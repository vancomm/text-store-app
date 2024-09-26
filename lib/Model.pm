package Model;

use strict;
use warnings;

use DBI qw//;

sub get_connect_cb {
    my %args = @_;

    return sub {
        my $conn;
        eval {            
            $conn = DBI->connect_cached(@args{qw/dsn user password opts/});
        };
        if ($@) {
            return (undef, 'unable to connect to database: ' . $@)
        }
        return ($conn, undef)
    };

}

1;