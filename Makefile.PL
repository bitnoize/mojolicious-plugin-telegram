#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => "Mojolicious::Plugin::Telegram",
  VERSION_FROM  => "lib/Mojolicious/Plugin/Telegram.pm",
  ABSTRACT      => "Telegram Bot API for your Mojolicious app",
  LICENSE       => 'artistic_2',
  AUTHOR        => "Dmitry Krutikov <monstar\@cpan.org>",
  PREREQ_PM     => {
    'Mojolicious' => '8.12'
  },
  test => { TESTS => 't/*.t' }
);
