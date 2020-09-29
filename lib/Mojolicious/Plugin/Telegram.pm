package Mojolicious::Plugin::Telegram;
use Mojo::Base 'Mojolicious::Plugin';

use MojoX::TBot;

our $VERSION = "0.02";
$VERSION = eval $VERSION;

sub register {
  my ($plugin, $app, $conf) = @_;

  $app->attr(tbot => sub { MojoX::TBot->new(%$conf) });

  $app->routes->add_shortcut(
    tbot =>  sub {
      my ($r, $name, %params) = @_;

      $params{webhook} //= $name;

      $r->post(
        "/tbot/<tbot_webhook>" => {
          tbot_webhook => $params{webhook}
        }
      )->to(
        format  => 'json',

        cb  => sub {
          my ($c) = @_;

          warn $c->dumper($c->res->json);
        }
      )->name("tbot_$name");
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

