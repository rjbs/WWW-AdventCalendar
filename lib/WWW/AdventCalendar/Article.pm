package WWW::AdventCalendar::Article;
use Moose;

use autodie;
use Pod::Elemental;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::PPIHTML;
use Pod::Elemental::Transformer::VimHTML;
use Pod::Elemental::Transformer::WikiDoc;
use Pod::Hyperlink::BounceURL;
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
    # use Pod::Simple::XHTML;
    # my $parser = Pod::Simple::XHTML->new;
    # $parser->output_string(\$string);
    # $parser->parse_file($fh);
    # sub Pod::Simple::XHTML::_end_head {
    #   my $h = delete $_[0]{in_head};
    #   $h++;
    #   my $id = $_[0]->idify($_[0]{scratch});
    #   my $text = $_[0]{scratch};
    #   $_[0]{'scratch'} = qq{<h$h id="$id">$text</h$h>};
    #   $_[0]->emit;
    #   push @{ $_[0]{'to_index'} }, [$h, $id, $text];
    # }
    # $string = "<div class='pod'>$string</div>";
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
    \s*<pre>\s*
    (<table\sclass='code-listing'>.+?
    \s*</table>)\s*(?:<!--\shack\s-->)?\s*</pre>\s*
  }{my $str = $1; $str =~ s/\G^\s\s[^\$]*$//gm; $str}gesmx;

  $string =~ s{<pre>}{<pre>&nbsp;\n}g;

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
