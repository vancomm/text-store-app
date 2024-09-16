package Project::Config;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/load/;

sub load {
    return {
        users_filename => "users.jsonl",
    };
}

1;