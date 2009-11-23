package Calendar::Advent::Article;
use Moose;

use autodie;
use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::PPIHTML;
use Pod::Elemental::Transformer::WikiDoc;
use Pod::Hyperlink::BounceURL;
use Pod::Xhtml;

has date => (is => 'ro', isa => 'DateTime', required => 1);
has [ qw(title package body) ] => (is => 'ro', isa => 'Str', required => 1);

sub body_xhtml {
  my ($self) = @_;

  my $body = $self->body;

  my $document = Pod::Elemental->read_string($body);

  Pod::Elemental::Transformer::Pod5->new->transform_node($document);
  Pod::Elemental::Transformer::PPIHTML->new->transform_node($document);
  Pod::Elemental::Transformer::WikiDoc->new->transform_node($document);

  $body = $document->as_pod_string;

  open my $fh, '<', \$body;

  my $linkparser = Pod::Hyperlink::BounceURL->new;
  $linkparser->configure(URL => 'http://search.cpan.org/perldoc?%s');

  my $px = Pod::Xhtml->new(
    FragmentOnly => 1,
    LinkParser   => $linkparser,
    MakeIndex    => 0,
    MakeMeta     => 0,
    StringMode   => 1,
    TopHeading   => 2,
    TopLinks     => 0,
  );
  $px->parse_from_filehandle($fh);

  my $string = $px->asString;

  $string =~ s{
    \s*<pre>\s*
    (<table\sclass='ppi-html'>.+?
    \s*</table>)\s*(?:<!--\shack\s-->)?\s*</pre>\s*
  }{$1}gsmx;

  $string =~ s{<pre>}{<pre>&nbsp;\n}g;

  return $string;
}

1;
