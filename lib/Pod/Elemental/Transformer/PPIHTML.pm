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

    my $space_count = 2 + length scalar @lines;
    my $spc = ' ' x $space_count;

    $html = "<table class='ppi-html'>"
          . "<tr class='line'><td><span class='line_number'>$spc</span>&nbsp;</td></tr>\n"
          . (join q{}, map {; "<tr class='line'><td>$_</td></tr>\n" } @lines)
          . "<tr class='line'><td><span class='line_number'>$spc</span>&nbsp;</td></tr>\n"
          . "</table>";

    # This should not be needed, because this is a data paragraph, not a
    # ordinary paragraph, but Pod::Xhtml doesn't seem to know the difference
    # and tries to expand format codes. -- rjbs, 2009-11-20
    $html =~ s/^/  /gsm;

    my $para = Pod::Elemental::Element::Pod5::Data->new({
      content => $html,
    });

    # This should not be needed, because if there's a \n\n in the content, we
    # should get a =begin and not a =for. -- rjbs, 2009-11-20
    my $hack = Pod::Elemental::Element::Pod5::Data->new({
      content => "<!-- hack -->\n",
    });

    my $new = Pod::Elemental::Element::Pod5::Region->new({
      format_name => 'xhtml',
      is_pod      => 0,
      content     => '',
      children    => [ $para, $hack ],
    });

    $parent_node->children->[ $i ] = $new;
  }

  return $parent_node;
}
