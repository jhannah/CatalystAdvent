package CatalystAdvent;

use strict;
use warnings;

use Catalyst qw( -Debug Static::Simple DefaultEnd );
use Pod::Xhtml;

our $VERSION = '0.02';

__PACKAGE__->config( name => 'CatalystAdvent' );
__PACKAGE__->setup;

=head1 NAME

CatalystAdvent - Catalyst based application

=head1 SYNOPSIS

    script/catalystadvent_server.pl

=head1 DESCRIPTION

Catalyst based application.

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private {
    my( $self, $c ) = @_;
    $c->detach( '/calendar/index' );
}

sub begin : Private {
    my( $self, $c ) = @_;
    $c->stash->{now}=DateTime->now();

}


=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
