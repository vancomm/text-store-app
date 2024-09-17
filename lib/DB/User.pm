package DB::User;

use strict;
use warnings;

use Model::User;

use Exporter 'import';
our @EXPORT_OK = qw/new select_all/;

sub new {
    my ($class, $dbh) = @_;

    my $self = {
        dbh => $dbh,
    };

    bless $self, $class;

    return $self;
}

sub select_all {
    my $self = shift;
    
    my $sth = $self->{dbh}->prepare_cached(
        'SELECT * FROM `user` WHERE deleted_at IS NULL',
    );
    $sth->execute();
    my $rows = $sth->fetchall_arrayref({});
    $sth->finish();

    return $rows;
}

sub select {
    my ($self, $id) = @_;

    my $sth = $self->{dbh}->prepare_cached(
        'SELECT * FROM `user` WHERE deleted_at IS NULL AND id = ?',
    );
    $sth->execute($id);
    my %row = %{ $sth->fetchrow_hashref() };
    $sth->finish();

    return %row;
}

sub insert {
    my ($self, $name, $funds, $birthday) = @_;

    my $sth = $self->{dbh}->prepare_cached(
        'INSERT INTO `user` (name, funds, birthday) VALUES (?, ?, ?)',
    );

    eval {
        $sth->execute($name, $funds, $birthday);
        $sth->finish();
        $self->{dbh}->commit();
    };
    if ($@) {
        eval { $self->{dbh}->rollback() };
        die 'unable to insert user: ' . $@;
    }

    return $sth->{mysql_insertid};
}

# $uh->update($id, { name => $name })
# $uh->update($id, { name => $name, funds => $funds })

sub update {
    my ($self, $id, $updates) = @_;

    eval {
        if (exists $updates->{name}) {
            $self->_update_name_no_commit($id, $updates->{name})
        }
        if (exists $updates->{funds}) {
            $self->_update_funds_no_commit($id, $updates->{funds})
        }
        if (exists $updates->{birthday}) {
            $self->_update_birthday_no_commit($id, $updates->{birthday})
        }
        $self->{dbh}->commit()
    };
    if ($@) {
        eval { $self->{dbh}->rollback() };
        die 'unable to update user: ' . $@;
    }
}

sub _update_name_no_commit {
    my ($self, $id, $name) = @_;

    my $sth = $self->{dbh}->prepare_cached(
        'UPDATE `user` SET name = ? WHERE id = ?',
    );

    eval {
        $sth->execute($name, $id);
        $sth->finish();
    };
    if ($@) {
        eval { $self->{dbh}->rollback() };
        die 'unable to update user: ' . $@;
    }
}

sub _update_funds_no_commit {
    my ($self, $id, $funds) = @_;

    my $sth = $self->{dbh}->prepare_cached(
        'UPDATE `user` SET funds = ? WHERE id = ?',
    );

    eval {
        $sth->execute($funds, $id);
        $sth->finish();
    };
    if ($@) {
        eval { $self->{dbh}->rollback() };
        die 'unable to update user: ' . $@;
    }
}

sub _update_birthday_no_commit {
    my ($self, $id, $birthday) = @_;

    my $sth = $self->{dbh}->prepare_cached(
        'UPDATE `user` SET birthday = ? WHERE id = ?',
    );

    eval {
        $sth->execute($birthday, $id);
        $sth->finish();
    };
    if ($@) {
        eval { $self->{dbh}->rollback() };
        die 'unable to update user: ' . $@;
    }
}

sub remove {
    my ($self, $id) = @_;

    my $sth = $self->{dbh}->prepare_cached(
        'UPDATE `user` SET deleted_at = CURRENT_TIMESTAMP WHERE id = ?',
    );

    eval {
        $sth->execute($id);
        $sth->finish();
        $self->{dbh}->commit();
    };
    if ($@) {
        eval { $self->{dbh}->rollback() };
        die 'unable to delete user: ' . $@;
    }
}

1;