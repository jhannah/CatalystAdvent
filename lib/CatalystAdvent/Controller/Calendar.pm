package CatalystAdvent::Controller::Calendar;

use strict;
use warnings;

use base qw( Catalyst::Controller );
use DateTime;
use Calendar::Simple;

=head1 NAME

CatalystAdvent::Controller::Calendar - Catalyst Controller

=head1 SYNOPSIS

See L<CatalystAdvent>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub index : Private {
    my( $self, $c ) = @_;
    $c->detach( 'year', [ $c->stash->{now}->year  ] );
}

sub year : Regex('^(\d{4})$') {
    my( $self, $c, $year ) = @_;
    $year ||= $c->req->snippets->[ 0 ];
    $c->res->redirect( $c->uri_for( '/' ) )
        unless ( -e $c->path_to( 'root', $year ) );
    $c->stash->{ year }     = $year;
    $c->stash->{ calendar } = calendar( 12, $year );
    $c->stash->{ template } = 'year.tt';
}

sub day : Regex('^(\d{4})/(\d\d?)$') {
    my( $self, $c, $year, $day ) = @_;
    $year ||= $c->req->snippets->[ 0 ];
    $day  ||= $c->req->snippets->[ 1 ];

    $c->detach('year',[$year]) 
        unless( -e ( my $file = $c->path_to( 'root', $year, "$day.pod" ) ) ); 
    $c->stash->{ calendar } = calendar( 12, $year );
    $c->stash->{ year }     = $year;
    $c->stash->{ day }      = $day;
    $c->stash->{ template } = 'day.tt';
        my $parser = Pod::Xhtml->new( StringMode => 1, FragmentOnly => 1, MakeIndex => 0, TopLinks => 0 );
        $parser->parse_from_file( "$file" );
        $c->stash->{ pod }      = $parser->asString;
}

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
