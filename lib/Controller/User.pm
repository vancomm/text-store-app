package Controller::User;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/new create find get_all update remove/;

sub new {
    my ($class, $store) = @_;

    my $self = {
        store => $store,
    };

    bless($self, $class);

    return $self;
}

sub create {
    my ($self, $params) = @_;

    return $self->{store}->insert($params);
}

sub find {
    my ($self, $id) = @_;

    return $self->{store}->select_one($id);
}

sub get_all {
    my ($self) = @_;

    return $self->{store}->select_all();
}

sub update {
    my ($self, $id, $updates) = @_;

    return $self->{store}->update($id, $updates);
}

sub remove {
    my ($self, $id) = @_;

    return $self->{store}->remove($id);
}

1;