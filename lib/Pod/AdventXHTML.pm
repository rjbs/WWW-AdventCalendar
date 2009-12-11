use strict;
package Pod::Simple::XHTML::WithXHTMLRegions;
use base 'Pod::Simple::XHTML';

sub new {
  my $self = shift;
  my $parser = $self->SUPER::new(@_);

  $parser->accept_targets('xhtml');

  return $parser;
}

# Absolutely, without a doubt, the wrong place to do this...
# ...but it works. -- rjbs, 2009-12-10
sub _ponder_Data {
  print {$_[0]->{'output_fh'}} $_[1][2], "\n\n";
}

sub handle_text {
  my $self = shift;

  # I don't understand why I can't just tack on the contents un-HTML-encoded
  # when we're in an XHTML region.  I can't, though.  All kinds of crazy crap
  # happens. -- rjbs, 2009-12-10
  return if $self->{__in_advent_xhtml};
  
  $self->SUPER::handle_text(@_);
}

sub start_for {
  my ($self, $flags) = @_;

  return $self->SUPER::start_for($flags)
    unless $flags->{target_matching} eq 'xhtml';

  Carp::confess("xhtml target sections may not nest")
    if $self->{__in_advent_xhtml};

  $self->{__in_advent_xhtml} = 1;
}

sub end_for {
  my ($self, $flags) = @_;

  return $self->SUPER::start_for($flags)
    unless $flags->{target_matching} eq 'xhtml';

  $self->{__in_advent_xhtml} = 0;
}

sub _end_head {
  my $h = delete $_[0]{in_head};
  $h++;
  my $id = $_[0]->idify($_[0]{scratch});
  my $text = $_[0]{scratch};
  $_[0]{'scratch'} = qq{<h$h id="$id">$text</h$h>};
  $_[0]->emit;
  push @{ $_[0]{'to_index'} }, [$h, $id, $text];
}

1;
