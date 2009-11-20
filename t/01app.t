use Test::More tests => 2;
BEGIN { use_ok( Catalyst::Test, 'CatalystAdvent' ); }

ok( request('/')->is_success );
