package CatalystAdvent::Controller::Calendar;

use strict;
use warnings;

use base qw( Catalyst::Controller );

use DateTime;
use Calendar::Simple;
use File::stat;
use XML::Atom::SimpleFeed;
use POSIX qw(strftime);
use List::Util qw(max);
use CatalystAdvent::Pod;

=head1 NAME

CatalystAdvent::Controller::Calendar - Handles calendar year/day viewing

=head1 SYNOPSIS

See L<CatalystAdvent>

=head1 DESCRIPTION

This controller provides the various methods to generate the index for
a year, display the "tip" for a given day and generate RSS feeds.

=head1 METHODS

=head2 index

Detaches to the "year" display for the current year.

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    opendir DIR, $c->path_to('root') or die "Error opening root: $!";
    my @years = sort grep { /\d{4}/ } readdir DIR;
    closedir DIR;

    my $year = pop @years || $c->stash->{now}->year;
    $c->forward( 'year', [$year] );
}

=head2 year

Displays the calendar for any given year

=cut

sub year : Regex('^(\d{4})$') {
    my ( $self, $c, $year ) = @_;
    $year ||= $c->req->snippets->[0];
    $c->res->redirect( $c->uri_for('/') )
        unless ( -e $c->path_to( 'root', $year ) );
    $c->stash->{year}     = $year;
    $c->stash->{calendar} = calendar( 12, $year );
    $c->stash->{template} = 'year.tt';
}

=head2 day

Displays the tip of the day. Uses Pod::Xhtml to do the conversion from
pod to html.

=cut

sub day : Regex('^(\d{4})/(\d\d?)$') {
    my ( $self, $c, $year, $day ) = @_;
    $year ||= $c->req->snippets->[0];
    $day  ||= $c->req->snippets->[1];

    $c->detach( 'year', [$year] )
        unless ( -e ( my $file = $c->path_to( 'root', $year, "$day.pod" ) ) );
    $c->stash->{calendar} = calendar( 12, $year );
    $c->stash->{year}     = $year;
    $c->stash->{day}      = $day;
    $c->stash->{template} = 'day.tt';

    # cache the generated XHTML file so we're not parsing it on every request
    my $mtime      = ( stat $file )->mtime;
    my $cached_pod = $c->cache->get("$file $mtime");
    if ( !$cached_pod ) {
        my $parser = CatalystAdvent::Pod->new(
            StringMode   => 1,
            FragmentOnly => 1,
            MakeIndex    => 0,
            TopLinks     => 0
        );
        $parser->parse_from_file("$file");
        $cached_pod = $parser->asString;
        $c->cache->set( "$file $mtime", $cached_pod, '12h' );
    }
    $c->stash->{pod} = $cached_pod;
}

=head2 rss

Generates an rss feed of tips for the given year.

=cut

sub rss : Global {
    my ( $self, $c, $year ) = @_;
    $year ||= $c->stash->{now}->year;
    $year ||= $c->req->snippets->[0];
    $c->res->redirect( $c->uri_for('/') )
        unless ( -e $c->path_to( 'root', $year ) );

    $c->stash->{year} = $year;

    my $feed;
    my @entries = # get 5 most recent entires that actually exist on disk
      (grep {-e} map {$c->path_to('root', $year, "$_.pod")} 1 .. 24)[-5..-1]; 

    my @stats = map { stat "$_" } @entries;
    
    my $latest_mtime = max map { $_->mtime } @stats;
    my $last_mod = format_date_rfc822( $latest_mtime );

    $c->res->header( 'Last-Modified' => $last_mod );
    $c->res->header( 'ETag' => qq'"$last_mod"' );
    $c->res->content_type( 'application/atom+xml' );

    my $cond_date = $c->req->header( 'If-Modified-Since' );
    my $cond_etag = $c->req->header( 'If-None-Match' );
    if( $cond_date or $cond_etag ) {
        # if both headers are present, both must match
        my $do_send_304 = 1;
        if( $cond_date ) { $do_send_304 = $cond_date eq $last_mod }
        if( $cond_etag ) { $do_send_304 &&= $cond_etag eq qq'"$last_mod"' }
        if( $do_send_304 ) {
            $c->res->status( 304 );
            return;
        }
    }

    my $feed = XML::Atom::SimpleFeed->new(
        title   => "Catalyst Advent Calendar $year",
        link    => $c->req->base,
        link    => { rel => 'self', href => $c->uri_for("/rss/$year") },
        id      => $c->uri_for("/rss/$year"),
        updated => format_date_w3cdtf( $latest_mtime ),
    );

    for my $entry ( @entries ) {
        my $parser = CatalystAdvent::Pod->new(
            StringMode   => 1,
            FragmentOnly => 1,
            MakeIndex    => 0,
            TopLinks     => 0
        );

        $parser->parse_from_file( "$entry" );
	my $day = ($entry->basename =~ /^(\d+).pod$/);

	my $stat = shift @stats;
        $feed->add_entry(
            title    => { type => 'text', content => $parser->summary },
            content  => { type => 'xhtml', content => $parser->asString },
            author   => { name => $parser->author, email => $parser->email },
            link     => $c->uri_for( "/$year/$day" ),
            id       => $c->uri_for( "/$year/$day" ),
            published=> format_date_w3cdtf( $stat->ctime ),
            updated  => format_date_w3cdtf( $stat->mtime ),
        );
    }

    $c->res->body( $feed->as_string );
}

sub format_date_w3cdtf { strftime '%Y-%m-%dT%H:%M:%SZ', gmtime $_[0] }
sub format_date_rfc822 { strftime '%a, %d %b  %Y %H:%M:%S +0000', gmtime $_[0] }

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

