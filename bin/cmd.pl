#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

use Getopt::Long::Subcommand;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Controller::User qw//;
use Project::Config qw//;

my $conf = Project::Config::load();

my $usage = "usage: $0 [-fh] <command>

commands:
    insert  <name> <height> <birthday>      Insert a new record into the 
                                            database. Returns record id
    get     <id>                            Read an existing record
            -a, --all                       Read all records
    update  <id> [-s, --set <key>=<value>]  Update an existing record
    remove  <id>                            Delete an existing record

options:
    -f, --filename <FILE>                   Path to database file
    -h, --help                              Print this message and exit
";

my %opts = (
    filename => $conf->{users_filename},
);

my $res = GetOptions (
    options => {
        'f|filename=s' => \$opts{filename},
        'h|help' => sub { say $usage; exit 0; },
    },
    subcommands => {
        insert => {},
        get => {
            options => {
                'a|all' => \$opts{get_all},
            }
        },
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

    my ($name, $funds, $birthday) = @ARGV;
    my ($id, $err) = Controller::User::insert(
        $filename, {name => $name, funds => $funds, birthday => $birthday},
    );

    die "insert error: $err\n" if defined $err;

    say $id;
} elsif ($command eq 'get') {
    if (defined $opts{get_all}) {
        my ($users, $err) = Controller::User::get_all($filename);

        die "get all error: $err\n" if defined $err;

        foreach my $pair (@$users) {
            my ($id, $user) = @$pair;
            say join ' ', $id, $user->{name}, $user->{funds}, $user->{birthday};
        }
    } else {
        die "read expected 1 arg, but received $nargs\n$usage" if $nargs != 1;

        my $id = shift @ARGV;

        my ($user, $err) = Controller::User::get($filename, $id);

        die "read error: $err\n" if defined $err;

        say join ' ', $user->{name}, $user->{funds}, $user->{birthday};
    }
} elsif ($command eq 'update') {
    die "update expected 1 arg, but received $nargs\n$usage" if $nargs != 1;
    die 'update requires at least one field' unless defined $opts{updates};

    my $id = shift @ARGV;
    my $updates = $opts{updates};
    my $err = Controller::User::update($filename, $id, $updates);

    die "update error: $err\n" if defined($err);
} elsif ($command eq 'remove') {
    die "remove expected 1 arg, but received $nargs\n$usage" if $nargs != 1;
    
    my $id = shift @ARGV;
    my $err = Controller::User::remove($filename, $id);

    die "delete error: $err\n" if defined($err);
}