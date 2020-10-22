package MojoX::Telegram;
use Mojo::Base -base;

use Carp 'croak';
use Mojo::UserAgent;
use Mojo::Util qw/monkey_patch dumper/;
use Scalar::Util qw/looks_like_number/;

use constant DEBUG => $ENV{MOJOX_TELEGRAM_DEBUG} || 0;

has ua        => sub { Mojo::UserAgent->new };

has api_entry => sub { Mojo::URL->new("https://api.telegram.org") };
has bots_farm => sub { die "There are no any bots in the farm!" };

sub new {
  my $self = shift->SUPER::new(@_);

  $self->ua->max_redirects(0)->connect_timeout(3)->request_timeout(5);

  return $self;
}

sub webhook_url {
  my ($self, $bot_id) = @_;

  my $config = $self->_config($bot_id);

  my $url = Mojo::URL->new($config->{webhook_entry});
  return $url->path($config->{webhook_route})->to_abs;
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

  my $config = $self->_config($bot_id);

  my $api_path = sprintf "/bot%s/%s", $config->{auth_token}, $method;
  my $api_url  = $self->api_entry->clone->path($api_path);

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
        my @onward = qw/description error_code parameters/;
        return Mojo::Promise->resolve(undef, @$json{@onward});
      }
    }

    else {
      my $error = sprintf "code %s message %s", $res->code, $res->message;
      return Mojo::Promise->reject("Telegram API call: connection $error");
    }
  });
}

sub _config {
  my ($self, $bot_id) = @_;

  croak "Telegram missing 'bot_id' on config"
    unless defined $bot_id and not ref $bot_id;

  my $config = $self->bots_farm->{$bot_id};

  die "Telegram '$bot_id' config undefined\n"
    unless ref $config eq 'HASH';

  die "Telegram '$bot_id' config malformed\n"
    unless defined $config->{webhook_entry}
      and  defined $config->{webhook_route}
      and  defined $config->{auth_token};

  return $config;
}

1;

=encoding utf8

=head1 NAME

MojoX::Telegram - JSON-RPC client for Telegram Bot API

=head1 SYNOPSIS

  my $telegram = MojoX::Telegram->new(
    bots_farm => {
      test_bot  => {
        webhook_entry => "https://my.test.site.com",
        webhook_route => "/telegram/s3cret-one",
        auth_token    => "000001:AAAAAA"
      },

      another_test => {
        webhook_entry => "https://another.site.test.com",
        webhook_route => "/telegram/s3cret-two",
        auth_token    => "000002:BBBBBB"
      },

      third_bot => {
        webhook_entry => "https://my.test.site.com",
        webhook_route => "/telegram/s3cret-three",
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
  })->catch(sub {
    my ($message) = @_;

    warn "Error: $message\n";
  })->wait;

=head1 DESCRIPTION

L<MojoX::Telegram> is a simple JSON-RPC client for Telegram Bot API.

=head1 ATTRIBUTES

L<MojoX::Telegram> implements the following attributes.

=head2 ua

  my $ua    = $telegram->ua;
  $telegram = $telegram->ua(Mojo::UserAgent->new);

UserAgent object to use for JSON-RPC requests to Telegram Bot API.

=head2 api_entry

  my $api_entry = $telegram->api_entry;
  $telegram     = $telegram->api_entry(Mojo::URL->new("api.telegram.org"));

Telegram API URL object for UserAgent.

=head2 bots_farm

  my $bots_farm = {
    test_bot => {
      webhook_entry => "",
      webhook_route => "",
      auth_token    => ""
    },

    ...
  }

  my $bots_farm = $telegram->bots_farm;
  $telegram     = $telegram->bots_farm($bots_farm);

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

