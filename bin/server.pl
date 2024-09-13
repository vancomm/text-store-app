#!/usr/bin/env perl

use strict;
use warnings;

use Mojolicious::Lite;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use TextStore::User qw//;

my %conf = (
    users_file => 'user.data',
);

my $users_file = $conf{users_file};

get '' => sub {
    my $c = shift;

    $c->render(template => 'index');
};

post '/user' => sub {
    my $c = shift;

    my $user = $c->req->json;
    my ($id, $err) = TextStore::User::insert($users_file, $user);
    if (defined $err) {
        $c->render(json => {err => $err});
    } else {
        $c->render(json => {id => $id});
    }
};

get '/user/:id' => sub {
    my $c = shift;

    my $id = $c->param('id');
    my ($user, $err) = TextStore::User::get($users_file, $id);
    if (defined $err) {
        $c->render(json => {err => $err});
    } else {
        $c->render(json => {user => $user});
    }
};

put '/user/:id' => sub {
    my $c = shift;

    my $id = $c->param('id');
    my $user = $c->req->json;
    my $err = TextStore::User::update($users_file, $id, $user);
    if (defined $err) {
        $c->render(json => {err => $err});
    } else {
        $c->rendered(200);
    }
};

del '/user/:id' => sub {
    my $c = shift;

    my $id = $c->param('id');
    TextStore::User::remove($users_file, $id);
    $c->rendered(200);
};

app->start();

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    Hello world!
</body>
</html>