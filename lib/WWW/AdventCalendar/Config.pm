package WWW::AdventCalendar::Config;
use Moose;
extends 'Config::MVP::Reader::INI';

use Config::MVP::Assembler;

sub build_assembler {
  my $assembler = Config::MVP::Assembler->new;

  my $section = $assembler->section_class->new({
    name => '_',
    aliases => { category => 'categories' },
    multivalue_args => [ qw( categories ) ],
  });
  $assembler->sequence->add_section($section);

  return $assembler;
}

1;
