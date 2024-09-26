#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

use Getopt::Long::Subcommand;

use FindBin qw//;
use lib "$FindBin::Bin/../lib";
use Store::Text::User qw//;
use Controller::User qw//;
use Project::Config qw//;

my %conf = Project::Config::load();

my $usage = "usage: $0 [-fh] <command>

commands:
    create  <name> <funds> <birthday>       Insert a new record into the
                                            database. Returns record id
    read    <id>                            Read an existing record
            -a, --all                       Read all records
    update  <id> [-s, --set <key>=<value>]  Update an existing record
    delete  <id>                            Delete an existing record

options:
    -f, --filename <FILE>                   Path to database file
    -h, --help                              Print this message and exit
";

my %opts = (
    filename => $conf{users_filename},
);

my $res = GetOptions (
    options => {
        'f|filename=s' => \$opts{filename},
        'h|help' => sub { say $usage; exit 0; },
    },
    subcommands => {
        create => {},
        read => {
            options => {
                'a|all' => \$opts{read_all},
            }
        },
        update => {
            options => {
                's|set=s%' => \$opts{updates},
            }
        },
        delete => {},
    },
);

die $usage unless $res->{success};
die "error: no command provided\n$usage" unless @{$res->{subcommand}};

my $command = shift @{$res->{subcommand}};
my $nargs = @ARGV;

my $store = Store::Text::User->new($opts{filename});

my $uh = Controller::User->new($store);

if ($command eq 'create') {
    die "error: create expected 3 args, but received $nargs\n$usage" if $nargs != 3;

    my ($name, $funds, $birthday) = @ARGV;
    my ($id, $err) = $uh->create(
        {name => $name, funds => $funds, birthday => $birthday},
    );

    die "create error: $err\n" if defined $err;

    say $id;
} elsif ($command eq 'read') {
    if (defined $opts{read_all}) {
        
        my ($users, $err) = $uh->get_all();

        die "read all error: $err\n" if defined $err;

        for my $user (@$users) {            
            say join ' ', $user->{id}, $user->{name}, $user->{funds}, $user->{birthday};
        }
    } else {
        die "read expected 1 arg, but received $nargs\n$usage" if $nargs != 1;

        my $id = shift @ARGV;

        my ($user, $err) = $uh->find($id);

        die "read error: $err\n" if defined $err;

        say join ' ', $user->{name}, $user->{funds}, $user->{birthday};
    }
} elsif ($command eq 'update') {
    die "update expected 1 arg, but received $nargs\n$usage" if $nargs != 1;
    die 'update requires at least one field' unless defined $opts{updates};

    my $id = shift @ARGV;
    my $updates = $opts{updates};
    my $err = $uh->update($id, $updates);

    die "update error: $err\n" if defined($err);
} elsif ($command eq 'delete') {
    die "delete expected 1 arg, but received $nargs\n$usage" if $nargs != 1;

    my $id = shift @ARGV;
    my $err = $uh->remove($id);

    die "delete error: $err\n" if defined($err);
}