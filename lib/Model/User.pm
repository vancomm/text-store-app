package Model::User;

use strict;
use warnings;
use feature 'say';

use JSON qw//;
use File::Touch 0.12 qw//;
use MIME::Base64 qw//;
use Time::Piece qw//;
use DDP;

use Project::Util;

use Exporter 'import';
our @EXPORT_OK = qw/new get_conf apply_update check_required_keys unmarshal_json marshal_json/;

my @data_keys = qw/name funds birthday/;
my @audit_ts_keys = qw/created_at updated_at deleted_at/;

my @updateable_keys = qw/name funds birthday updated_at deleted_at/;

my @all_keys = (@data_keys, @audit_ts_keys);
my @sorted_keys = sort @all_keys;

my %conf = (
    birthday_fmt => '%Y-%m-%d',
    audit_ts_fmt => '%Y-%m-%dT%H:%M:%S',
);

sub get_conf {
    return %conf;
}

sub new {
    my ($class, $args) = @_;

    my $self = {
        name => $args->{name},
        funds => $args->{funds},
        birthday => $args->{birthday},
        created_at => $args->{created_at} || Project::Util::now_iso(),
        updated_at => $args->{updated_at} || Project::Util::now_iso(),
        deleted_at => $args->{deleted_at} || undef,
    };
    bless $self, $class;

    {
        my $err = $self->check_required_keys();
        return (undef, $err) if defined $err;
    }

    {
        my $err = $self->validate_user_fields();
        return (undef, $err) if defined $err;
    }

    return ($self, undef);
}

sub check_required_keys {
    my $self = shift;

    foreach (@data_keys) {
        return "user $_ is required" unless exists($self->{$_});
    }

    return;
}

sub apply_updates {
    my ($self, $updates) = @_;

    foreach my $key (@updateable_keys) {
        $self->{$key} = $updates->{$key} if exists($updates->{$key});
    }
    return $self->validate_user_fields();
}

sub validate_user_shape {
    my $self = shift;

    foreach (@all_keys) {
        return "user must have a $_" unless exists($self->{$_});
    }
    return;
}

sub validate_user_fields {
    my $self = shift;

    my $funds = $self->{funds};
    if (defined($funds)) {
        return 'funds: must be a number' unless $funds and $funds =~ /^-?\d+(.\d+)?$/;
    }

    my $birthday = $self->{birthday};

    if (defined($birthday)) {
        my ($date, $err) = Project::Util::try_parse_ts($birthday, $conf{birthday_fmt});
        return 'birthday: ' . $err if defined $err;
        my $formatted = $date->strftime($conf{birthday_fmt});
        if ($formatted ne $birthday) {
            $self->{birthday} = $formatted;
        }
    }

    foreach (@audit_ts_keys) {
        my $field = $self->{$_};
        if (defined $field) {
            my ($date, $err) = Project::Util::try_parse_ts($field, $conf{audit_ts_fmt});
            return $_ . ': ' . $err if defined $err;
            my $formatted = $date->strftime($conf{audit_ts_fmt});
            if ($formatted ne $field) {
                $self->{$_} = $formatted;
            }
        }
    }

    return;
}

sub unmarshal_json {
    my ($class, $text) = @_;

    my ($user, $err) = new $class, JSON::decode_json($text);
    return ($user, $err);
}

sub marshal_json {
    my $self = shift;

    my $text = JSON::encode_json({ %{ $self } });
    return $text;
}

1;
