use strict;
use warnings;
use utf8;
use PocketIO::Test;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use JSON;
use Test::More;
use Yancha::Client;
use t::Utils;

BEGIN {
    use Test::More;
    plan skip_all => 'PocketIO::Client::IO are required to run this test'
      unless eval { require PocketIO::Client::IO; 1 };
}

my $testdb  = t::Utils->setup_testdb(schema => './db/init.sql');
my $config = {
    database => {connect_info => [$testdb->dsn]},
    server_info => {
        default_tag => 'PUBLIC',
        api_endpoint => {
            '/api/data' => ['Yancha::API::Data', {}, 'For testing'],
        }
    },
};
my $server = t::Utils->server_with_dbi(config => $config);

test_pocketio $server => sub {
    my ($port) = @_;
    my $client = Yancha::Client->new;

    ok $client->login(
        "http://localhost:$port/" => 'login', {nick => 'test_client'}
    ), 'login';

    my $ua = LWP::UserAgent->new;
    my $post_by_api = sub {
        my ($text) = @_;
        my $req = POST "http://localhost:$port/api/data" => {
            default_tag => 1,
        };
        my $data = $ua->request($req)->content;
        eq_array JSON::decode_json($data), ['PUBLIC'];
    };

};


done_testing;
