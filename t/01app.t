use Test::More;
BEGIN { use_ok( Catalyst::Test, 'CatalystAdvent' ); }

ok( request('/')->is_success );
ok( request('/2008')->is_success );
ok( request('/2008/02')->is_success );

ok( request('/rss')->is_success );
ok( request('/feed')->is_success );
ok( request('/rss/2008')->is_success );
ok( request('/feed/2008')->is_success );

done_testing;
