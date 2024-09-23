package Model::User;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw//;


my %datetime_fmt = (
    '%Y-%m-%d' => [qw/birthday/],
    '%Y-%m-%dT%H:%M:%S' => [qw/created_at updated_at deleted_at/],
);

sub lookup_fmt {
    my ($field) = @_;

    return List::Util::first {
        List::Util::any { $_ eq $field } @{$datetime_fmt{$_}}
    } keys %datetime_fmt;
}

sub new {
    my ($class, $conn_cb) = @_;

    my $self = {
        conn_cb => $conn_cb,
    };

    bless($self, $class);

    return $self;
}

sub select_all {
    my $self = shift;

    my ($dbh, $err) = $self->{conn_cb}->();

    return (undef, $err) if defined($err);

    my $sth = $dbh->prepare_cached(
        'select * from `user` where deleted_at is null',
    );
    $sth->execute();
    my $rows = $sth->fetchall_arrayref({});
    $sth->finish();

    return ($rows, undef);
}

sub select_one {
    my ($self, $id) = @_;

    my ($dbh, $err) = $self->{conn_cb}->();

    return (undef, $err) if defined($err);

    my $sth = $dbh->prepare_cached(
        'select * from `user` where deleted_at is null and id = ?',
    );
    $sth->execute($id);
    my $row = $sth->fetchrow_hashref();
    $sth->finish();

    return ($row, undef);
}

my @insertable_keys = qw/name birthday funds/;

sub insert {
    my ($self, $params) = @_;

    my ($dbh, $err) = $self->{conn_cb}->();

    return (undef, $err) if defined($err);

    my $sql = 'insert into `user` (';
    my @placeholders = ();
    my @values = ();

    for my $key (@insertable_keys) {
        next unless exists $params->{$key};
        push @placeholders, $key;
        push @values, $params->{$key};
    }

    return (undef, 'no data to insert') unless @placeholders;

    $sql .= join ', ', @placeholders;
    $sql .= ') values (';
    $sql .= join ', ', ('?') x @placeholders;
    $sql .= ')';

    my $sth = $dbh->prepare_cached($sql);

    eval {
        $sth->execute(@values);
        $sth->finish();
        $dbh->commit();
    };
    if ($@) {
        eval { $dbh->rollback() };
        die 'unable to insert user: ' . $@;
    }

    return ($sth->{mysql_insertid}, undef);
}

my @updateable_keys = qw/name birthday funds/;

sub update {
    my ($self, $id, $updates) = @_;
    
    my ($dbh, $err) = $self->{conn_cb}->();

    return $err if defined($err);

    my $sql = 'update `user` set ';
    my @placeholders = ();
    my @values = ();

    for my $key (@updateable_keys) {
        next unless exists $updates->{$key};
        push @placeholders, $key . ' = ?';
        push @values, $updates->{$key};
    }

    return 'nothing to update' unless @placeholders;

    $sql .= join ', ', @placeholders;

    $sql .= ' where id = ?';
    push @values, $id;

    my $sth = $dbh->prepare_cached($sql);

    eval {
        $sth->execute(@values);
        $sth->finish();
        $dbh->commit();
    };
    if ($@) {
        eval { $dbh->rollback() };
        die 'unable to update user: ' . $@;
    }

    return;
}

sub remove {
    my ($self, $id) = @_;

    my ($dbh, $err) = $self->{conn_cb}->();

    return $err if defined($err);

    my $sth = $dbh->prepare_cached(
        'update `user` set deleted_at = current_timestamp where id = ?',
    );

    eval {
        $sth->execute($id);
        $sth->finish();
        $dbh->commit();
    };
    if ($@) {
        eval { $dbh->rollback() };
        die 'unable to delete user: ' . $@;
    }

    return;
}

sub sleep {
    my ($self, $id) = @_;

    my ($dbh, $err) = $self->{conn_cb}->();

    return $err if defined($err);

    eval {
        $dbh->do('select sleep(400);');
    };
    if ($@) {
        return (undef, 'sleep failed: ' . $@);
    }
}

1;