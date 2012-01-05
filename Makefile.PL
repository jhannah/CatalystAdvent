use inc::Module::Install 0.87;

name('CatalystAdvent');
abstract('Catalyst Application');
author('Catalyst developers');
version_from('lib/CatalystAdvent.pm');
license('perl');

include('ExtUtils::AutoInstall');

requires Catalyst => '5.90';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Catalyst::Plugin::Unicode::Encoding';
requires 'Catalyst::Plugin::Cache' => '0.08';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Cache::FileCache';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::View::TT';
requires 'DateTime';
requires 'File::stat';
requires 'Pod::Xhtml';
requires 'Calendar::Simple';
requires 'XML::Atom::SimpleFeed';
requires 'HTTP::Date';
requires 'List::Util';
requires 'Template::Plugin::DateTime'; # EWWWWW
requires 'Date::Calc';
requires 'Catalyst::Action::RenderView';

test_requires 'Test::More' => '0.88';

catalyst;

install_script( glob('script/*.pl') );
auto_install();
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/examples/CatalystAdvent/';

WriteAll;
