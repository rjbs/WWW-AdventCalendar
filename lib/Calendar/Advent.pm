package Calendar::Advent;
use Moose;

use autodie;
use Calendar::Advent::Article;
use Calendar::Simple;
use DateTime;
use DateTime::Format::W3CDTF;
use Email::Simple;
use File::Copy qw(copy);
use File::Path qw(remove_tree);
use DateTime;
use File::Basename;
use Template;
use XML::Atom::SimpleFeed;

has root   => (is => 'ro', isa => 'Str',   required => 1);
has share  => (is => 'ro', isa => 'Str',   required => 1);
has output => (is => 'ro', isa => 'Str',   required => 1);
has today  => (is => 'rw', isa => 'Value');

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
    time_zone => 'America/New_York',
  );
}

sub BUILD {
  my ($self) = @_;

  my $today = $self->today
            ? _parse_isodate($self->today, [localtime])
            : DateTime->now(time_zone => 'America/New_York');

  $self->today($today);
}

sub build {
  my ($self) = @_;

  remove_tree($self->{output});
  mkdir($self->{output});

  my $template = Template->new(
    WRAPPER => 'templates/wrapper.tt',
    PRE_CHOMP  => 1,
    POST_CHOMP => 1,
  );

  my $share = $self->{share};
  copy $_ => $self->{output} for <$share/*>;

  my $feed = XML::Atom::SimpleFeed->new(
    title   => 'RJBS Advent Calendar',
    link    => 'http://advent.rjbs.manxome.org/',
    link    => {
      rel  => 'self',
      href => 'http://advent.rjbs.manxome.org/atom.xml',
    },
    updated => DateTime::Format::W3CDTF->new->format_datetime($self->today),
    author  => 'Ricardo Signes',
    id      => 'urn:uuid:0984725a-d60d-11de-b491-d317acc4aa0b',
  );

  my %dec;
  for (1 .. 31) {
    $dec{$_} = DateTime->new(
      year  => 2009,
      month => 12,
      day   => $_,
      time_zone => 'America/New_York',
    );
  }

  if ($dec{1} > $self->today) {
    my $dur  = $dec{1} - $self->today;
    my $days = $dur->delta_days + 1;
    my $str  = $days != 1 ? "$days days" : "1 day";

    $template->process(
      'templates/patience.tt',
      {
        days => $str,
        year => $self->today->year,
      },
      "$self->{output}/index.html",
    ) || die $template->error;

    $feed->add_entry(
      title     => "The RJBS Advent Calendar is Coming",
      link      => "http://advent.rjbs.manxome.org/",
      id        => 'urn:uuid:5fe50e6e-d862-11de-8370-7b1cadc4aa0b',
      summary   => "The first door opens in $str days...\n",
      updated   => DateTime::Format::W3CDTF->new->format_datetime($self->today),
      category  => 'Perl',
      category  => 'RJBS',
    );

    open my $atom, '>', "$self->{output}/atom.xml";
    $feed->print($atom);
    close $atom;

    exit;
  }

  my $article = $self->read_articles;

  {
    my $d = $dec{1};
    while (
      $d->ymd le (sort { $a cmp $b } ($dec{25}->ymd, $self->today->ymd))[0]
    ) {
      warn "no article written for " . $d->ymd . "!\n"
        unless $article->{ $d->ymd };

      $d = $d + DateTime::Duration->new(days => 1 );
    }
  }

  $template->process(
    'templates/year.tt',
    {
      now  => $self->today,
      year => $self->today->year,
      calendar    => scalar calendar(12, $self->today->year),
      article_for => sub { $article->{sprintf("2009-12-%02u", $_[0])} },
    },
    "$self->{output}/index.html",
  ) || die $template->error;

  my @dates = sort keys %$article;
  for my $i (0 .. $#dates) {
    my $date = $dates[ $i ];

    my $output;

    print "processing article for $date...\n";
    $template->process(
      'templates/article.tt',
      {
        article   => $article->{ $date },
        date      => $date,
        tomorrow  => ($i < $#dates ? $dates[ $i + 1 ] : undef),
        yesterday => ($i > 0       ? $dates[ $i - 1 ] : undef),
        year      => $self->today->year,
      },
      \$output,
    ) || die $template->error;

    open my $fh, '>', "$self->{output}/$date.html";
    print $fh $output;
  }

  for my $date (reverse @dates){
    my $article = $article->{ $date };

    $feed->add_entry(
      title     => $article->title,
      link      => "http://advent.rjbs.manxome.org/$date.html",
      id        => $article->fake_guid,
      summary   => Encode::decode('utf-8', $article->body_xhtml),
      updated   => DateTime::Format::W3CDTF->new->format_datetime($article->date),
      category  => 'Perl',
      category  => 'RJBS',
    );
  }

  open my $atom, '>', "$self->{output}/atom.xml";
  $feed->print($atom);
  close $atom;
}

sub read_articles{
  my ($self) = @_;
  my $root = $self->{root};

  my @files = <$root/*>;

  my %article;

  for my $file (@files) {
    my ($name, $path) = fileparse($file);
    $name =~ s{\..+\z}{}; # remove extension
    my $document = Email::Simple->new(scalar `cat $file`);
    my $isodate  = $document->header('Date') || $name;

    die "no title set in $file\n" unless $document->header('title');

    my $article  = Calendar::Advent::Article->new(
      body  => $document->body,
      date  => _parse_isodate($isodate),
      title => $document->header('title'),
      package => $document->header('package'),
    );

    next unless $article->date < $self->today;

    die "already have an article for " . $article->date->ymd
      if $article{ $article->date->ymd };

    $article{ $article->date->ymd } = $article;
  }

  return \%article;
}

sub today { $_[0]->{today} }

1;
