package Entity::User;

use strict;
use warnings;
use feature 'say';

use File::Touch 0.12 qw//;
use MIME::Base64 qw//;
use Time::Piece qw//;
use Try::Tiny qw/try catch/;

use Marshal::WSV qw//;

use Exporter 'import';
our @EXPORT_OK = qw/insert get remove update get_conf/;

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

sub now_iso {
    my $text = Time::Piece::gmtime->strftime($conf{audit_ts_fmt});
    return $text;
}

sub count_lines {
    my ($filename) = @_;

    my $lines = 0;
    open(my $fh, '<', $filename) or die $!;
    while (<$fh>) {
        $lines++;
    }
    close $fh;
    return $lines;
}

sub try_parse_ts {
    my ($date, $fmt) = @_;

    try {
        return (Time::Piece->strptime($date, $fmt), undef);
    } catch {
        return (undef, 'invalid timestamp');
    };
}

sub new {
    my ($args) = @_;

    foreach my $key (@data_keys) {
        return (undef, "user $key must be defined") unless defined($args->{$key});
    }

    my $user = {
        name => $args->{name},
        funds => $args->{funds},
        birthday => $args->{birthday},
        created_at => now_iso(),
        updated_at => now_iso(),
        deleted_at => undef,
    };

    my $err = validate_user_fields($user);
    return (undef, $err) if defined $err;

    return ($user, undef);
}

sub validate_user_shape {
    my %user = %{$_[0]};

    foreach (@all_keys) {
        return "user must have a $_" unless exists($user{$_});
    }
    return;
}

sub validate_user_fields {
    my %user = %{$_[0]};

    my $funds = $user{funds};
    if (defined($funds)) {
        return 'funds: must be a number' unless $funds and $funds =~ /^-?\d+(.\d+)?$/;
    }

    my $birthday = $user{birthday};
    if (defined($birthday)) {
        my (undef, $err) = try_parse_ts $birthday, $conf{birthday_fmt};
        return 'birthday: ' . $err if defined $err;
    }

    foreach (@audit_ts_keys) {
        my $field = $user{$_};
        if (defined $field) {
            my (undef, $err) = try_parse_ts($field, $conf{audit_ts_fmt});
            return $_ . ': ' . $err if defined $err;
        }
    }

    return;
}

sub unmarshal_user_wsv {
    my $text = shift;

    my %user;
    my @fields = Marshal::WSV::unmarshal_fields $text;
    @user{@sorted_keys} = @fields;

    my $err = validate_user_shape(\%user);
    return (undef, $err) if defined $err;        

    return (\%user, undef);
}

sub marshal_user_wsv {
    my %user = %{$_[0]};

    my @sorted_fields = map { $user{$_} } sort keys %user;
    return Marshal::WSV::marshal_fields(@sorted_fields) . "\n";
}

sub insert {
    my ($filename, $args) = @_;

    my ($user_ref, $err) = new($args);

    return (undef, $err) if $err;

    my %user = %{$user_ref};

    foreach (@data_keys) {
        return (undef, "user $_ is required") unless exists($user{$_});
    }

    File::Touch::touch($filename);

    open(my $fh, '>>', $filename) or die $!;
    print $fh marshal_user_wsv($user_ref);
    close $fh;

    my $id = count_lines $filename;

    return ($id, undef);
}

sub get {
    my ($filename, $id) = @_;

    open(my $fh, '<', $filename) or die $!;
    my $text;
    while (<$fh>) {
        $text = $_ if $. == $id;
    }
    close $fh;

    return (undef, 'not found') unless defined $text;

    my ($user, $err) = unmarshal_user_wsv $text;
    return (undef, 'database file corrupt') if defined $err;

    return (undef, 'not found') if defined $user->{deleted_at};

    return ($user, undef);
}

sub get_all {
    my ($filename) = @_;

    my @users = ();

    open(my $fh, '<', $filename) or die $!;
    while (<$fh>) {
        my ($user, $err) = unmarshal_user_wsv $_;
        return (undef, 'database file corrupt') if defined $err;
        push(@users, [$., $user]) unless defined $user->{deleted_at};
    }
    close $fh;

    return \@users;
}

sub update {
    my ($filename, $id, $updates) = @_;

    my $err = validate_user_fields $updates;
    return $err if defined $err;

    my @lines = ();
    open(my $read_fh, '<', $filename) or die $!;
    while (<$read_fh>) {
        unless ($. == $id) {
            push(@lines, $_);
            next;
        }
        my ($user, $err) = unmarshal_user_wsv($_);
        return (undef, 'database file corrupt') if defined $err;

        return if defined $user->{deleted_at};

        foreach my $key (@updateable_keys) {
            $user->{$key} = $updates->{$key} if exists($updates->{$key});
        }
        push(@lines, marshal_user_wsv($user));
    }
    close $read_fh;

    open(my $write_fh, '>', $filename) or die $!;
    for (@lines) {
        print $write_fh $_;
    }
    close $write_fh;

    return;
}

sub remove {
    my ($filename, $id) = @_;

    return update($filename, $id, { deleted_at => now_iso() });
}

1;
