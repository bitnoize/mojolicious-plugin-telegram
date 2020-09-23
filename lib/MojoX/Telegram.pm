package MojoX::Telegram;
use Mojo::Base -base;

use Scalar::Util 'looks_like_number';
use Mojo::Util qw/monkey_patch dumper/;

use constant DEBUG => $ENV{MOJOX_TELEGRAM_DEBUG} || 0;

has ua => sub { Mojo::UserAgent->new };

has api_base  => sub { Mojo::URL->new("https://api.telegram.org") };
has api_token => sub { die "Attribute 'app_token' is required" };

sub new {
  my $self = shift->SUPER::new(@_);

  $self->ua->max_redirects(0)->connect_timeout(3)->request_timeout(5);

  return $self;
}

# Telegram Bot HTTP API
# https://core.telegram.org/bots/api

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
    my ($self, %params) = @_;

    $self->_api_call($method, \%params);
  };
}

sub _api_call {
  my ($self, $method, $params) = @_;

  my $api_path = sprintf "/bot%s/%s", $self->api_token, $method;
  my $api_url  = $self->api_base->clone->path($api_path);

  my $headers = {
    'Content-Type' => 'application/json'
  };

  warn "-- Telegram API request params => ", dumper $params
    if DEBUG;

  $self->ua->post_p($api_url, $headers, json => $params)->then(sub {
    my ($tx) = @_;

    my $res = $tx->result;

    if ($res->is_success) {
      my $json = $res->json;

      warn "-- Telegram API response json => ", dumper $json
        if DEBUG;

      die "Telegram API call: malformed response json\n"
        unless ref $json eq 'HASH' and defined $json->{ok};

      if ($json->{ok}) {
        my $result = $json->{result};

        die "Telegram API call: malformed response result\n"
          unless defined $result;

        return Mojo::Promise->resolve($result, $json->{description});
      }

      else {
        my @onward = qw/description error_code parameters/;
        return Mojo::Promise->resolve(undef, @$json{@onward});
      }
    }

    else {
      my $error = sprintf "code %s message %s", $res->code, $res->messsage;
      return Mojo::Promise->reject("Telegram API call: connection $error");
    }
  });
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
      warn $result->{username};
    }
  })->catch(sub {
    my ($message) = @_;

    warn "Error: $message";
  });

