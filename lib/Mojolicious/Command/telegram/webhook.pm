package Mojolicious::Command::telegram::webhook;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw/getopt dumper/;

has description => "Telegram webhook related commands";
has usage       => sub { shift->extract_usage };

sub run {
  my ($self, @args) = @_;

  my $log       = $self->app->log;
  my $telegram  = $self->app->telegram;

  my $action = 'show';

  getopt \@args,
    "i|bot-id=s"  => \my $bot_id,
    "s|setup"     => sub { $action = 'setup' };

  my %actions = (
    show  => sub {
      $telegram->getWebhookInfo_p($bot_id)->then(sub {
        my ($result, $description, $error_code) = @_;

        return Mojo::Promise->reject("Telegram error: $description $error_code")
          unless $result;

        say "Show webhook => ", dumper $result;
      });
    },

    setup => sub {
      my $params = {
        url => $telegram->webhook_url($bot_id)->to_string,
        allowed_updates => [ ],
      };

      $telegram->setWebhook_p($bot_id, $params)->then(sub {
        my ($result, $description, $error_code) = @_;

        return Mojo::Promise->reject("Telegram error: $description $error_code")
          unless $result;

        $telegram->getWebhookInfo_p($bot_id);
      })->then(sub {
        my ($result, $description, $error_code) = @_;

        return Mojo::Promise->reject("Telegram error: $description $error_code")
          unless $result;

        say "Setup webhook => ", dumper $result;
      });
    }
  );

  die $self->usage unless $bot_id and $actions{$action};
  my $promise = $actions{$action}->();

  $promise->catch(sub {
    my ($error) = @_;

    $log->fatal("Telegram webhook: $error");
  })->wait;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Command::telegram::webhook - Telegram Bot API webhook control

=head1 SYNOPSIS

  Usage: APPLICATION telegram webhook [OPTIONS]

    mojo telegram webhook -i test_bot
    mojo telegram webhook -i test_bot -s

  Options:
    -i, --bot-id  Specify bot identifier
    -s, --setup   Setup values from config
    -h, --help    Show this summary of available options

=cut

