#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use TextStore::User qw//;
use Getopt::Long::Subcommand;

my $default_filename = 'user.data';

my $usage = "usage: $0 [-fh] <command>

commands:
    insert  <name> <height> <birthday>      Insert a new record into the 
                                            database. Returns record id
    get    <id>                             Read an existing record
    update  <id> [-s, --set <key>=<value>]  Update an existing record
    remove  <id>                            Delete an existing record

options:
    -f, --filename <FILE>                   Path to database file
    -h, --help                              Print this message and exit
";

my %opts = (filename => $default_filename);
my $res = GetOptions (
    options => {
        'f|filename=s' => \$opts{filename},
        'h|help' => sub { say $usage; exit 0; },
    },
    subcommands => {
        insert => {},
        get => {},
        update => {
            options => {
                's|set=s%' => \$opts{updates},
            }
        },
        remove => {},
    },
);

die $usage unless $res->{success};
die "no command provided\n$usage" unless @{$res->{subcommand}};

my $command = shift @{$res->{subcommand}};
my $nargs = @ARGV;
my $filename = $opts{filename};

if ($command eq 'insert') {
    die "insert expected 3 args, but received $nargs\n$usage" if $nargs != 3;

    my ($name, $height, $birthday) = @ARGV;
    my $user = {name => $name, height => $height, birthday => $birthday};
    my ($id, $err) = TextStore::User::insert($filename, $user);
    die "insert error: $err\n" if defined $err;

    say $id;
} elsif ($command eq 'get') {
    die "read expected 1 arg, but received $nargs\n$usage" if $nargs != 1;

    my $id = shift @ARGV;
    my ($user, $err) = TextStore::User::get($filename, $id);
    die "read error: $err\n" if defined $err;

    say join ' ', $user->{name}, $user->{height}, $user->{birthday};
} elsif ($command eq 'update') {
    die "update expected 1 arg, but received $nargs\n$usage" if $nargs != 1;
    die 'update requires at least one field' unless defined $opts{updates};

    my $id = shift @ARGV;
    my $updates = $opts{updates};
    my $err = TextStore::User::update($filename, $id, $updates);
    die "update error: $err\n" if defined $err;
} elsif ($command eq 'remove') {
    die "remove expected 1 arg, but received $nargs\n$usage" if $nargs != 1;
    
    my $id = shift @ARGV;
    TextStore::User::remove($filename, $id);
}