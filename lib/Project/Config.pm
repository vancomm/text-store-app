package Project::Config;

use strict;
use warnings;

use List::Util qw//;

use Exporter 'import';
our @EXPORT_OK = qw/load/;

my %conf;

sub _mysql_timeouts {
    "mysql_connect_timeout=20;mysql_write_timeout=20;mysql_read_timeout=20"
}

sub _mysql_server_prepare {
    "mysql_server_prepare=1"
}

sub load {
    return %conf if exists $conf{ok};

    my $db_name = $ENV{DB_NAME};
    my $db_user = $ENV{DB_USER};
    my $db_host = $ENV{DB_HOST};
    my $db_password = $ENV{DB_PASSWORD};
    my $db_port = $ENV{DB_PORT};

    my @required_vars = ($db_name, $db_user, $db_host, $db_password, $db_port);

    my $db_conf = {};
    unless (List::Util::all { defined $_ } @required_vars) {
        warn "warning: some configuration vars are not defined, check your environment\n";
    } else {
        my $dsn = "DBI:mysql:database=$db_name;host=$db_host;port=$db_port";
        $dsn .= ';' . _mysql_timeouts if _mysql_timeouts;
        $dsn .= ';' . _mysql_server_prepare if _mysql_server_prepare;
        $db_conf = {
            dsn => $dsn,
            user => $db_user,
            password => $db_password,
        };
    }

    %conf = (
        ok => 1,
        users_filename => 'users.jsonl',
        db => $db_conf,
    );

    return %conf;
}

1;