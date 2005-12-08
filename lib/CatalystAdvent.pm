package CatalystAdvent;

use strict;
use warnings;

use Catalyst qw( -Debug Static::Simple DefaultEnd );

our $VERSION = '0.02';

__PACKAGE__->config( name => 'CatalystAdvent' );
__PACKAGE__->setup;

=head1 NAME

CatalystAdvent - Catalyst-based Advent Calendar

=head1 SYNOPSIS

    script/catalystadvent_server.pl

=head1 DESCRIPTION

After some sudden inspiration, Catalysters decided to put
together a Catalyst advent calendar to complement the excellent perl one.

=head1 METHODS

=head2 default

Detaches you to the calendar index if no other path is a match.

=cut

sub default : Private {
    my( $self, $c ) = @_;
    $c->detach( '/calendar/index' );
}

=head2 begin

Simply adds the current date to the stash for some operations needed
across various methods.

=cut

sub begin : Private {
    my( $self, $c )  = @_;
    $c->stash->{now} = DateTime->now();
}

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
