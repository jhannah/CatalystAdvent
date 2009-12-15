package CatalystAdvent::Controller::Root;
use strict;
use warnings;

use base 'Catalyst::Controller';
__PACKAGE__->config(namespace => '');

=head2 default

Detaches you to the calendar index if no other path is a match.

=cut

sub default : Private {
    my( $self, $c ) = @_;
    $c->detach( '/calendar/index' );
}

=head2 base

Simply adds the current date to the stash for some operations needed
across various methods.

=cut

sub base : Chained('/') PathPart('') CaptureArgs(0) {
    my( $self, $c )  = @_;
    $c->stash->{now} = DateTime->now();
}

=head2 end

Renders a view if needed.

=cut

sub end : ActionClass('RenderView') {}

1;

