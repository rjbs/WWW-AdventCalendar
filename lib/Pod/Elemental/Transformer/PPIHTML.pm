package Pod::Elemental::Transformer::PPIHTML;
use Moose;
with 'Pod::Elemental::Transformer';

use PPI;
use PPI::HTML;

sub transform_node {
  my ($self, $parent_node) = @_;

  for my $i (0 .. (@{ $parent_node->children } - 1)) {
    my $node = $parent_node->children->[ $i ];

    next unless $node->isa('Pod::Elemental::Element::Pod5::Region')
         and    $node->format_name eq 'perl';

    die "=begin :perl makes no sense\n" if $node->is_pod;

    my $perl    = $node->children->[0]->as_pod_string;
    my $ppi_doc = PPI::Document->new(\$perl);
    my $ppihtml = PPI::HTML->new( line_numbers => 1 );
    my $html    = $ppihtml->html( $ppi_doc );

    my @lines = split m{<br>\n?}, $html;

    $html = "<table class='ppi-html'>"
          . (join q{}, map {; "<tr class='line'><td>$_</td></tr>\n" } @lines)
          . "</table>";

    my $para = Pod::Elemental::Element::Pod5::Data->new({
      content => "<div class='ppi-html'>$html</div>\n",
    });

    my $new = Pod::Elemental::Element::Pod5::Region->new({
      format_name => 'xhtml',
      is_pod      => 0,
      content     => '',
      children    => [ $para ],
    });

    $parent_node->children->[ $i ] = $new;
  }

  return $parent_node;
}
