use inc::Module::Install 0.87;

name('CatalystAdvent');
abstract('Catalyst Application');
author('Catalyst developers');
version_from('lib/CatalystAdvent.pm');
license('perl');

include('ExtUtils::AutoInstall');

requires( Catalyst => '5.60' );
requires( 'Catalyst::Plugin::DefaultEnd' );
requires( 'Catalyst::Plugin::Unicode' );
requires( 'Catalyst::Plugin::Cache::FileCache' );
requires( 'DateTime' );
requires( 'File::stat' );
requires( 'Pod::Xhtml' );
requires( 'Calendar::Simple' );
requires( 'XML::Atom::SimpleFeed' );
requires( 'HTTP::Date' );
requires( 'List::Util' );

catalyst_files();

install_script( glob('script/*.pl') );
auto_install();
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/examples/CatalystAdvent/';

&WriteAll;
