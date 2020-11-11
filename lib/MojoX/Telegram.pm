package MojoX::Telegram;
use Mojo::Base -base;

use Carp 'croak';
use Scalar::Util qw/looks_like_number/;
use Mojo::Util qw/monkey_patch dumper/;
use Mojo::URL;
use Mojo::UserAgent;

use constant DEBUG => $ENV{MOJOX_TELEGRAM_DEBUG} || 0;

has ua        => sub { Mojo::UserAgent->new };

has api_base  => sub { Mojo::URL->new("https://api.telegram.org") };
has bots      => sub { die "There are no any bots defined!" };

sub new {
  my $self = shift->SUPER::new(@_);

  $self->ua->max_redirects(0)->connect_timeout(3)->request_timeout(5);

  return $self;
}

sub webhook_url {
  my ($self, $bot_id) = @_;

  my $config = $self->config($bot_id);

  my $url = Mojo::URL->new($config->{webhook_base});

  my $webhook_under = Mojo::Path->new($config->{webhook_under});
  $webhook_under->leading_slash(1)->trailing_slash(1);

  my $webhook_path = Mojo::Path->new($config->{webhook_path});
  $webhook_path->leading_slash(0)->trailing_slash(0);

  return $url->path($webhook_under->merge($webhook_path))->to_string;
}

state @METHODS = qw/
  setWebhook
  deleteWebhook
  getWebhookInfo
  getMe
  sendMessage
  deleteMessage
  sendPhoto
  sendAudio
  sendDocument
  sendVideo
  sendAnimation
  sendVoice
  sendVideoNote
  sendMediaGroup
  sendLocation
  editMessageLiveLocation
  stopMessageLiveLocation
  sendVenue
  sendContact
  sendPoll
  sendDice
  sendChatAction
  getUserProfilePhotos
  getFile
  kickChatMember
  unbanChatMember
  restrictChatMember
  promoteChatMember
  setChatAdministratorCustomTitle
  setChatPermissions
  exportChatInviteLink
  setChatPhoto
  deleteChatPhoto
  setChatTitle
  setChatDescription
  pinChatMessage
  unpinChatMessage
  leaveChat
  getChat
  getChatAdministrators
  getChatMembersCount
  getChatMember
  setChatStickerSet
  deleteChatStickerSet
  answerCallbackQuery
  setMyCommands
  getMyCommands
  editMessageText
  editMessageCaption
  editMessageMedia
  editMessageReplyMarkup
  stopPoll
/;

for my $method (@METHODS) {
  monkey_patch __PACKAGE__, "${method}_p" => sub {
    shift->_api_call($method, @_)
  };
}

sub _api_call {
  my ($self, $method, $bot_id, $params) = @_;

  my $config = $self->config($bot_id);

  my $api_path = sprintf "/bot%s/%s", $config->{auth_token}, $method;
  my $api_url  = $self->api_base->clone->path($api_path);

  my $headers = {
    'Content-Type' => 'application/json'
  };

  warn "-- Telegram bot '$bot_id' $method request => ", dumper $params
    if DEBUG;

  $self->ua->post_p($api_url, $headers, json => $params)->then(sub {
    my ($tx) = @_;

    my $res = $tx->result;

    if ($res->is_success) {
      my $json = $res->json;

      warn "-- Telegram bot '$bot_id' $method response => ", dumper $json
        if DEBUG;

      die "Telegram API call: malformed response\n"
        unless ref $json eq 'HASH' and defined $json->{ok};

      if ($json->{ok}) {
        my $result = $json->{result};

        die "Telegram API call: malformed result\n"
          unless defined $result;

        return Mojo::Promise->resolve($result, $json->{description});
      }

      else {
        my @pass = qw/description error_code parameters/;
        return Mojo::Promise->resolve(undef, @$json{@pass});
      }
    }

    else {
      return Mojo::Promise->resolve(undef, $res->message, $res->code);
    }
  });
}

sub config {
  my ($self, $bot_id) = @_;

  croak "Telegram config missing 'bot_id'"
    unless defined $bot_id and not ref $bot_id;

  my $config = $self->bots->{$bot_id};

  die "Telegram '$bot_id' config undefined\n"
    unless defined $config and ref $config eq 'HASH';

  die "Telegram '$bot_id' config malformed\n"
    unless defined $config->{webhook_base}
      and  defined $config->{webhook_under}
      and  defined $config->{webhook_path}
      and  defined $config->{auth_token};

  return $config;
}

1;

=encoding utf8

=head1 NAME

MojoX::Telegram - JSON-RPC client for Telegram Bot API

=head1 SYNOPSIS

  my $telegram = MojoX::Telegram->new(
    bots => {
      'test_bot'  => {
        webhook_base  => "https://my.test.site.com",
        webhook_under => "webhook",
        webhook_path  => "s3cret-one",
        auth_token    => "000001:AAAAAA"
      },

      'another_test' => {
        webhook_base  => "https://another.site.test.com",
        webhook_under => "webhook",
        webhook_path  => "s3cret-two",
        auth_token    => "000002:BBBBBB"
      },

      'third_bot' => {
        webhook_base  => "https://my.test.site.com",
        webhook_under => "webhook",
        webhook_path  => "s3cret-three",
        auth_token    => "000003:CCCCCC"
      },
    }
  );

  # Promise interface
  $telegram->getMe_p('test_bot')->then(sub {
    my ($result, $description, $error_code) = @_;

    if ($result) {
      say $result->{somedata};
    }

    else {
      warn "Error: $error_code $description\n";
    }
  })->catch(sub { warn "Error: @_\n" })->wait;

=head1 DESCRIPTION

L<MojoX::Telegram> is a simple JSON-RPC client for Telegram Bot API.

=head1 ATTRIBUTES

L<MojoX::Telegram> implements the following attributes.

=head2 ua

  my $ua    = $telegram->ua;
  $telegram = $telegram->ua(Mojo::UserAgent->new);

UserAgent object to use for JSON-RPC requests to Telegram Bot API.

=head2 api_base

  my $api_base  = $telegram->api_base;
  $telegram     = $telegram->api_base(Mojo::URL->new("https://api.telegram.org"));

Telegram API URL object for UserAgent.

=head2 bots

  my $bots = {
    test_bot => {
      webhook_base  => "",
      webhook_under => "",
      webhook_path  => "",
      auth_token    => ""
    },

    ...
  }

  my $bots  = $telegram->bots;
  $telegram = $telegram->bots($bots);

Farm of bots.

=head1 METHODS

L<MojoX::Telegram> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 webhook_url

  my $url = $telegram->webhook_url($bot_id);

Return full webhook URL for specified $bot_id.

=head2 setWebhook_p

=head2 deleteWebhook_p

=head2 getWebhookInfo_p

=head2 getMe_p

=head2 sendMessage_p

=head2 deleteMessage_p


=head1 DEBUGGING

You can set the C<MOJOX_TELEGRAM_DEBUG> environment variable to get some
advanced diagnostics information printed to C<STDERR>.

  MOJOX_TELEGRAM_DEBUG=1

=head1 SEE ALSO

L<Mojo::UserAgent>, L<https://core.telegram.org/bots/api>.

=cut

