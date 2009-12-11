use strict;
package Pod::Simple::XHTML::WithXHTMLRegions;
use base 'Pod::Simple::XHTML';

__PACKAGE__->_accessorize('header_level');

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  $self->accept_targets('xhtml');

  $self->{__region_targets} = [];

  return $self;
}

# Absolutely, without a doubt, the wrong place to do this...
# ...but it works. -- rjbs, 2009-12-10
sub _ponder_Data {
  return unless $_[0]->__exactly_in_xhtml_region;
  print {$_[0]->{'output_fh'}} $_[1][2], "\n\n";
}

sub __exactly_in_xhtml_region {
  my ($self) = @_;
  return @{ $self->{__region_targets} }
     and $self->{__region_targets}[-1] eq 'xhtml';
}

sub handle_text {
  my $self = shift;

  # I don't understand why I can't just tack on the contents un-HTML-encoded
  # when we're in an XHTML region.  I can't, though.  All kinds of crazy crap
  # happens. -- rjbs, 2009-12-10
  return if $self->__exactly_in_xhtml_region;
  
  $self->SUPER::handle_text(@_);
}

sub start_for {
  my ($self, $flags) = @_;

  push @{ $self->{__region_targets} }, $flags->{target_matching};
  return $self->SUPER::start_for($flags)
}

sub end_for {
  my ($self, $flags) = @_;

  pop @{ $self->{__region_targets} };
  return $self->SUPER::start_for($flags)
}

sub _end_head {
  my ($self) = @_;
  my $add = $self->header_level;
  $add = 1 unless defined $add;
  $_[0]{in_head} += $add - 1;
  return $_[0]->SUPER::_end_head;
}

1;
