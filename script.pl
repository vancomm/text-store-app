#!/usr/bin/env perl

use strict;
use warnings;

use DBI qw//;
use Data::Dumper qw/Dumper/;

use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Store::DB::User qw//;
use Project::Config qw//;

for (1..5) {
    warn 'found: ' . Store::DB::User::lookup_fmt('birthday');
    warn "\n";
}

# my %conf = Project::Config::load();

# my $dbh_opts = {
#     RaiseError => 1,
#     AutoCommit => 0,
# };
# my $dbh = DBI->connect(
#     $conf{db}{dsn}, $conf{db}{user}, $conf{db}{password}, $dbh_opts,
# ) or die 'could not connect to database: ' . DBI::errstr;

# my $uh = Store::DB::User->new($dbh);

# my $new_id = $uh->insert({name => 'Bbb', funds => 25, birthday => '1999-12-31'});
# warn $new_id;

# my %user = $uh->select(1);
# print Dumper(%user);

# my $all_users = $uh->select_all();
# p $all_users;

# $uh->update(1, { name => 'Ccc', funds => 1, pwn => 'yes' });

# %user = $uh->select(1);
# print Dumper(%user);

# $uh->update(1, { pwn => 'yes' });

# %user = $uh->select(1);
# print Dumper(%user);

# $uh->remove($new_id);

# $all_users = $uh->select_all();
# p $all_users;

# $dbh->disconnect();