use strict;
use warnings;
use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => 'Test::Pod 1.14 required' if $@;
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

{
    my $old = Test::Pod::_parser->can('whine');
    my $whine = sub {
        return if $_[2] =~ /L<text\|scheme/;
        $old->(@_);
    };
    {
        no strict 'refs';
        no warnings qw/redefine once/;
        *Test::Pod::_parser::whine = $whine;
    }
}

all_pod_files_ok();

