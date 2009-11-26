package Pod::Elemental::Transformer::VimHTML;
use Moose;
with 'Pod::Elemental::Transformer::SynHi';

use Text::VimColor;

sub build_html {
  my ($self, $arg) = @_;
  my $string = $arg->{content};
  my $syntax = $arg->{syntax};

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
  # ...and now we emit as a verbatim paragraph explicitly to remain (A) still
  # working and (B) valid. -- rjbs, 2009-11-26
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

  return $html;
}

sub synhi_params_for_para {
  my ($self, $para) = @_;

  if (
    $para->isa('Pod::Elemental::Element::Pod5::Region')
    and    $para->format_name eq 'vim'
  ) {
    die "=begin :vim makes no sense\n" if $para->is_pod;

    return {
      syntax  => $para->content,
      content => $para->children->[0]->as_pod_string,
    };
  }

  return;
}

1;
