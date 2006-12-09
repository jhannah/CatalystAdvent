#!/usr/bin/perl
# Pod.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

=head1 NAME

CatalystAdvent::Pod - parse POD into XHTML + metadata

=cut

package CatalystAdvent::Pod;
use base 'Pod::Xhtml';
use strict;

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

sub title   { $_[0]->{_title} }
sub summary { $_[0]->{_first_paragraph} }
sub author  { $_[0]->{_author} }
sub email   { $_[0]->{_email} }
1;

