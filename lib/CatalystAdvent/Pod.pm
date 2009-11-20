#!/usr/bin/perl
# Pod.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

=head1 NAME

CatalystAdvent::Pod - parse POD into XHTML + metadata

=cut

package CatalystAdvent::Pod;
use base 'Pod::Xhtml';
use strict;

sub new {
    my $class = shift;
    $Pod::Xhtml::SEQ{L} = \&seqL;

    $class->SUPER::new(@_);
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
    
    $targ ||= $text;
    $text = Pod::Xhtml::_htmlEscape($text);
    $targ = Pod::Xhtml::_htmlEscape($targ);
    
    return qq{<a href="http://search.cpan.org/perldoc?$targ">$text</a>};
}

sub title   { $_[0]->{_title} }
sub summary { $_[0]->{_first_paragraph} }
sub author  { $_[0]->{_author} }
sub email   { $_[0]->{_email} }
1;

