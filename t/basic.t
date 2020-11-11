use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use_ok('MojoX::Telegram');
use_ok('Mojolicious::Plugin::Telegram');
use_ok('Mojolicious::Command::telegram');
use_ok('Mojolicious::Command::telegram::bots');
use_ok('Mojolicious::Command::telegram::webhook');

done_testing;
