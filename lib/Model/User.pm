package Model::User;

use strict;
use warnings;

use List::Util qw//;
use File::Touch 0.12 qw//;

use Project::Util;

use Exporter 'import';
our @EXPORT_OK = qw/lookup_fmt new update/;

sub _prototype {
    return {
        name => undef,
        funds => undef,
        birthday => undef,
        created_at => Project::Util::now_iso(),
        updated_at => Project::Util::now_iso(),
        deleted_at => undef,
    }
};

my @all_keys = keys %{ _prototype() };

my @optional_keys = qw/deleted_at/;
my @required_keys = do {
    my %excl = map { $_ => 1 } @optional_keys;
    grep { not $excl{$_} } @all_keys;
};

my @immutable_keys = qw/created_at/;
my @updateable_keys = do {
    my %excl = map { $_ => 1 } @immutable_keys;
    grep { not $excl{$_} } @all_keys;
};

my %datetime_fmt = (
    '%Y-%m-%d' => [qw/birthday/],
    '%Y-%m-%dT%H:%M:%S' => [qw/created_at updated_at deleted_at/],
);

sub lookup_fmt {
    my $field = shift;

    return List::Util::first {
        List::Util::any { $_ eq $field } @{$datetime_fmt{$_}}
    } keys %datetime_fmt;
}

sub new {
    my ($class, $args) = @_;

    my $self = _prototype();

    foreach (@all_keys) {
        $self->{$_} = $args->{$_} if defined($args->{$_});
    }

    bless $self, $class;

    my $err = $self->_validate();
    return (undef, $err) if defined $err;

    return ($self, undef);
}

sub update {
    my ($self, $updates) = @_;

    foreach my $key (@updateable_keys) {
        $self->{$key} = $updates->{$key} if exists($updates->{$key});
    }

    return $self->_validate();
}

sub _validate {
    my $self = shift;

    foreach my $key (@required_keys) {
        return "user field $key is required" unless defined($self->{$key});
    }

    my $funds = $self->{funds};
    if (defined($funds)) {
        return 'funds: must be a number'
            unless $funds and $funds =~ /^-?\d+(.\d+)?$/;
    }

    my $err = $self->_normalize_timestamps();
    return $err if defined $err;

    return;
}

sub _normalize_timestamps {
    my $self = shift;

    while (my ($format, $fields) = each %datetime_fmt) {
        foreach my $field (@{$fields}) {
            next unless defined($self->{$field});

            my $value = $self->{$field};
            my ($normalized, $err) = Project::Util::normalize_timestamp(
                $value, $format,
            );

            return qq/field $field => "$value" does not match format "$format"/
                if defined($err);

            unless ($value eq $normalized) {
                $self->{$field} = $normalized;
            }
        }
    }

    return;
}

1;
