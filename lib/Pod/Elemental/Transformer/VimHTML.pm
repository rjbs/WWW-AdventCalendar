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

  return $self->standard_code_block( $vim->html );
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
