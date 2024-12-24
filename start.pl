#!/usr/bin/env perl

use strict;
use warnings;

use Proc::Daemon;

my $daemon = Proc::Daemon->new(
    work_dir => '.',
    exec_command => 'hypnotoad bin/server.pl -f',
    child_STDOUT => '+>>daemon.out',
    child_STDERR => '+>>daemon.err',
    pid_file => 'daemon.pid',
);

my $pid = $daemon->Init;

warn "started process $pid\n";

sub stop {
    my $killed = $daemon->Kill_Daemon('QUIT');
    die("\r" . ($killed ? 'killed' : 'not killed') . " ($killed)\n");
}

$SIG{INT} = \&stop;

while (<>) {}

stop;
