use inc::Module::Install;

name('CatalystAdvent');
abstract('Catalyst Application');
author('Catalyst developer');
version_from('lib\CatalystAdvent.pm');
license('perl');

include('ExtUtils::AutoInstall');

requires( Catalyst => '5.60' );

catalyst_files();

install_script( glob('script/*.pl') );
auto_install();
&WriteAll;
