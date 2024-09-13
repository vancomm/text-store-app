#!/usr/bin/env perl

use strict;
use warnings;

use File::Touch 0.12 qw//;
use MIME::Base64 qw//;
use Time::Piece qw//;

package TextStore::User;

use Exporter 'import';
our @EXPORT_OK = qw/insert get remove update/;

my %conf = (
    birthday_fmt => '%Y-%m-%d',
);

sub next_id {
    my $filename = shift;

    open(my $fh, '<', $filename) or die $!;
    my $last_line = '0';
    while (<$fh>) {
        chomp;
        if (/\S/) {
            $last_line = $_;
        }
    }
    close $fh;
    my ($last_id) = split ' ', $last_line;

    die "database file $filename corrupt" unless $last_id =~ /^\d+$/;

    return $last_id + 1;
}

sub validate_user_fields {
    my $user = shift;

    my $height = $user->{height};
    if (defined($height)) {
        return (undef, 'height must be a positive number') unless $height and $height =~ /^\d+(.\d+)?$/;
    }
    my $birthday = $user->{birthday};
    if (defined($birthday)) {
        eval {
            Time::Piece->strptime($birthday, $conf{birthday_fmt});
        } or do {
            return (undef, 'invalid birthday format');
        };
    }

    return ($user, undef);
}

sub validate_user {
    my $user = shift;

    return (undef, 'user must have a name') unless exists($user->{name});
    return (undef, 'user must have a height') unless exists($user->{height});
    return (undef, 'user must have a birthday') unless exists($user->{birthday});

    return validate_user_fields $user;
}

sub unmarshal_user {
    my $text = shift;

    my @parts = split ' ', $text;

    return (undef, 'malformed record') unless $#parts + 1 == 3;
    
    my ($name_64, $height, $birthday) = split ' ', $text;
    my $name = MIME::Base64::decode $name_64;
    my $user = {name => $name, height => $height, birthday => $birthday};

    return $user;
}

sub marshal_user {
    my $user = shift;

    my $name = $user->{name};
    my $height = $user->{height};
    my $birthday = $user->{birthday};
    my $name_64 = MIME::Base64::encode $name, '';

    return join ' ', $name_64, $height, $birthday, '\n';
}

sub insert {
    my ($filename, $user_params) = @_;

    my ($user, $err) = validate_user $user_params;
    return undef, $err if defined $err;

    File::Touch::touch($filename);
    my $id = next_id $filename;
    my $record = marshal_user $user;
    open(my $fh, '>>', $filename) or die $!;
    print $fh $id . ' ' . $record;
    close $fh;

    return ($id, undef);
}

sub get {
    my ($filename, $id) = @_;

    open(my $fh, '<', $filename) or die $!;
    my $record;
    while (<$fh>) {
        $record = $_ if /^$id /;
    }
    close $fh;

    return (undef, 'not found') unless defined $record;

    return unmarshal_user $record =~ s/^$id //r;
}

# mark for deletion with deleted_at field
sub remove {
    my ($filename, $id) = @_;

    open(my $read_fh, '<', $filename) or die $!;
    my @lines = <$read_fh>;
    close $read_fh;

    open(my $write_fh, '>', $filename) or die $!;
    for (@lines) {
        print $write_fh $_ unless /^$id /;
    }
    close $write_fh;
}

sub update {
    my ($filename, $id, $updates) = @_;

    my ($updated_user, $err) = validate_user_fields $updates;
    return $err if defined $err;

    my @lines = ();
    open(my $read_fh, '<', $filename) or die $!;
    while (<$read_fh>) {
        unless (/^$id /) {
            push @lines, $_;
            next;
        }
        my ($user, $err) = unmarshal_user $_ =~ s/$id //r;
        return $err if defined $err;
        $user->{name} = $updated_user->{name} if exists($updated_user->{name});
        $user->{height} = $updated_user->{height} if exists($updated_user->{height});
        $user->{birthday} = $updated_user->{birthday} if exists($updated_user->{birthday});       
        push @lines, $id . ' ' . marshal_user $user;
    }
    close $read_fh;

    open(my $write_fh, '>', $filename) or die $!;
    for (@lines) {
        print $write_fh $_;
    }
    close $write_fh;

    return undef;
}

1;
