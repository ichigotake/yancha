use strict;
use warnings;
use PocketIO::Test;
use t::Utils;
use AnyEvent;
use Yancha::Client;

BEGIN {
    use Test::More;
    plan skip_all => 'PocketIO::Client::IO are required to run this test'
      unless eval { require PocketIO::Client::IO; 1 };
}

my $testdb = t::Utils->setup_testdb( schema => './db/init.sql' );
my $config = {
    'database' => { connect_info => [ $testdb->dsn ] },
    'plugins' => [
        [ 'Yancha::Plugin::DenyDoubleSimpleLogin' => [ mark => '_', sns_key => ['-'] ] ],
    ],
};
my $server = t::Utils->server_with_dbi( config => $config );

my $client = sub {
    my ( $port ) = shift;

    my $cv = AnyEvent->condvar;
    my $w  = AnyEvent->timer( after => 10, cb => sub {
        fail("Time out.");
        $cv->send;
    } );

    my $on_connect = sub {
        my ( $client ) = @_;
        my $count = 0;

        $client->socket->on('nicknames' => sub {
            my @nicknames = sort keys %{ $_[1] };

            if ( @nicknames >= 3 ) {
                is_deeply( \@nicknames, [qw/user user_ user__/], 'three uesrs' );
                $cv->send;
            }

        });

    };

    my ( $client1, $client2 ) = t::Utils->create_clients_and_set_tags(
        $port,
        { nickname => 'user', on_connect => $on_connect }, 
        { nickname => 'user' },
        { nickname => 'user' },
    );

    my $timer = AnyEvent->timer( after => 5, cb => sub {
        $client2->socket->close;
    } );

    $cv->wait;
};

test_pocketio $server, $client;

ok(1, 'test done');

done_testing;

