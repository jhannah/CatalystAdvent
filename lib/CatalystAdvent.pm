package CatalystAdvent;

use strict;
use warnings;

use Catalyst qw( -Debug Static::Simple );
use Pod::Xhtml;

our $VERSION = '0.01';

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

sub auto : Private {
    my( $self, $c ) = @_;
    $c->stash->{ now } = DateTime->now;
}

sub default : Private {
    my( $self, $c ) = @_;
    $c->detach( '/calendar/index' );
}

=head2 end

=cut

sub end : Private {
    my( $self, $c )   = @_;
    my( $year, $day ) = ( $c->stash->{ year } || 0, $c->stash->{ day } || 0 );

    $day += 0;

    if( -e ( my $file = $c->path_to( 'root', $year, "$day.pod" ) ) ) {
        my $parser = Pod::Xhtml->new( StringMode => 1, FragmentOnly => 1, MakeIndex => 0, TopLinks => 0 );
        $parser->parse_from_file( "$file" );
        $c->stash->{ pod }      = $parser->asString;
        $c->stash->{ template } = 'day.tt';
    }
    elsif( -e $c->path_to( 'root', $year ) ) {
        $c->stash->{ template } = 'year.tt';
    }
    elsif( !$c->res->body ) {
        $c->res->body( 'Redirecting...' );
        $c->res->redirect( $c->uri_for( '/' ) );
    }

    $c->res->content_type( 'text/html; charset=utf-8' ) unless $c->res->content_type;
    $c->forward( $c->view( 'TT' ) ) unless $c->res->body;
}

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
