package CatalystAdvent::Controller::Calendar;

use strict;
use warnings;

use base qw( Catalyst::Controller );
use DateTime;
use Calendar::Simple;
use XML::Feed;

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

sub rss : Global {
    my( $self, $c, $year ) = @_;
    my $feed=XML::Feed->new('RSS');
    $year ||= $c->stash->{now}->year;
    $feed->title($c->config->{name}. ' RSS Feed');
    $feed->link($c->req->base);
    $feed->description('Catalyst advent calendar');
    $year ||= $c->req->snippets->[ 0 ];
    $c->res->redirect( $c->uri_for( '/' ) )
        unless ( -e $c->path_to( 'root', $year ) );
    $c->stash->{ year }     = $year;
    my ($day,$entries)      = (24, 0);
    my $feed_mtime=0;
    while ($day>0 && $entries<5) {
        if ( -e ( my $file = $c->path_to( 'root', $year, "$day.pod" ) ) )  {
            my ($mtime,$ctime) = (stat($file))[9,10];
            $feed_mtime=$mtime if $mtime>$feed_mtime;
            my $entry = XML::Feed::Entry->new('RSS');
            $entry->title("Calendar entry for day $day.");
            $entry->link($c->uri_for("/$year/$day"));
            $entry->issued(DateTime->from_epoch(epoch=>$ctime));
            $entry->modified(DateTime->from_epoch(epoch=>$mtime));

            $feed->add_entry($entry);
            $entries++;   
        }
        $day--;
    }
    $feed->modified(DateTime->from_epoch(epoch=>$feed_mtime));
    $c->res->body($feed->as_xml);
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
