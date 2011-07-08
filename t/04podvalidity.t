use Test::More;
use FindBin qw($Bin);

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my @pod_files = glob( "$Bin/../root/2*/*.pod" );
all_pod_files_ok(@pod_files);
