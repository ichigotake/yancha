package Yancha::API::Data;

use strict;
use warnings;
use utf8;
use Encode;
use parent qw(Yancha::API);
use Yancha::DataStorage;

sub run {
    my ( $self, $req ) = @_;

    my $tags;
    if ( $req->param('default_tag') ) {
        $tags = $self->sys->config->{server_info}->{default_tag};
        $tags = [$tags] unless ref $tags;
        return $self->response_as_json($tags, 200);
    }


    return $self->response_as_json($tags, 400);
}

1;
