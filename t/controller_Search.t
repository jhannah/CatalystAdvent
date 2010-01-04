use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Search' }
BEGIN { use_ok 'CatalystAdvent::Controller::Search' }

ok( request('/search')->is_success, 'Request should succeed' );



done_testing();
