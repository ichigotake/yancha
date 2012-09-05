use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Tweet2Yancha',
    AUTHOR        => 'ichigotake',
    VERSION_FROM  => 'lib/Yancha/Client/Tweet2Yancha.pm',
### XXX NOW FAILURE TO USING ABSTRACT_FROM
#    ABSTRACT_FROM => 'lib/Yancha.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'  => 0,
        'version'     => 0,
        'JSON'        => 0,
        'DBI'         => 0,
        'Encode'      => 0,
        'HTTP::Request::Coommon' => 0,
        'LWP::UserAgent' => 0,
        'AnyEvent'    => 0,
        'URL::Encode' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Yancha-*' },
);

