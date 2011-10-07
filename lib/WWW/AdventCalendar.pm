package WWW::AdventCalendar;
use Moose;
# ABSTRACT: a calendar for a month of articles (on the web)

use autodie;
use Calendar::Simple;
use DateTime;
use DateTime::Format::W3CDTF;
use Email::Simple;
use File::Copy qw(copy);
use File::Path 2.07 qw(remove_tree);
use File::ShareDir;
use DateTime;
use File::Basename;
use HTML::Mason::Interp;
use Moose::Util::TypeConstraints;
use Path::Class ();
use XML::Atom::SimpleFeed;
use WWW::AdventCalendar::Article;

use namespace::autoclean;

=head1 DESCRIPTION

This is a library for producing Advent calendar websites.  In other words, it
makes four things:

=for :list
* a page saying "first door opens in X days" until Dec 1
* a calendar page on and after Dec 1
* a page for each day in December with an article
* an Atom feed

This library may be generalized somewhat in the future.  Until then, it should
work for at least December for every year.  It has only been tested for 2009,
which may be of limited utility going forward.

=head1 OVERVIEW

To build an Advent calendar:

=for :list
1. create an advent.ini configuration file
2. write articles and put them in a directory
3. schedule F<advcal> to run nightly

F<advent.ini> is easy to produce.  Here's the one used for the original RJBS
Advent Calendar:

  title  = RJBS Advent Calendar
  year   = 2009
  uri    = http://advent.rjbs.manxome.org/
  editor = Ricardo Signes
  category = Perl
  category = RJBS

  article_dir = rjbs/articles
  share_dir   = share

These should all be self-explanatory.  Only C<category> can be provided more
than once, and is used for the category listing in the Atom feed.

These settings all correspond to L<calendar attributes/ATTRIBUTES> described
below.

Articles are easy, too.  They're just files in the C<article_dir>.  They begin
with an email-like set of headers, followed by a body written in Pod.  For
example, here's the beginning of the first article in the original calendar:

  Title:  Built in Our Workshop, Delivered in Your Package
  Package: Sub::Exporter

  =head1 Exporting

  In Perl, we organize our subroutines (and other stuff) into namespaces called
  packages.  This makes it easy to avoid having to think of unique names for

The two headers seen above, title and package, are the only headers required,
and correspond to those attributes in the L<WWW::AdventCalendar::Article>
object created from the article file.

Finally, running L<advcal> is easy, too.  Here is its usage:

  advcal [-aot] [long options...]
    -c --config       the ini file to read for configuration
    -a --article-dir  the root of articles
    --share-dir       the root of shared files
    -o --output-dir   output directory
    --today           the day we treat as "today"; default to today

    -t --tracker      include Google Analytics; -t TRACKER-ID

Options given on the command line override those loaded form configuration.  By
running this program every day, we cause the calendar to be rebuilt, adding any
new articles that have become available.

=head1 ATTRIBUTES

=for :list
= title
The title of the calendar, to be used in headers, the feed, and so on.
= uri
The base URI of the calendar, including trailing slash.
= editor
The name of the calendar's editor, used in the feed.
= year
The year being calendared.
= categories
An arrayref of category names for use in the feed.
= article_dir
The directory in which articles can be found, with names like
F<YYYY-MM-DD.html>.
= share_dir
The directory for templates, stylesheets, and other static content.
= output_dir
The directory into which output files will be written.
= today
The date to treat as "today" when deciding how much of the calendar to publish.
= tracker_id
A Google Analytics tracker id.  If given, each page will include analytics.

=cut

has title  => (is => 'ro', required => 1);
has uri    => (is => 'ro', required => 1);
has editor => (is => 'ro', required => 1);
has subtitle   => (is => 'ro', predicate => 'has_subtitle');
has categories => (is => 'ro', default => sub { [ qw() ] });

has article_dir => (is => 'rw', required => 1);
has share_dir   => (is => 'rw', required => 1);
has output_dir  => (is => 'rw', required => 1);

has year       => (
  is   => 'ro',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    return $self->start_date->year if $self->_has_start_date;
    return $self->end_date->year   if $self->_has_end_date;

    return (localtime)[5] + 1900;
  },
);

class_type('DateTimeObject', { class => 'DateTime' });
coerce  'DateTimeObject', from 'Str', via \&_parse_isodate;

has start_date => (
  is   => 'ro',
  isa  => 'DateTimeObject',
  lazy => 1,
  coerce  => 1,
  default => sub { DateTime->new(year => $_[0]->year, month => 12, day => 1) },
  predicate => '_has_start_date',
);

has end_date => (
  is   => 'ro',
  isa  => 'DateTimeObject',
  lazy => 1,
  coerce  => 1,
  default => sub { DateTime->new(year => $_[0]->year, month => 12, day => 24) },
  predicate => '_has_end_date',
);

has today      => (is => 'rw');

has tracker_id => (is => 'ro');

sub _masonize {
  my ($self, $comp, $args) = @_;

  my $str = '';

  my $interp = HTML::Mason::Interp->new(
    comp_root  => [
      [ user  => $self->share_dir->subdir('templates')->absolute->stringify ],
      [ stock => Path::Class::dir(
          File::ShareDir::dist_dir('WWW-AdventCalendar') )
          ->subdir('templates')->absolute->stringify
      ],
    ],
    out_method => \$str,
    allow_globals => [ '$calendar' ],
  );

  $interp->set_global('$calendar', $self);

  $interp->exec($comp,
    tracker_id => $self->tracker_id,
    %$args
  );

  return $str;
}

sub _parse_isodate {
  my ($date, $time_from) = @_;

  my ($y, $m, $d) = $date =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/;
  die "can't parse date: $date\n" unless $y and $m and $d;

  $time_from ||= [ (0) x 10 ];

  return DateTime->new(
    year   => $y,
    month  => $m,
    day    => $d,
    hour   => $time_from->[2],
    minute => $time_from->[1],
    second => $time_from->[0],
    time_zone => 'local',
  );
}

sub BUILD {
  my ($self) = @_;

  $self->today(
    $self->today
    ? _parse_isodate($self->today, [localtime])
    : DateTime->now(time_zone => 'local')
  );

  confess "start_date, end_date, and year do not all agree"
    unless $self->year == $self->start_date->year
    and    $self->year == $self->end_date->year;

  for (map { "$_\_dir" } qw(article output share)) {
    $self->$_( Path::Class::Dir->new($self->$_) );
  }
}

=method build

  $calendar->build;

This method does all the work: it reads in the articles, decides how many to
show, writes out the rendered pages, the index, and the atom feed.

=cut

sub build {
  my ($self) = @_;

  $self->output_dir->rmtree;
  $self->output_dir->mkpath;

  my $share = $self->share_dir;
  copy "$_" => $self->output_dir
    for grep { ! $_->is_dir } $self->share_dir->subdir('static')->children;

  my $feed = XML::Atom::SimpleFeed->new(
    title   => $self->title,
    id      => $self->uri,
    link    => {
      rel  => 'self',
      href => $self->uri . 'atom.xml',
    },
    updated => $self->_w3cdtf($self->today),
    author  => $self->editor,
  );

  my %month;
  for (
    1 .. DateTime->last_day_of_month(
      year  => $self->year,
      month => $self->start_date->month
    )->day
  ) {
    $month{$_} = DateTime->new(
      year  => $self->year,
      month => $self->start_date->month,
      day   => $_,
      time_zone => 'local',
    );
  }

  if ($self->start_date > $self->today) {
    my $dur  = $self->start_date->subtract_datetime_absolute( $self->today );
    my $days = int($dur->delta_seconds / 86_400  +  1);
    my $str  = $days != 1 ? "$days days" : "1 day";

    $self->output_dir->file("index.html")->openw->print(
      $self->_masonize('/patience.mhtml', {
        days => $str,
        year => $self->year,
      }),
    );

    $feed->add_entry(
      title     => $self->title . " is Coming",
      link      => $self->uri,
      id        => $self->uri,
      summary   => "The first door opens in $str...\n",
      updated   => $self->_w3cdtf($self->today),

      (map {; category => $_ } @{ $self->categories }),
    );

    $feed->print( $self->output_dir->file('atom.xml')->openw );

    return;
  }

  my $article = $self->read_articles;

  {
    my $d = $month{1};
    while (
      $d->ymd le (sort { $a cmp $b } ($self->end_date->ymd, $self->today->ymd))[0]
    ) {
      warn "no article written for " . $d->ymd . "!\n"
        unless $article->{ $d->ymd };

      $d = $d + DateTime::Duration->new(days => 1 );
    }
  }

  $self->output_dir->file('index.html')->openw->print(
    $self->_masonize('/calendar.mhtml', {
      today  => $self->today,
      year   => $self->year,
      month  => \%month,
      calendar => scalar calendar(12, $self->year),
      articles => $article,
    }),
  );

  my @dates = sort keys %$article;
  for my $i (0 .. $#dates) {
    my $date = $dates[ $i ];

    my $output;

    print "processing article for $date...\n";
    my $txt = $self->_masonize('/article.mhtml', {
      article => $article->{ $date },
      date    => $date,
      next    => ($i < $#dates ? $article->{ $dates[ $i + 1 ] } : undef),
      prev    => ($i > 0       ? $article->{ $dates[ $i - 1 ] } : undef),
      year    => $self->year,
    });

    my $bytes = Encode::encode('utf-8', $txt);
    $self->output_dir->file("$date.html")->openw->print($bytes);
  }

  for my $date (reverse @dates){
    my $article = $article->{ $date };

    $feed->add_entry(
      title     => HTML::Entities::encode_entities($article->title),
      link      => $self->uri . "$date.html",
      id        => $article->atom_id,
      summary   => $article->body_html,
      updated   => $self->_w3cdtf($article->date),
      (map {; category => $_ } @{ $self->categories }),
    );
  }

  $feed->print( $self->output_dir->file('atom.xml')->openw );
}

sub _w3cdtf {
  my ($self, $datetime) = @_;
  DateTime::Format::W3CDTF->new->format_datetime($datetime);
}

=method read_articles

  my $article = $calendar->read_articles;

This method reads in all the articles for the calendar and returns a hashref.
The keys are dates (in the format C<YYYY-MM-DD>) and the values are
L<WWW::AdventCalendar::Article> objects.

=cut

sub read_articles {
  my ($self) = @_;

  my %article;

  for my $file (grep { ! $_->is_dir } $self->article_dir->children) {
    my ($name, $path) = fileparse($file);
    $name =~ s{\..+\z}{}; # remove extension

    open my $fh, '<:encoding(utf-8)', $file;
    my $content = do { local $/; <$fh> };
    my $document = Email::Simple->new($content);
    my $isodate  = $name;

    die "no title set in $file\n" unless $document->header('title');

    my $article  = WWW::AdventCalendar::Article->new(
      body  => $document->body,
      date  => _parse_isodate($isodate),
      title => $document->header('title'),
      package  => $document->header('package'),
      calendar => $self,
    );

    next unless $article->date < $self->today;

    die "already have an article for " . $article->date->ymd
      if $article{ $article->date->ymd };

    $article{ $article->date->ymd } = $article;
  }

  return \%article;
}

1;
