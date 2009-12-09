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

  $html =~ s/\A\n+//;
  1 while chomp $html;

  my @lines = split /\n/, $html;

  my $numbers = join "\n",
                map {; $_ = sprintf "%2s:&nbsp;", $_; s/ /&nbsp;/g; $_ }
                (1 .. @lines);
  my $code    = join "\n", @lines;

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
