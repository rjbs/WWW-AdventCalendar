package WWW::AdventCalendar::Config;
# ABSTRACT: Config::MVP-based configuration reader for WWW::AdventCalendar

use Moose;
extends 'Config::MVP::Reader::INI';

use namespace::autoclean;

=head1 DESCRIPTION

You probably want to read about L<WWW::AdventCalendar> or L<Config::MVP>.

This is just a L<Config::MVP::Reader::INI> subclass that will begin its
assembler in a section named "C<_>" with a few multivalue args and aliases
pre-configured.

Apart from that, there is nothing to say.

=cut

use Config::MVP::Assembler;

{
  package
    WWW::AdventCalendar::Config::Assembler;
  use Moose;
  extends 'Config::MVP::Assembler';
  use namespace::autoclean;
  sub expand_package { return undef }
}

{
  package
    WWW::AdventCalendar::Config::Palette;
  $INC{'WWW/AdventCalendar/Config/Palette.pm'} = 1;
}

sub build_assembler {
  my $assembler = WWW::AdventCalendar::Config::Assembler->new;

  my $section = $assembler->section_class->new({
    name => '_',
    aliases => {
      category => 'categories',
      css_href => 'css_hrefs',
    },
    multivalue_args => [ qw( categories css_hrefs ) ],
  });
  $assembler->sequence->add_section($section);

  return $assembler;
}

1;
