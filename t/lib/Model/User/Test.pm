package Model::User::Test;

use strict;
use warnings;

use base qw(Test::Class);

use Test::Most;
use List::Util;
use DBI;

use FindBin qw//;
use lib 'lib';
use Model qw//;
use Model::User qw//;

sub test_select_all_empty : Test(2) {
    my ($self) = @_;

    my ($users, $err) = $self->{uh}->select_all();
    ok !defined($err), 'must not return error' or diag $err;
    is scalar @$users, 0, 'no rows' or diag 'must have returned no rows';
}

sub test_insert_and_select_one : Test(3) {
    my ($self) = @_;

    my $params = {
        name => 'Larry Wall',
        funds => '1000000',
        birthday => '1954-09-27',
    };

    my ($user_id, $ins_err) = $self->{uh}->insert($params);
    ok !defined($ins_err), 'must not return error' or diag $ins_err;

    my ($user, $sel_err) = $self->{uh}->select_one($user_id);
    ok !defined($sel_err), 'must not return error' or diag $sel_err;

    my $approx_date_re = '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}';

    my $expected_user = {
        %$params,
        id => re('\d+'),
        created_at => re($approx_date_re),
        updated_at => re($approx_date_re),
        deleted_at => any((undef, re($approx_date_re))),
    };

    cmp_deeply(
        $user,
        $expected_user,
        'user must match expected shape'
    );
}

sub test_insert_fail : Test(1) {
    my ($self) = @_;

    my $params = {
        name => 'Larry Wall',
        # skipped required field 'funds'
        birthday => '1954-09-27',
    };

    my ($user_id, $ins_err) = $self->{uh}->insert($params);
    ok defined($ins_err), 'must return error' 
        or diag "returned user id: $user_id";
}

sub test_insert_and_select_many : Test(5) {
    my ($self) = @_;

    my $param_ary = [
        { name => 'Larry Wall', funds => 500, birthday => '1954-09-27' },
        { name => 'Barry Mall', funds => 400, birthday => '1970-01-01' },
        { name => 'Jerry Tall', funds => 200, birthday => '1999-12-31' },
    ];

    my @expected_users = ();

    for my $params (@$param_ary) {
        my ($user_id, $ins_err) = $self->{uh}->insert($params);
        ok !defined($ins_err), 'must not return error' or diag $ins_err;
        push @expected_users, superhashof({ %$params, id => $user_id });
    }

    my ($users, $sel_err) = $self->{uh}->select_all();
    ok !defined($sel_err), 'must not return error' or diag $sel_err;
    cmp_deeply($users, \@expected_users, 'users must have same ids');
}

sub test_insert_and_update : Test(5) {
    my ($self) = @_;

    my $params = { 
        name => 'Larry Ball',
        funds => 500,
        birthday => '2001-01-19',
    };

    my ($user_id, $ins_err) = $self->{uh}->insert($params);
    ok !defined($ins_err), 'must not return error' or diag $ins_err;

    my $updates = { name => 'Larry Wall', birthday => '1954-09-27' };

    {
        my ($user, $sel_err) = $self->{uh}->select_one($user_id);
        ok !defined($sel_err), 'must not return error' or diag $sel_err;

        my $upd_err = $self->{uh}->update($user_id, $updates);
        ok !defined($upd_err), 'must not return error' or diag $upd_err;
    }

    {
        my ($user, $sel_err) = $self->{uh}->select_one($user_id);
        ok !defined($sel_err), 'must not return error' or diag $sel_err;
        cmp_deeply $user, superhashof({ %$params, %$updates }), 
            'updates must be applied';
    }
}

sub test_insert_and_remove : Test(5) {
    my ($self) = @_;

    my $params = { 
        name => 'Larry Wall',
        funds => 500,
        birthday => '1954-09-27',
    };

    my ($user_id, $ins_err) = $self->{uh}->insert($params);
    ok !defined($ins_err), 'must not return error' or diag $ins_err;

    my $del_err = $self->{uh}->remove($user_id);
    ok !defined($del_err), 'must not return error' or diag $del_err;
    
    my ($user, $sel_err) = $self->{uh}->select_one($user_id);
    ok !defined($sel_err), 'must not return error' or diag $sel_err;
    ok !defined($user), 'must not return row' or diag "select returned $user";
}

sub _mysql_timeouts {
    'mysql_connect_timeout=20;mysql_write_timeout=20;mysql_read_timeout=20'
}

sub _mysql_server_prepare {
    'mysql_server_prepare=1'
}

sub _migration_files {
    grep { $_ !~ /\-\d/ } glob './migrations/*.sql';
}

sub _revert_migration_files {
    grep { /\-\d/ } glob './migrations/*.sql';
};

sub prepare_db : Test(startup => 4) {
    my ($self) = @_;

    my $db_host = $ENV{DB_HOST};
    my $db_port = $ENV{DB_PORT};
    my $db_user = $ENV{DB_USER};
    my $db_password = $ENV{DB_PASSWORD};
    my $db_name = $ENV{DB_NAME};

    ok List::Util::all { defined $_ }
        ($db_host, $db_port, $db_user, $db_password, $db_name) 
        or BAIL_OUT 'db creds are not set';

    my $dsn = "DBI:mysql:database=$db_name;host=$db_host;port=$db_port";
    $dsn .= ';' . _mysql_timeouts if _mysql_timeouts;
    $dsn .= ';' . _mysql_server_prepare if _mysql_server_prepare;
    my $dbh_opts = {
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 0,
    };

    my ($conn_cb, $err) = Model::get_connect_cb(
        dsn => $dsn,
        user => $db_user,
        password => $db_password,
        opts => $dbh_opts,
    );
    ok !defined $err or BAIL_OUT $err;
    ok defined $conn_cb or BAIL_OUT 'no conn_cb';

    my ($dbh, $conn_err) = $conn_cb->();
    ok !defined $conn_err or BAIL_OUT $conn_err;

    for my $file (_migration_files) {
        my $sql = do {
            open(my $fh, '<', $file) or die $!;
            local $/;
            <$fh>
        };

        $dbh->do($sql);
    }

    $self->{conn_cb} = $conn_cb;
    $self->{uh} = Model::User->new($conn_cb)
}

sub clear_tables : Test(teardown => 2) {
    my ($self) = @_;

    my ($dbh, $err) = $self->{conn_cb}->();
    ok !defined $err or BAIL_OUT $err;

    $dbh->do('delete from `user`;');
}

sub clear_db : Test(shutdown => 1) {
    my ($self) = @_;

    my ($dbh, $err) = $self->{conn_cb}->();
    ok !defined $err or BAIL_OUT $err;

    for my $file (_revert_migration_files) {
        my $sql = do {
            open(my $fh, '<', $file) or die $!;
            local $/;
            <$fh>
        };

        $dbh->do($sql);
    }
}

1;