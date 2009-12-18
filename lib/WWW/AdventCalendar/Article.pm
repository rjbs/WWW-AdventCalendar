package WWW::AdventCalendar::Article;
use Moose;
# ABSTRACT: one article in an advent calendar

use autodie;
use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::PPIHTML;
use Pod::Elemental::Transformer::VimHTML;
use Pod::Elemental::Transformer::List;
use Pod::Simple::XHTML 3.11;

BEGIN { 
  # Will be 3.12 when that is released -- rjbs, 2009-12-11
  die "Pod::Simple::XHTML with html_h_level support required"
    unless Pod::Simple::XHTML->can('html_h_level');
}

has date => (is => 'ro', isa => 'DateTime', required => 1);
has [ qw(title package body) ] => (is => 'ro', isa => 'Str', required => 1);

has body_xhtml => (
  is   => 'ro',
  lazy => 1,
  builder => '_build_body_xhtml',
);

sub _build_body_xhtml {
  my ($self) = @_;

  my $body = $self->body;

  my $document = Pod::Elemental->read_string($body);

  Pod::Elemental::Transformer::Pod5->new->transform_node($document);
  Pod::Elemental::Transformer::List->new->transform_node($document);
  Pod::Elemental::Transformer::PPIHTML->new->transform_node($document);
  Pod::Elemental::Transformer::VimHTML->new->transform_node($document);

  $body = $document->as_pod_string;

  my $parser = Pod::Simple::XHTML->new;
  $parser->output_string(\my $html);
  $parser->html_h_level(2);
  $parser->html_header('');
  $parser->html_footer('');

  $parser->parse_string_document( Encode::encode('utf-8', $body) );

  $html = "<div class='pod'>$html</div>";

  $html =~ s{
    \s*(<pre>)\s*
    (<table\sclass='code-listing'>.+?
    \s*</table>)\s*(?:<!--\shack\s-->)?\s*(</pre>)\s*
  }{my $str = $2; $str =~ s/\G^\s\s[^\$]*$//gm; $str}gesmx;

  return $html;
}

sub fake_guid {
  my ($self) = @_;

  return sprintf 'urn:uuid:0984725a-%04u-%04u-%04u-d317acc4aa0b',
    $self->date->year,
    $self->date->month,
    $self->date->day;
}

1;
