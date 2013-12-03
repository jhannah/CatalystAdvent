package CatalystAdvent::Controller::Calendar;

use base 'Catalyst::Controller';
use Moose;
use namespace::autoclean;

use DateTime;
use Calendar::Simple;
use File::stat;
use XML::Atom::SimpleFeed;
use POSIX qw(strftime);
use List::Util qw(max);
use CatalystAdvent::Pod;
use HTTP::Date;

=head1 NAME

CatalystAdvent::Controller::Calendar - Handles calendar year/day viewing

=head1 SYNOPSIS

See L<CatalystAdvent>

=head1 DESCRIPTION

This controller provides the various methods to generate the index for
a year, display the "tip" for a given day and generate RSS feeds.

=head1 METHODS

=head2 base

Base action for this controller that all other actions are attached to.

=head2 index

Detaches to the "year" display for the current year.

=cut

has retired => (is => 'ro');

sub base : Chained('/base') PathPart('') CaptureArgs(0) {}

sub index : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;

    my @years = $self->_years($c);

    if (not $self->retired) {
        my $now = $c->stash->{now};

        if (not ($now->month == 12 || ($now->month == 1 || $now->month == 2))) {
            my $start_date = $now->clone->set(month => 12, day => 1);

            my $days_until = $start_date->delta_days($now)->delta_days;

            $c->stash(days_until => $days_until);

            pop @years if @years && $years[-1] == $now->year;
        }
    }
    else {
        $c->stash(retired => $self->retired);
    }

    $c->stash(previous_years => \@years) if @years;

    $c->go($self->action_for('year'), [$years[-1]], []) if @years;
}

sub _years {
    my ($self, $c) = @_;

    opendir my $dir, $c->path_to('root') or die "Error opening root: $!";

    return sort { $a <=> $b } grep { /^\d{4}\z/ } readdir $dir;
}

=head2 get_year

Gets relevant calendar data for any given year

=cut

sub get_year : Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $year ) = @_;

    $c->detach( '/calendar/index' ) unless $year =~ /^\d{4}$/;

    $c->res->redirect( $c->uri_for('/') ) && $c->detach
        unless ( -d $c->path_to( 'root', $year ) );

    $c->stash->{year}     = $year;
    $c->stash->{calendar} = calendar( 12, $year );

    opendir my $DIR, $c->path_to('root', $year) or die "Error opening root: $!";
    my @days = sort { $a <=> $b }
               map  { m/(\d+)\.pod/ }
               readdir $DIR;
    closedir $DIR;

    my @links;
    DAY: foreach my $day (@days) {
        # Don't show link to articles before the appropriate day, even if they're ready
        my $date = DateTime->new( day => $day, month => 12, year => $year );
        next DAY if $c->stash->{now} < $date;

        my $file = $c->path_to( 'root', $year )->file( "$day.pod" );

        my $mtime        = ( stat $file )->mtime;
        my $cached_title = $c->cache->get("title $file $mtime");
        if ( !$cached_title ) {
            my $parser = CatalystAdvent::Pod->new();

            open my $fh, '<:utf8', $file or die "Failed to open $file: $!";
            $parser->parse_from_filehandle($fh);
            close $fh;
            
            $cached_title = $parser->title || '(no title)';
            $c->cache->set( "title $file $mtime", $cached_title, '12h' );
        }

        push @links, { day => $day, title => $cached_title };
    }

    $c->stash->{links} = \@links;

    # for years links
    $c->stash(years => [ $self->_years($c) ]);
}

=head2 year

Displays the per-year page.

=cut

sub year : Chained('get_year') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'year.tt';
}

=head2 day

Displays the tip of the day. Uses Pod::Xhtml to do the conversion from
pod to html.

=cut

sub day : Chained('get_year') PathPart('') Args(1) {
    my ( $self, $c, $day ) = @_;
    $c->detach( '/calendar/index' ) unless $day =~ /^\d{1,2}$/;

    my $year = $c->stash->{year};

    # Don't show articles before the appropriate day, even if they're ready
    if (!$c->debug && $year == $c->stash->{now}->year) {
        $c->detach( 'year', [$year] ) unless ($day <= $c->stash->{now}->day);
    }

    $c->detach( 'year', [$year] )
        unless ( -e ( my $file = $c->path_to( 'root', $year, "$day.pod" ) ) );

    $c->stash->{day}      = $day;
    $c->stash->{template} = 'day.tt';

    # cache the generated XHTML file so we're not parsing it on every request
    my $mtime      = ( stat $file )->mtime;
    my $cached_pod = $c->cache->get("$file $mtime");
    if ( !$cached_pod ) {
        my $parser = CatalystAdvent::Pod->new();

        open my $fh, '<:utf8', $file or die "Failed to open $file: $!";
        $parser->parse_from_filehandle($fh);
        close $fh;
        
        $cached_pod = $parser->asString;
        $c->cache->set( "$file $mtime", $cached_pod, '12h' );
    }
    $c->stash->{pod} = $cached_pod;
}

=head2 rss

Forwards to the "feed" URI to maintain compatibility with bookmarked aggregators

=cut

sub rss : Chained('base') Args() {
    my ( $self, $c, $year ) = @_;
    $c->go('feed', [$year] );
}

=head2 feed 

Generates an XML feed (Atom) of tips for the given year.

=cut

sub feed : Chained('base') Args() {
    my ( $self, $c, $year ) = @_;
    $year ||= $c->stash->{now}->year;
    $c->detach( '/calendar/index' ) unless $year =~ /^\d{4}$/;
    $c->res->redirect( $c->uri_for('/') )
        unless ( -e $c->path_to( 'root', $year ) );

    $c->stash->{year} = $year;

    my $now = $c->stash->{now};

    # get only not published entries
    my @entry = reverse 1 .. ( $year == $now->year ? $now->day : 24 );
    my %path = map { $_ => $c->path_to( 'root', $year, "$_.pod" ) } @entry;
    @entry = grep -e $path{ $_ }, @entry;
    
    # only keep the newest five entries
    splice @entry, (@entry > 5) ? 5 : scalar @entry; 
    
    my %stat = map { $_ => stat ''. $path{ $_ } } @entry;
    my $latest_mtime = max map { $_->mtime } values %stat;
    my $last_mod = time2str( $latest_mtime );

    $c->res->header( 'Last-Modified' => $last_mod );
    $c->res->header( 'ETag' => qq'"$last_mod"' );
    $c->res->content_type( 'application/atom+xml' );
    
    my $cond_date = $c->req->header( 'If-Modified-Since' );
    my $cond_etag = $c->req->header( 'If-None-Match' );
    if( $cond_date || $cond_etag ) {

        # if both headers are present, both must match
        my $do_send_304 = 1;
	$do_send_304 = (str2time($cond_date) >= $latest_mtime)
	  if( $cond_date );
	$do_send_304 &&= ($cond_etag eq qq{"$last_mod"})
	  if( $cond_etag );
	
        if( $do_send_304 ) {
            $c->res->status( 304 );
            return;
        }
    }
    
    my $feed = XML::Atom::SimpleFeed->new(
        title   => "Catalyst Advent Calendar $year",
        link    => $c->req->base,
        link    => { rel => 'self', href => $c->uri_for("/feed/$year") },
        id      => $c->uri_for("/feed/$year"),
        updated => format_date_w3cdtf( $latest_mtime || 0 ),
    );

    for my $day ( @entry ) {
        my $parser = CatalystAdvent::Pod->new();

        my $file = q{}. $path{$day};
        open my $fh, '<:utf8', $file or die "Failed to open $file: $!";
        $parser->parse_from_filehandle($fh);
        close $fh;
        
        my $e = $feed->add_entry(
            title    => { type => 'text', content => ($parser->title || "") },
            content  => { type => 'html', content => $parser->asString },
            author   => { name => $parser->author||'Catalyst', 
			  email => ($parser->email||
				    'catalyst@lists.scsys.co.uk') },
            link     => $c->uri_for( "/$year/$day" ),
            id       => $c->uri_for( "/$year/$day" ),
            published=> format_date_w3cdtf( $stat{ $day }->ctime ),
            updated  => format_date_w3cdtf( $stat{ $day }->mtime ),
        );
    }

    $c->res->body( $feed->as_string );
}

=head2 format_date_w3cdtf

Formats a date as an ISO8601 date string.

=cut

sub format_date_w3cdtf { strftime '%Y-%m-%dT%H:%M:%SZ', gmtime $_[0] }

=head1 AUTHORS

Brian Cassidy, <bricas@cpan.org>

Sebastian Riedel, <sri@cpan.org>

Andy Grundman, <andy@hybridized.org>

Marcus Ramberg, <mramberg@cpan.org>

Jonathan Rockway, <jrockway@cpan.org>

Aristotle Pagaltzis, <pagaltzis@gmx.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

