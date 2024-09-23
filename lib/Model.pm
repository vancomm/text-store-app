package Model;

use strict;
use warnings;

use DBI qw//;
use List::Util qw//;

use Exporter 'import';
our @EXPORT_OK = qw//;

my @conns = ();

sub _create_conn {
    my ($dsn, $user, $password, $opts) = @_;

    my $conn;
    eval {
        $conn = DBI->connect($dsn, $user, $password, $opts);
    };
    if ($@) {
        return (undef, 'unable to connect to database: ' . $@)
    }

    return (undef, 'unable to connect to database (ping failed)')
        unless ($conn->ping());

    return ($conn, undef);
}

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