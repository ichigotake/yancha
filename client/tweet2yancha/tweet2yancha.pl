#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use AnyEvent;
use lib qw| lib ../../lib |;
use Yancha::Client::Tweet2Yancha;

my $cv = AnyEvent->condvar;
my $io; $io = AnyEvent->io(
    fh   => \*STDIN,
    poll => 'r',
    cb   => sub {
        chomp(my $input = <STDIN>);
        undef $io;
        $cv->send($input);
        warn 'end';
    },
);

my $yancha = Yancha::Client::Tweet2Yancha->new(
    yancha_url => 'http://localhost:3000',
    api_endpoint => '/api/post',
    nick => 'ついとりちゃん@bot',
);

my $id;

my $cv_timer = AnyEvent->condvar;
my $timer; $timer = AnyEvent->timer(
    after    => 0,
    interval => 5,
    cb       => sub {
            my $content = $yancha->search_twitter( ['test', 'hachioji'] );
            if ( $id && $content ) {
                for my$res( @{ $content->{ results } } ) {
                    last if ($id >= $res->{ id });
                    next if ($yancha->is_retweet( $res->{ text } ));
                    $yancha->yancha_post( $res );
                    $id = $res->{ id };
                }
            }
            else {
                $id = $content->{ results }[0]->{ id };
            }
            $cv_timer->send;

        },
    );
$cv_timer->recv;


if (defined(my $input = $cv->recv)) {
    print "'ついとりちゃん' stoped\n";
}


