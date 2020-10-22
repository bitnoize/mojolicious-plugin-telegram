package Mojolicious::Plugin::Telegram;
use Mojo::Base 'Mojolicious::Plugin';

use MojoX::Telegram;

our $VERSION = "0.04";
$VERSION = eval $VERSION;

sub register {
  my ($plugin, $app, $conf) = @_;

  my $bots_farm = $conf->{bots_farm} //= {};

  for my $bot_id (keys %$bots_farm) {
    my $config = $bots_farm->{$bot_id};

    $config->{webhook_entry} //= $conf->{webhook_entry};

    die "Telegram '$bot_id' malformed configuration\n"
      unless defined $config->{webhook_entry}
        and  defined $config->{webhook_route}
        and  defined $config->{auth_token}
  }

  $app->helper(telegram => sub {
    state $telegram = MojoX::Telegram->new(bots_farm => $bots_farm);
  });

  $app->routes->add_shortcut(
    telegram => sub {
      my ($r, $bot_id) = @_;

      my $config = $app->telegram->_config($bot_id);

      $r->post($config->{webhook_route})->to(
        format  => 'json',
        bot_id  => $bot_id,
        action  => 'webhook'
      )->name("telegram_$bot_id");
    }
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Telegram - Telegram Bot API for your Mojolicious app

=head1 SYNOPSIS

  # Mojolicious app
  sub startup {
    my ($app) = @_;

    # Load plugin
    $app->plugin('Mojolicious::Plugin::Telegram' => {
      # Default webhook_entry for all bots
      webhook_entry => 'https://my.test.site.com',

      bots_farm => {
        # First bot
        test_bot  => {
          webhook_route => "/telegram/s3cret-one",
          auth_token    => "000001:AAAAAA"
        },

        # Second bot
        another_test => {
          # Special webhook_entry can be defined too
          webhook_entry => "https://another.site.test.com",
          webhook_route => "/telegram/s3cret-two",
          auth_token    => "000002:BBBBBB"
        },

        # Third bot
        another_one => {
          webhook_route => "/telegram/s3cret-three",
          auth_token    => "000003:CCCCCC"
        },
      }
    });

    # Register webhook for 'test_bot'
    $app->routes->telegram('test_bot')->to(cb => sub {
      my $c = shift->render_later;

      my $bot_id = $c->stash('bot_id');

      my $update = $c->req->json;

      return $c->render
        unless my $message = $update->{message};

      warn $c->dumper($message);

      ...

      $c->render(json => {
        method  => 'sendMessage',
        chat_id => $message->{chat}{id},
        text    => "Some text message!"
      });
    });

    # Promise interface
    $app->telegram->getMe_p('test_bot')->then(sub {
      my ($result, $description, $error_code) = @_;

      if ($result) {
        say $result->{somedata};
      }

      else {
        warn "Error: $error_code $description\n";
      }
    })->catch(sub {
      my ($message) = @_;

      warn "Error: $message\n";
    });
  }

=head1 AUTHOR

Dmitry Krutikov E<lt>monstar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Dmitry Krutikov.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the README file.

=cut

