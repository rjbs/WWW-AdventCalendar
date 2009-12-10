package Pod::AdventXHTML;
use base 'Pod::Simple::XHTML';

sub handle_text {
  $_[0]{'scratch'} .= ($_[0]->{target}[-1]||'') eq 'xhtml'
                    ? $_[1]
                    : HTML::Entities::encode_entities( $_[1] )
}

sub start_for {
  my ($self, $flags) = @_;
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
