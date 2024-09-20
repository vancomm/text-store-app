package Project::Config;

use strict;
use warnings;

use List::Util qw//;

use Exporter 'import';
our @EXPORT_OK = qw/load/;

my %conf;

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
        $db_conf = {
            dsn => "DBI:mysql:database=$db_name;host=$db_host;port=$db_port",
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