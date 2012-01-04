package CatalystAdvent;

use strict;
use warnings;

use Catalyst qw( Static::Simple
                 ConfigLoader
                 Cache
                 Unicode::Encoding
              );

our $VERSION = '0.05';

__PACKAGE__->config(
  name => 'CatalystAdvent',
  'Plugin::Cache' => { backend => {
    class => 'Cache::FileCache',
    namespace => 'CatalystAdvent',
  } },
);
__PACKAGE__->setup;

=head1 NAME

CatalystAdvent - Catalyst-based Advent Calendar

=head1 SYNOPSIS

    script/catalystadvent_server.pl

=head1 DESCRIPTION

After some sudden inspiration, Catalysters decided to put
together a Catalyst advent calendar to complement the excellent perl one.

=head1 AUTHORS

Brian Cassidy, <bricas@cpan.org>

Sebastian Riedel, <sri@cpan.org>

Andy Grundman, <andy@hybridized.org>

Marcus Ramberg, <mramberg@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
