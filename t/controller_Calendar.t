
use Test::More tests => 3;
use_ok( Catalyst::Test, 'CatalystAdvent' );
use_ok('CatalystAdvent::Controller::Calendar');

ok( request('calendar')->is_success );

