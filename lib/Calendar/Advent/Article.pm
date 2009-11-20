package Calendar::Advent::Article;
use Moose;

has body  => (is => 'ro', isa => 'Str',      required => 1);
has title => (is => 'ro', isa => 'Str',      required => 1);
has date  => (is => 'ro', isa => 'DateTime', required => 1);

1;
