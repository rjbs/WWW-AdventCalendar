use strict;
use warnings;
use 5.010;

use DateTime;

use lib '/Users/rjbs/code/hub/list-cell/lib';

{
  package Calendar;
  use Moose;
  with 'List::Cell';

  has date => (is => 'ro', isa => 'DateTime', required => 1);

  sub day_of_week {
    return $_[0]->date->day_of_week % 7
  }

  sub BUILD {
    my ($self) = @_;
    $self->_ensure_start_sunday;
    $self->_ensure_end_saturday;
  }

  sub _ensure_start_sunday {
    my ($self) = @_;
    my $class = ref $self;

    my $first = $self->first;

    while ($first->day_of_week != 0) {
      my $prev_date = $first->date - DateTime::Duration->new(days => 1);
      my $prev_cell = $class->new({ date => $prev_date });

      say "moving " . $prev_cell->date->ymd . " to head";
      $prev_cell->replace_next($first);

      $first = $first->first;
    }
  }

  sub _ensure_end_saturday {
  }
}

my $cal = Calendar->new({
  date => DateTime->now(time_zone => 'local')
});

warn $cal->prev->date->ymd;

for (my $cell = $cal->first; $cell; $cell = $cell->next) {
  printf "%2s: %s\n", $cell->day_of_week, $cell->date->ymd;
}

