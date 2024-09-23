package Store;

use strict;
use warnings;

use Carp qw/croak/;

sub insert {
    my ($self, $params) = @_;

    croak 'abstract method ' . ref($self) . '::' . (caller(0))[3] . ' invoked';
}

sub select_one {
    my ($self, $id) = @_;

    croak 'abstract method ' . ref($self) . '::' . (caller(0))[3] . ' invoked';
}

sub select_many {
    my ($self, $id) = @_;

    croak 'abstract method ' . ref($self) . '::' . (caller(0))[3] . ' invoked';
}

sub update {
    my ($self, $id, $updates) = @_;

    croak 'abstract method ' . ref($self) . '::' . (caller(0))[3] . ' invoked';
}

sub remove {
    my ($self, $id) = @_;

    croak 'abstract method ' . ref($self) . '::' . (caller(0))[3] . ' invoked';
}

1;