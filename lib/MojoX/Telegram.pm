package MojoX::Telegram;
use Mojo::Base -base;

use Carp 'croak';
use Mojo::UserAgent;
use Mojo::Util qw/monkey_patch dumper/;
use Scalar::Util qw/looks_like_number/;

use constant DEBUG => $ENV{MOJOX_TELEGRAM_DEBUG} || 0;

has ua        => sub { Mojo::UserAgent->new };

has api_entry => sub { Mojo::URL->new("https://api.telegram.org") };
has bots_farm => sub { die "There are no any bots in the farm yet" };

sub new {
  my $self = shift->SUPER::new(@_);

  $self->ua->max_redirects(0)->connect_timeout(3)->request_timeout(5);

  return $self;
}

sub webhook {
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
  monkey_patch __PACKAGE__, $method => sub {
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

  croak "missing bot_id for config"
    unless defined $bot_id;

  my $config = $self->bots_farm->{$bot_id};

  die "Telegram bot '$bot_id' config not defined\n"
    unless ref $config eq 'HASH';

  die "Telegram bot '$bot_id' config malformed\n"
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

  my $telegram = MojoX::Telegram->new(api_token => '...');
  $telegram->getMe->then(sub {
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

L<MojoX::Ethereum> implements the following attributes.

=head2 ua

  my $ua    = $telegram->ua;
  $telegram = $telegram->ua(Mojo::UserAgent->new);

UserAgent object to use for JSON-RPC requests to Telegram Bot API.

=head2 api_base

  my $api_base  = $telegram->api_base;
  $telegram     = $telegram->api_base(Mojo::URL->new("api.telegram.org"));

Base URL object for UserAgent.

=head2 api_token

  my $api_token = $telegram->api_token;
  $telegram     = $telegram->api_token("0000000000:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-0");

Token string to authorize with requests.

=head1 METHODS

L<MojoX::Telegram> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 setWebhook

=head2 deleteWebhook

=head2 getWebhookInfo

=head2 getMe

=head2 sendMessage

=head2 deleteMessage


=head1 DEBUGGING

You can set the C<MOJOX_TELEGRAM_DEBUG> environment variable to get some
advanced diagnostics information printed to C<STDERR>.

  MOJOX_TELEGRAM_DEBUG=1

=head1 SEE ALSO

L<Mojo::UserAgent>, L<https://core.telegram.org/bots/api>.

=cut

