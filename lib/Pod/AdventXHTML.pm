use strict;
package Pod::AdventXHTML;
use base 'Pod::Simple::XHTML';

sub new {
  my $self = shift;
  my $parser = $self->SUPER::new(@_);

  $parser->accept_targets('xhtml');

  return $parser;
}

sub _ponder_Data {
  print {$_[0]->{'output_fh'}} $_[1][2], "\n\n";
}

sub handle_text {
  $_[0]{'scratch'} .= ($_[0]->{target}[-1]||'') eq 'xhtml'
                    ? '' # ?!?!?!? SHOULD NOT HAPPEN
                    : HTML::Entities::encode_entities( $_[1] )
}

sub start_for {
  my ($self, $flags) = @_;

  Carp::confess("non-xhtml target section begun")
    unless $flags->{target_matching} eq 'xhtml';

  push @{ $self->{target} ||= [] }, $flags->{target_matching};
}

sub end_for {
  my ($self, $flags) = @_;
  pop @{ $self->{target} ||= [] };
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
