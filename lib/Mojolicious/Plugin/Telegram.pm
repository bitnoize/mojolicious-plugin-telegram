package Mojolicious::Plugin::Telegram;
use Mojo::Base 'Mojolicious::Plugin';

use MojoX::Telegram;

our $VERSION = "0.01";
$VERSION = eval $VERSION;

sub register {
  my ($plugin, $app, $conf) = @_;

  my @conf = qw/api_base api_token/;
  my %conf = map { $_ => $conf->{$_} } grep { defined $conf->{$_} } @conf;

  $app->attr(telegram => sub { MojoX::Telegram->new(%conf) });

  $app->routes->add_shortcut(
    telegram =>  sub {
      my ($r, $name, %params) = @_;

      $params{webhook} //= $name;

      $r->post(
        "/telegram-bot/<webhook>" => {
          webhook => $params{webhook}
        }
      )->to(
        format    => 'json',
        bot_name  => $name,

        cb => sub {
          my ($c) = @_;

          warn $c->dumper($c->res->json);
        }
      )->name("telegram_$name");
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

    $app->telegram->getMe->then(sub {
      my ($result, $description, $error_code) = @_;

      if ($result) {
        warn $result->{username};
      }
    })->catch(sub {
      my ($message) = @_;
      warn "Error: $message";
    });
  }

=head1 AUTHOR

Dmitry Krutikov E<lt>monstar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Dmitry Krutikov.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the README file.

=cut
