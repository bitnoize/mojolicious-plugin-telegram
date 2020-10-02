package Mojolicious::Command::telegram;
use Mojo::Base 'Mojolicious::Commands';

has description => "Telegram commands";

has hint => <<EOF;
See 'APPLICATION telegram help COMMAND' for more information on a specific command.
EOF

has message    => sub { shift->extract_usage . "\nCommands:\n" };
has namespaces => sub { ['Mojolicious::Command::telegram'] };

sub help { shift->run(@_) }

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::telegram - Telegram specific commands

=head1 SYNOPSIS

  Usage: APPLICATION telegram COMMAND [OPTIONS]

