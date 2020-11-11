package Mojolicious::Command::telegram::webhook;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw/getopt dumper/;

has description => "Telegram webhook setup";
has usage       => sub { shift->extract_usage };

sub run {
  my ($self, @args) = @_;

  my $app = $self->app;

  my $log = $app->log;
  my $t   = $app->telegram;

  getopt \@args,
    "i|bot-id=s"  => \my $bot_id;

  die $self->usage unless $bot_id;

  my $url = $t->webhook_url($bot_id);

  $t->setWebhook_p($bot_id => {
    url             => $url,
    allowed_updates => [ ]
  })->then(sub {
    my ($result, $description, $error_code) = @_;

    return Mojo::Promise->reject("setWebhook: $description $error_code")
      unless defined $result;

    $t->getWebhookInfo_p($bot_id);
  })->then(sub {
    my ($result, $description, $error_code) = @_;

    return Mojo::Promise->reject("getWebhookInfo: $description $error_code")
      unless defined $result;

    say "WebHook => ", dumper $result;
  })->catch(sub {
    $log->fatal("Telegram WebHook @_");
  })->wait;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::telegram::webhook - Telegram WebHook setup

=head1 SYNOPSIS

  Usage: APPLICATION telegram webhook [OPTIONS]

    mojo telegram webhook -i test_bot

  Options:
    -i, --bot-id  Specify bot identifier
    -h, --help    Show this summary of available options

=cut

