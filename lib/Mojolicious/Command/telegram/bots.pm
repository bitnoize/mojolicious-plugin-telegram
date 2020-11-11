package Mojolicious::Command::telegram::bots;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw/getopt dumper/;

has description => "Telegram bots config display";
has usage       => sub { shift->extract_usage };

sub run {
  my ($self, @args) = @_;

  my $app = $self->app;

  my $t = $app->telegram;

  say dumper $t->bots;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::telegram::bots - Telegram bots config display

=head1 SYNOPSIS

  Usage: APPLICATION telegram bots [OPTIONS]

    mojo telegram bots

  Options:
    -h, --help    Show this summary of available options

=cut

