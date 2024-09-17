#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

use DBI qw//;
use DDP;

use FindBin qw/$Bin/;
use lib "$Bin/lib";
use DB::User qw//;
use Project::Config qw//;

my %conf = Project::Config::load();

my $users_file = $conf{users_filename};

my $dbh_opts = {
    RaiseError => 1,
    AutoCommit => 0,
};
my $dbh = DBI->connect(
    $conf{db}{dsn}, $conf{db}{user}, $conf{db}{password}, $dbh_opts,
) or die 'could not connect to database: ' . DBI::errstr;

my $uh = DB::User->new($dbh);

my $new_id = $uh->insert('Bbb', 25, '1999-12-31');
say 'inserted user id: ' . $new_id;

my %user = $uh->select($new_id);
p %user;

my $all_users = $uh->select_all();
p $all_users;

$uh->update($new_id, { name => 'Ccc' });

%user = $uh->select($new_id);
p %user;

$uh->remove($new_id);

$all_users = $uh->select_all();
p $all_users;

$dbh->disconnect();