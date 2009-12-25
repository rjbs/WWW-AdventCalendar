package WWW::AdventCalendar::Config;
use Moose;
extends 'Config::MVP::Reader::INI';
# ABSTRACT: Config::MVP-based configuration reader for WWW::AdventCalendar

=head1 DESCRIPTION

You probably want to read about L<WWW::AdventCalendar> or L<Config::MVP>.

This is just a L<Config::MVP::Reader::INI> subclass that will begin its
assembler in a section named "C<_>" with a few multivalue args and aliases
pre-configured.

Apart from that, there is nothing to say.

=cut

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
