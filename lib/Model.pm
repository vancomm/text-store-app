package Model;

use strict;
use warnings;

use DBI qw//;
use List::Util qw//;

sub get_connect_cb {
    my ($dsn, $user, $password, $opts) = @_;

    return sub {
        my $conn;
        eval {
            $conn = DBI->connect_cached($dsn, $user, $password, $opts);
        };
        if ($@) {
            return (undef, 'unable to connect to database: ' . $@)
        }
        return ($conn, undef)
    };

}

1;