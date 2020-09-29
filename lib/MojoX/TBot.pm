package MojoX::TBot;
use Mojo::Base -base;

use Mojo::UserAgent;
use Mojo::Util qw/monkey_patch dumper/;
use Scalar::Util qw/looks_like_number/;

use constant DEBUG => $ENV{MOJOX_TBOT_DEBUG} || 0;

has ua        => sub { Mojo::UserAgent->new };

has api_base  => sub { Mojo::URL->new("https://api.telegram.org") };
has api_token => sub { die "Attribute 'app_token' is required" };

sub new {
  my $self = shift->SUPER::new(@_);

  $self->ua->max_redirects(0)->connect_timeout(3)->request_timeout(5);

  return $self;
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

  warn "-- TBot API request params => ", dumper $params
    if DEBUG;

  my @post_args = ($api_url, $headers, json => $params);
  $self->ua->post_p(@post_args)->then(sub {
    my ($tx) = @_;

    my $res = $tx->result;

    if ($res->is_success) {
      my $json = $res->json;

      warn "-- TBot API response json => ", dumper $json
        if DEBUG;

      die "TBot API call: malformed response JSON\n"
        unless ref $json eq 'HASH' and defined $json->{ok};

      if ($json->{ok}) {
        my $result = $json->{result};

        die "TBot API call: malformed response result\n"
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
      return Mojo::Promise->reject("TBot API call: connection $error");
    }
  });
}

1;

=encoding utf8

=head1 NAME

MojoX::TBot - JSON-RPC client for Telegram Bot API

=head1 SYNOPSIS

  my $tbot = MojoX::TBot->new(api_token => '...');
  $tbot->getMe->then(sub {
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

L<MojoX::TBot> is a simple JSON-RPC client for Telegram Bot API.

=head1 ATTRIBUTES

L<MojoX::Ethereum> implements the following attributes.

=head2 ua

  my $ua  = $tbot->ua;
  $tbot   = $tbot->ua(Mojo::UserAgent->new);

UserAgent object to use for JSON-RPC requests to Telegram Bot API.

=head2 api_base

  my $api_base  = $tbot->api_base;
  $tbot         = $tbot->api_base(Mojo::URL->new("api.telegram.org"));

Base URL object for UserAgent.

=head2 api_token

  my $api_token = $tbot->api_token;
  $tbot         = $tbot->api_token("00000:ABC");

Token string to authorize with requests.

=head1 METHODS

L<MojoX::TBot> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 setWebhook

=head2 deleteWebhook

=head2 getWebhookInfo

=head2 getMe

=head2 sendMessage

=head2 deleteMessage


=head1 DEBUGGING

You can set the C<MOJOX_TBOT_DEBUG> environment variable to get some
advanced diagnostics information printed to C<STDERR>.

  MOJOX_TBOT_DEBUG=1

=head1 SEE ALSO

L<Mojo::UserAgent>, L<https://core.telegram.org/bots/api>.

=cut

