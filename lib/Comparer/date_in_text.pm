package Comparer::date_in_text;

use 5.010001;
use strict;
use warnings;

use DateTime;

# AUTHORITY
# DATE
# DIST
# VERSION

our $DATE_EXTRACT_MODULE = $ENV{PERL_DATE_EXTRACT_MODULE} // "Date::Extract";

sub meta {
    return {
        v => 1,
        args => {
            reverse => {schema=>'bool*'},
            ci => {schema=>'bool*'},
        },
    };
}

my $re_is_num = qr/\A
                   [+-]?
                   (?:\d+|\d*(?:\.\d*)?)
                   (?:[Ee][+-]?\d+)?
                   \z/x;

sub gen_comparer {
    my %args = @_;

    my $reverse = $args{reverse};
    my $ci = $args{ci};

    my ($parser, $code_parse);
    unless (defined $parser) {
        my $module = $DATE_EXTRACT_MODULE;
        $module = "Date::Extract::$module" unless $module =~ /::/;
        if ($module eq 'Date::Extract') {
            require Date::Extract;
            $parser = Date::Extract->new();
            $code_parse = sub { $parser->extract($_[0]) };
        } elsif ($module eq 'Date::Extract::ID') {
            require Date::Extract::ID;
            $parser = Date::Extract::ID->new();
            $code_parse = sub { $parser->extract($_[0]) };
        } elsif ($module eq 'DateTime::Format::Alami::EN') {
            require DateTime::Format::Alami::EN;
            $parser = DateTime::Format::Alami::EN->new();
            $code_parse = sub { my $h; eval { $h = $parser->parse_datetime($_[0]) }; $h }; ## no critic: BuiltinFunctions::ProhibitStringyEval
        } elsif ($module eq 'DateTime::Format::Alami::ID') {
            require DateTime::Format::Alami::ID;
            $parser = DateTime::Format::Alami::ID->new();
            $code_parse = sub { my $h; eval { $h = $parser->parse_datetime($_[0]) }; $h }; ## no critic: BuiltinFunctions::ProhibitStringyEval
        } else {
            die "Invalid date extract module '$module'";
        }
        eval "use $module"; die if $@; ## no critic: BuiltinFunctions::ProhibitStringyEval
    }

    sub {
        no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict

        my $cmp;

        # XXX cache

        my $dt_a = $code_parse->($_[0]);
        warn "Found date $dt_a in $_[0]\n" if $ENV{DEBUG} && $dt_a;
        my $dt_b = $code_parse->($_[1]);
        warn "Found date $dt_b in $_[1]\n" if $ENV{DEBUG} && $dt_b;

        {
            if ($dt_a && $dt_b) {
                $cmp = DateTime->compare($dt_a, $dt_b);
                last if $cmp;
            } elsif ($dt_a && !$dt_b) {
                $cmp = -1;
                last;
            } elsif (!$dt_a && $dt_b) {
                $cmp = 1;
                last;
            }

            if ($ci) {
                $cmp = lc($a) cmp lc($b);
            } else {
                $cmp = $a cmp $b;
            }
        }

        $reverse ? -1*$cmp : $cmp;
    };
}

1;
# ABSTRACT: Compare date found in text (or text asciibetically, if no date is found)

=for Pod::Coverage ^(gen_sorter|meta)$

=head1 DESCRIPTION

The generated comparer routine will compare text by date found in it (extracted
using L<Date::Extract>, but other module can be selected, see
L</PERL_DATE_EXTRACT_MODULE>) or (f no date is found in text) ascibetically.
Items that have a date will sort before items that do not.


=head1 ENVIRONMENT

=head2 DEBUG => bool

If set to true, will print stuffs to stderr.

=head2 PERL_DATE_EXTRACT_MODULE => str

Can be set to L<Date::Extract>, L<Date::Extract::ID>, or
L<DateTime::Format::Alami::EN>, L<DateTime::Format::Alami::ID>.


=head1 SEE ALSO

L<SortKey> version: L<SortKey::date_in_text>.

Old incarnation: L<Sort::Sub::by_date_in_text>.
