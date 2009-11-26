package Pod::Elemental::Transformer::PPIHTML;
use Moose;
with 'Pod::Elemental::Transformer::SynHi';

use utf8;
use PPI;
use PPI::HTML;

sub build_html {
  my ($self, $arg) = @_;
  my $perl = $arg->{content};
  my $opt  = $arg->{options};

  1 while chomp $perl;
  $perl =~ s/^  //gms;

  my $ppi_doc = PPI::Document->new(\$perl);
  my $ppihtml = PPI::HTML->new( line_numbers => 1 );
  my $html    = $ppihtml->html( $ppi_doc );

  my @lines = split m{<br>\n?}, $html;

  my $space_count = 2 + length scalar @lines;
  my $spc = ' ' x $space_count;

  $opt =~ /stupid-hyphen/ and s/-/−/g for @lines;

  $html = "<table class='code-listing'>"
        . "<tr class='line'><td><span class='line_number'>$spc</span>&nbsp;</td></tr>\n"
        . (join q{}, map {; "<tr class='line'><td>$_</td></tr>\n" } @lines)
        . "<tr class='line'><td><span class='line_number'>$spc</span>&nbsp;</td></tr>\n"
        . "</table>";

  # This should not be needed, because this is a data paragraph, not a
  # ordinary paragraph, but Pod::Xhtml doesn't seem to know the difference
  # and tries to expand format codes. -- rjbs, 2009-11-20
  # ...and now we emit as a verbatim paragraph explicitly to remain (A) still
  # working and (B) valid. -- rjbs, 2009-11-26
  $html =~ s/^/  /gsm;

  return $html;
}

sub synhi_params_for_para {
  my ($self, $para) = @_;

  if (
    $para->isa('Pod::Elemental::Element::Pod5::Region')
    and    $para->format_name eq 'perl'
  ) {
    die "=begin :perl makes no sense\n" if $para->is_pod;

    my $perl = $para->children->[0]->as_pod_string;
    return {
      content => $para->content,
      options => ($1 || ''),
      syntax  => 'perl',
    }
  } elsif ($para->isa('Pod::Elemental::Element::Pod5::Verbatim')) {
    my $content = $para->content;
    return unless $content =~ s/\A\s*#!perl(?:\s+(\S+))?\n+//gsm;
    return {
      content => $content,
      options => ($1 || ''),
      syntax  => 'perl',
    }
  }

  return;
}

1;
