package WWW::AdventCalendar::Article;
use Moose;

use autodie;
use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::PPIHTML;
use Pod::Elemental::Transformer::VimHTML;
use Pod::Elemental::Transformer::WikiDoc;
use Pod::Hyperlink::BounceURL;
use Pod::Simple::XHTML;
use Pod::AdventXHTML;
use Pod::Xhtml;

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
  Pod::Elemental::Transformer::PPIHTML->new->transform_node($document);
  Pod::Elemental::Transformer::VimHTML->new->transform_node($document);
  Pod::Elemental::Transformer::WikiDoc->new->transform_node($document);

  $body = $document->as_pod_string;

  open my $fh, '<', \$body;

  my $linkparser = Pod::Hyperlink::BounceURL->new;
  $linkparser->configure(URL => 'http://search.cpan.org/perldoc?%s');

  my $string;

  if (0) {
    my $parser = Pod::AdventXHTML->new;
    $parser->output_string(\$string);
    $parser->accept_targets_as_text('xhtml');
    $parser->parse_file($fh);
    $string = "<div class='pod'>$string</div>";
  } else {
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

     $string = $px->asString;
  }

  $string =~ s{
    \s*(<pre>)\s*
    (<table\sclass='code-listing'>.+?
    \s*</table>)\s*(?:<!--\shack\s-->)?\s*(</pre>)\s*
  }{my $str = $2; $str =~ s/\G^\s\s[^\$]*$//gm; $str}gesmx;

  return $string;
}

sub fake_guid {
  my ($self) = @_;

  return sprintf 'urn:uuid:0984725a-%04u-%04u-%04u-d317acc4aa0b',
    $self->date->year,
    $self->date->month,
    $self->date->day;
}

1;
