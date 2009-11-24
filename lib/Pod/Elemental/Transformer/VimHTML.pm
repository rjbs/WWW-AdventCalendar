package Pod::Elemental::Transformer::VimHTML;
use Moose;
with 'Pod::Elemental::Transformer';

use Text::VimColor;

sub _xhtml_node_for_vim {
  my ($self, $syntax, $string) = @_;

  1 while chomp $string;
  $string =~ s/^  //gms;

  my $vim = Text::VimColor->new(
    string   => $string,
    filetype => $syntax,
  );

  my $html = "\n" . $vim->html;

  # This should not be needed, because this is a data paragraph, not a
  # ordinary paragraph, but Pod::Xhtml doesn't seem to know the difference
  # and tries to expand format codes. -- rjbs, 2009-11-20
  $html =~ s/\A\n+//;
  $html =~ s/^/  /gsm;
  1 while chomp $html;

  my @lines = split /\n/, $html;
  my $count = @lines;
  my $line  = 0;

  my $space_count = 2 + length scalar @lines;
  my $spc = ' ' x $space_count;

  my $fmt
    = "<table class='code-listing'>"
    . "<tr class='line'><td><span class='line_number'>$spc</span>&nbsp;</td></tr>\n"
    . "%s"
    . "<tr class='line'><td><span class='line_number'>$spc</span>&nbsp;</td></tr>\n"
    . "</table>";

  my $lines = '';
  my $width = $space_count - 2;
  for (0 .. $#lines) {
    my $line = $lines[ $_ ];
    $line =~ s/^  //;
    $lines .= sprintf(
      "<tr class='line'><td><span class='line_number'>%${width}s: </span>"
      . "%s</td></tr>\n",
      $_ + 1,
      $line,
    );
  }

  $html = sprintf $fmt, $lines;

  my $para = Pod::Elemental::Element::Pod5::Data->new({
    content => $html,
  });

  # This should not be needed, because if there's a \n\n in the content, we
  # should get a =begin and not a =for. -- rjbs, 2009-11-20
  my $hack = Pod::Elemental::Element::Pod5::Data->new({
    content => "<!-- hack -->",
  });

  my $new = Pod::Elemental::Element::Pod5::Region->new({
    format_name => 'xhtml',
    is_pod      => 0,
    content     => '',
    children    => [ $para, $hack ],
  });

  return $new;
}

sub transform_node {
  my ($self, $parent_node) = @_;

  for my $i (0 .. (@{ $parent_node->children } - 1)) {
    my $node = $parent_node->children->[ $i ];

    my $new;

    if (
      $node->isa('Pod::Elemental::Element::Pod5::Region')
      and    $node->format_name eq 'vim'
    ) {
      die "=begin :vim makes no sense\n" if $node->is_pod;

      my $string = $node->children->[0]->as_pod_string;
      $new  = $self->_xhtml_node_for_vim($node->content, $string);
    } else {
      next;
    }

    die "couldn't produce new xhtml" unless $new;
    $parent_node->children->[ $i ] = $new;
  }

  return $parent_node;
}

1;
