package Pod::Elemental::Transformer::SynHi;
use Moose::Role;
with 'Pod::Elemental::Transformer';

requires 'synhi_params_for_para';
requires 'build_html';

sub build_html_para {
  my ($self, $arg) = @_;

  my $new = Pod::Elemental::Element::Pod5::Region->new({
    format_name => 'xhtml',
    content     => '',
    children    => [
      Pod::Elemental::Element::Pod5::Data->new({
        content => $self->build_html($arg),
      }),
    ],
  });

  return $new;
}

sub standard_code_block {
  my ($self, $html) = @_;

  $html =~ s/\A\n+//;
  1 while chomp $html;

  my @lines = split /\n/, $html;

  my $numbers = join "<br />", map {; "$_:&nbsp;" } (1 .. @lines);
  my $code    = join "<br />", map {; s/^(\s+)/'&nbsp;' x length $1/me; $_ }
                @lines;

  $html = "<table class='code-listing'><tr>"
        . "<td class='line-numbers'>\n$numbers\n</td>"
        . "<td class='code'>\n$code\n</td>"
        . "</table>";

  # This should not be needed, because this is a data paragraph, not a
  # ordinary paragraph, but Pod::Xhtml doesn't seem to know the difference
  # and tries to expand format codes. -- rjbs, 2009-11-20
  # ...and now we emit as a verbatim paragraph explicitly to remain (A) still
  # working and (B) valid. -- rjbs, 2009-11-26
  $html =~ s/^/  /gsm;
  $html =~ s/(<br \/>)/$1  /gsm;

  return $html;
}

sub transform_node {
  my ($self, $node) = @_;

  for my $i (0 .. (@{ $node->children } - 1)) {
    my $para = $node->children->[ $i ];

    next unless my $arg = $self->synhi_params_for_para($para);
    my $new = $self->build_html_para($arg);

    die "couldn't produce new xhtml" unless $new;
    $node->children->[ $i ] = $new;
  }

  return $node;
}

1;
