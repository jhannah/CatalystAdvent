package CatalystAdvent::Pod;
use base 'Pod::Xhtml';
use strict;

sub new {
    my $class = shift;
    $Pod::Xhtml::SEQ{L} = \&seqL;

    $class->SUPER::new(
        StringMode   => 1,
        FragmentOnly => 1,
        MakeIndex    => 0,
        TopLinks     => 0,
        @_
    );
}

sub textblock {
    my $self   = shift;
    my ($text) = @_;
    $self->{_first_paragraph} ||= $text;

    if($self->{_in_author_block}){
	$text =~ /((?:[\w.]+\s+)+)/ and $self->{_author} = $1;
	$text =~ /<([^<>@\s]+@[^<>\s]+)>/ and $self->{_email} = $1;
	$self->{_in_author_block} = 0; # not anymore
    }

    return $self->SUPER::textblock(@_);
}

sub command {
    my $self = shift;
    my ($command, $paragraph, $pod_para) = @_;

    $self->{_title} = $paragraph
        if $command eq 'head1' and not defined $self->{_title};

    $self->{_in_author_block} = 1
        if $command =~ /^head/ and $paragraph =~ /AUTHOR/;

    return $self->SUPER::command(@_);
}

sub seqL {
    my ($self, $link) = @_;
    $self->{LinkParser}->parse($link);
    my $page = $self->{LinkParser}->page;
    my $kind = $self->{LinkParser}->type;
    my $targ = $self->{LinkParser}->node;
    my $text = $self->{LinkParser}->text;

    if ($kind eq 'hyperlink'){
	return $self->SUPER::seqL($link);
    }

    $page ||= $text;
    $text = Pod::Xhtml::_htmlEscape($text);
    $page = Pod::Xhtml::_htmlEscape($page);
    $targ = Pod::Xhtml::_htmlEscape($targ);

    if ($targ) {
        return qq{<a href="http://metacpan.org/module/$page#$targ">$text</a>};
    }

    return qq{<a href="http://metacpan.org/module/$page">$text</a>};
}

sub title   { $_[0]->{_title} }
sub summary { $_[0]->{_first_paragraph} }
sub author  { $_[0]->{_author} }
sub email   { $_[0]->{_email} }
1;

=head1 NAME

CatalystAdvent::Pod - parse POD into XHTML + metadata

=head1 METHODS

=over

=item author

=item command

=item email

=item new

=item seqL

=item summary

=item textblock

=item title

=back

=head1 AUTHOR

    Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Jonathan Rockway

=cut

