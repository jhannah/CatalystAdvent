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
    return $self->SUPER::textblock(@_);
}

sub first_paragraph { return $_[0]->{_first_paragraph} }

1;

