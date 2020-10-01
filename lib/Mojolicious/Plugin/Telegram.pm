package Mojolicious::Plugin::Telegram;
use Mojo::Base 'Mojolicious::Plugin';

use MojoX::Telegram;

our $VERSION = "0.02";
$VERSION = eval $VERSION;

sub register {
  my ($plugin, $app, $conf) = @_;

  $conf->{webhook_entry}  //= "https://localhost";

  my $bots_farm = $conf->{bots_farm} //= {};

  for my $bot_id (keys %$bots_farm) {
    my $config = $bots_farm->{$bot_id};

    $config->{webhook_entry}  //= $conf->{webhook_entry};

    die "Telegram bot '$bot_id' requires 'webhook_route' config\n"
      unless defined $config->{webhook_route};

    die "Telegram bot '$bot_id' requires 'auth_token' config\n"
      unless defined $config->{auth_token};
  }

  $app->attr(telegram => sub {
    MojoX::Telegram->new(bots_farm => $bots_farm);
  });

  $app->routes->add_shortcut(
    telegram => sub {
      my ($r, $bot_id) = @_;

      my $config = $app->telegram->_config($bot_id);

      $r->post($config->{webhook_route})->to(
        format      => 'json',
        bot_id      => $bot_id
      )->name("telegram_$bot_id");
    }
  );
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Telegram - Telegram Bot API with Promises

=head1 SYNOPSIS

  # Mojolicious app
  sub startup {
    my ($app) = @_;

    $app->tbot->getMe->then(sub {
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

