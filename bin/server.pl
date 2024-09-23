#!/usr/bin/env perl

use strict;
use warnings;

use Mojolicious::Lite;
use Time::Piece qw//;
use DBI qw//;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Model qw//;
use Model::User qw//;
use Store::DB::User qw//;
use Controller::User qw//;
use Project::Config qw//;

my %conf = Project::Config::load();

my $dbh_opts = {
    RaiseError => 1,
    PrintError => 0,
    AutoCommit => 0,
};
my ($conn_cb, $err) = Model::get_connect_cb(
    $conf{db}{dsn}, $conf{db}{user}, $conf{db}{password}, $dbh_opts
);

die $err if defined($err);

my $model = Model::User->new($conn_cb);
my $uh = Controller::User->new($model);

# my $dbh = DBI->connect(
#     $conf{db}{dsn}, $conf{db}{user}, $conf{db}{password}, $dbh_opts,
# ) or die 'could not connect to database: ' . DBI::errstr;

# my $store = Store::DB::User->new($dbh);
# my $uh = Controller::User->new($store);

get '/' => 'index';

get '/users' => sub {
    my $c = shift;

    my ($users, $err) = $uh->get_all();

    if (defined($err)) {
        $c->flash(message => $err);
        return $c->redirect_to('error');
    }

    my $birthday_fmt = Store::DB::User::lookup_fmt('birthday');
    $c->stash(users => $users, birthday_fmt => $birthday_fmt);
    $c->render('users');
};

post '/user' => sub {
    my $c = shift;

    my ($id, $err) = $uh->create($c->req->params->to_hash);
    if (defined $err) {
        $c->flash(message => $err);
        return $c->redirect_to('error');
    }
    $c->flash(message => 'Created record id ' . $id);
    $c->redirect_to('success');
};

get '/user/edit/:id' => sub {
    my $c = shift;

    my $id = $c->param('id');
    my ($user, $err) = $uh->find($id);
    if (defined($err)) {
        $c->flash(message => $err);
        return $c->redirect_to('error');
    }
    $c->stash(id => $id, user => $user);
    $c->render('edit');
};

del '/user/:id' => sub {
    my $c = shift;

    my $id = $c->param('id');
    my $err = $uh->remove($id);
    if (defined($err)) {
        $c->flash(message => $err);
        return $c->redirect_to('error');
    }
    $c->redirect_to('users');
};

put '/user/:id' => sub {
    my $c = shift;

    my $id = $c->param('id');
    my $updates = $c->req->params->to_hash;
    $c->log->debug($updates);
    my ($user, $err) = $uh->update($id, $updates);
    if (defined($err)) {
        $c->flash(message => $err);
        return $c->redirect_to('error');
    }
    $c->redirect_to('users');
};

get '/success' => 'success';

get '/error' => 'error';

app->start();
__DATA__

@@ index.html.ep
% title 'Hello';
% layout 'base';
Hello world!
<br>
%= link_to Users => '/users'

@@ users.html.ep
% title 'Users';
% layout 'base';
%= form_for '/user' => (method => 'POST') => begin
    <fieldset style="width: fit-content;">
        <legend class="inverse" style="padding: 3px 6px;">
            new user
        </legend>
        %= label_for name => 'name'
        %= text_field name => '', required => ''
        <br>
        %= label_for funds => 'funds'
        %= number_field funds => '', required => ''
        <br>
        %= label_for birthday => 'birthday'
        %= date_field birthday => '', required => ''
        <br>
        %= submit_button 'Submit'
    </fieldset>
% end
<br>
<table style="padding: 3px 6px">
    <thead style="font-weight: bold;">
        <tr>
            <td>id</td>
            <td>name</td>
            <td>age</td>
            <td>funds</td>
            <td colspan=2>actions</td>
        </tr>
    </thead>
    <tbody>
    % for my $user (@{$users}) {
        <tr>
            % use POSIX qw//;
            % use Time::Piece qw//;
            % my $now = Time::Piece::gmtime;
            % my $dob = Time::Piece->strptime($user->{birthday}, $birthday_fmt);
            % my $age = POSIX::floor(($now - $dob) / (86400 * 365));
            % my $id = $user->{id};

            <td style="text-align: right;">
                %= $id
            </td>
            <td>
                %= $user->{name}
            </td>
            <td style="text-align: right;">
                %= $age
            </td>
            <td style="text-align: right;">
                %= $user->{funds}
            </td>
            <td style="padding: 0;">
                %= button_to Edit => "/user/edit/$id" => (style => 'display: inline-block;')
            </td>
            <td>
                %= button_to Delete => "/user/$id?_method=DELETE" => (method => 'POST') => (style => 'display: inline-block;')
            </td>
        </tr>
    % }
    </tbody>
</table>

@@ edit.html.ep
% title 'Edit';
% layout 'base';
%= form_for "/user/$id?_method=PUT" => (method => 'POST') => begin
    <fieldset style="width: fit-content;">
        <legend class="inverse" style="padding: 3px 6px;">
            edit user (id <%= $id %>)
        </legend>
        %= label_for name => 'name'
        %= text_field name => $user->{name}, required => ''
        <br>
        %= label_for funds => 'funds'
        %= number_field funds => $user->{funds}, required => ''
        <br>
        %= label_for birthday => 'birthday'
        %= date_field birthday => $user->{birthday}, required => ''
        <br>
        %= submit_button 'Submit'
    </fieldset>
% end
%= link_to Back => '/users'


@@ success.html.ep
% title 'Success';
% layout 'base';
<p>
    Success! <%= flash 'message' %>
</p>
%= link_to Back => '/users'

@@ error.html.ep
% title 'Error';
% layout 'base';
<p>
    Error: <%= flash('message') // 'unknown error' %>
</p>
%= link_to Back => '/users'

@@ layouts/base.html.ep
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= title %></title>
    <style>
        :root {
            color-scheme: light dark; /* both supported */
        }
        html {
            font-family: system-ui, sans-serif;
        }
        td {
            padding-right: .5rem;
        }
        .inverse {
            background-color: black;
            color: white;
        }
        @media (prefers-color-scheme: dark) {
            .inverse {
                background-color: white;
                font-weight: 600;
                color: black;
            }
        }
    </style>
</head>
<body>
    %= content
</body>
</html>