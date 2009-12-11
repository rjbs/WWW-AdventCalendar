package Pod::Elemental::Transformer::SynHi;
use Moose::Role;
with 'Pod::Elemental::Transformer';

requires 'synhi_params_for_para';
requires 'build_html';

sub build_html_para {
  my ($self, $arg) = @_;

  my $new = Pod::Elemental::Element::Pod5::Region->new({
    format_name => 'xhtml',
    is_pod      => 0,
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

  my @lines = split /\n/, $html;

  # The leading nbsp below, in generating $code, is to try to get indentation
  # to appear in feed readers, which to not respect white-space:pre or the pre
  # element. The use of <br> instead of newlines is for the same reason.
  # -- rjbs, 2009-12-10
  my $nums  = join "<br />", map {; "$_:&nbsp;" } (1 .. @lines);
  my $code  = join "<br />",
              map {; s/^(\s+)/'&nbsp;' x length $1/me; $_ }
              @lines;

  # Another stupid hack: the <code> blocks below force monospace font.  It
  # can't wrap the whole table, though, because it would cause styling issues
  # in the rendered XHTML. -- rjbs, 2009-12-10
  $html = "<table class='code-listing'><tr>"
        . "<td class='line-numbers'><br /><code>$nums</code><br />&nbsp;</td>"
        . "<td class='code'><br /><code>$code</code><br />&nbsp;</td>"
        . "</table>";

  # This should not be needed, because this is a data paragraph, not a
  # ordinary paragraph, but Pod::Xhtml doesn't seem to know the difference
  # and tries to expand format codes. -- rjbs, 2009-11-20
  $html =~ s/^/  /gsm;

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
