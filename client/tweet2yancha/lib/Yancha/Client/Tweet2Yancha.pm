package Yancha::Client::Tweet2Yancha;

use strict;
use warnings;
use Encode qw/encode_utf8/;
use URL::Encode qw/url_encode_utf8/;
use JSON;
use HTTP::Request::Common qw/POST/;
use LWP::UserAgent;
use Yancha::Client;

our $VERSION = '0.01';

sub client { $_[0]->{ client } }
sub user { $_[0]->{ user } }
sub ua   { $_[0]->{ ua } }

sub new {
    my ($class, @args) = @_;
    my $self = bless { @args }, $class;
    $self->{ ua } = LWP::UserAgent->new;

    $self->{ client } = Yancha::Client->new;
    my $res = $self->client->login(
        $self->{ yancha_url }, => 'login', { nick => $self->{ nick } || 'ついとりちゃん@bot' }
    );
    $self->client->connect;
    $self->{ client }->run(sub {
        my ( $self, $socket ) = @_;
        $socket->emit('token login', $self->token);
    });
    return $self;
}

sub is_retweet { $_[1] =~ m/^RT/ }

sub get_token {
    my ($self) = @_;

    my $token;
    unless ( $token = $self->client->token ) {
        $self->client->login(
            $self->{ yancha_url }, => 'login', { nick => $self->{ nick } || 'ついとりちゃん@bot' }
        );
        $self->client->connect;

        $token = $self->client->token;
    }

    return $token;
}

#todo: Yancha::Clientを使わずにWebAPIからトークン取得
#todo: トークンの期限切れ対応
sub yancha_post {
    my ($self, $text) = @_;

    unless ( $text ) {
        return 0;
    }

    my $param = {
        text  => $self->make_post( $text ),
        token => $self->get_token(),
    };

    my $endpoint = $self->{ yancha_url } . $self->{ api_endpoint };
    warn $endpoint;
    my $req = POST($endpoint, $param);
    my $res = $self->ua->request( $req );
}

#todo: 発言フォーマットを外部ファイルで設定する
sub make_post {
    my ($self, $data) = @_;

    my $url = 'http://twitter.com/status/' . $data->{ from_user } . '/' . $data->{ id };
    my $formated = '@' . $data->{ from_user } . ': ' . $data->{ text } . "\n" . $url . ' #TWITTER';

    return $formated;
}

sub search_twitter {
    my ($self, $word) = @_;

    my $endpoint = 'http://search.twitter.com/search.json?q=';
    $endpoint .= url_encode_utf8($word);

    my $res = $self->ua->get( $endpoint );

    my $data;
    if ( $res->is_success ) {
        $data = eval { decode_json( $res->content ) };
        if ( $@ ) {
            $data = {};
        }
    }
    else {
        $data = {};
    }

    return $data;
}
1;
__END__

=encoding utf8

=head1 NAME

Yancha::Client::Tweet2Yancha - post to Yancha from Twitter search. Yet another name is 'ついとりちゃん('twitori-chan')

=head1 SYNOPSIS

    use Yancha::Client::Tweet2Yancha;

    my $client = Yancha::Client::Tweet2Yancha->new(
        yancha_url => 'http://localhost:3000',
        api_endpoint => '/api/post',
        nick => 'ついとりちゃん@bot',
    );

    my @keywords = qw/hachojipm ltthon/; # OR検索
    my $posts = $client->search_twitter( @keywords );
    foreach my $post( @{ $posts } ) {
        next if ($client->is_retweet($post->{ text }));
        $yancha->yancha_post( $post );
    }

=head1 DESCRIPTION

Twitterのキーワード検索の結果をYanchaへ投稿します。

=head1 METHOD

=over 4

=item my $twitori = Yancha::Client::Tweet2Yancha->new(%args);

Yancha::Client::Tweet2Yancha のインスタンスを生成します

インスタンスを生成した段階でYanchaへログインします。

=over 4

=item yancha_url: Str

投稿先のYanchaサーバーのURLを設定します。

=item api_endpoint: Str

投稿先Yanchaサーバーの発言APIのエンドポイントを指定します。

Default: '/api/post'

=item nick: Str

ついとりちゃんのYanchaサーバーでのログイン表示名を設定します。

Default: 'ついとりちゃん@bot'

=item hashtag: Str

ついとりちゃんがYanchaへ投稿する時のタグを設定します。

Default: 'TWITTER'

=back

=item my $content = $twitori->twitter_search(@keyword)

Twitterのキーワード検索APIの取得結果を配列で返します。

引数に複数のキーワードを指定した場合はOR検索になります。

Twitter検索API仕様: https://dev.twitter.com/docs/using-search

=item my $res = $twitori->yancha_post($text);

a

=over 4

=head1 SEE ALSO

http://github.com/uzulla/yancha.git

=head1 AUTHOR

Takayuki Otake E<lt>k.wisiiy @ GMAIL COME<gt>

=head1 TODO

Yancha::Clientを使わずにWebAPIでトークンを取得するようにする

トークンの期限切れ時に再取得するようにする

発言フォーマットやサーバー情報などを外部ファイルにまとめる

=head1 LICENSE

Copyright (C) Takayuki Otake

This library is free software; you can redistribure it and/or modify
it under the same terms as Perl itself.

=cut
