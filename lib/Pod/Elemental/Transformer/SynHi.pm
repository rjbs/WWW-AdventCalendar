package Pod::Elemental::Transformer::SynHi;
use Moose::Role;
with 'Pod::Elemental::Transformer';

requires 'synhi_params_for_para';
requires 'build_html';

sub build_html_para {
  my ($self, $arg) = @_;

  my $new = Pod::Elemental::Element::Pod5::Region->new({
    format_name => 'xhtml',
    is_pod      => 1,
    content     => '',
    children    => [
      Pod::Elemental::Element::Pod5::Verbatim->new({
        content => $self->build_html($arg),
      }),
    ],
  });

  return $new;
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
