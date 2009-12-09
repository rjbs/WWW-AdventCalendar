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
  my $ppihtml = PPI::HTML->new;
  my $html    = $ppihtml->html( $ppi_doc );

  $opt =~ /stupid-hyphen/ and s/-/−/g for $html;

  $html =~ s/<br>\n?/\n/g;

  return $self->standard_code_block( $html );
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
