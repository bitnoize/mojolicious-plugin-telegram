package Mojolicious::Command::telegram::bots_farm;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw/getopt dumper/;

has description => "Telegram bots_farm config display";
has usage       => sub { shift->extract_usage };

sub run {
  my ($self, @args) = @_;

  my $log       = $self->app->log;
  my $telegram  = $self->app->telegram;

  say dumper $telegram->bots_farm;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::telegram::bots_farm - Telegram bots_farm config display

=head1 SYNOPSIS

  Usage: APPLICATION telegram bots_farm [OPTIONS]

    mojo telegram bots_farm

  Options:
    -h, --help    Show this summary of available options

=cut

