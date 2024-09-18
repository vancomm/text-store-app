package Controller::User;

use strict;
use warnings;

use JSON::XS qw//;

use Model::User;
use Project::Util;

use Exporter 'import';
our @EXPORT_OK = qw/insert get get_all remove update/;

sub unmarshal_json {
    my $text = shift;

    my ($user, $err) = Model::User->new(JSON::XS::decode_json($text));
    return ($user, $err);
}

sub marshal_json {
    my $user = shift;

    my $text = JSON::XS::encode_json({ %{ $user } });
    return $text;
}

sub insert {
    my ($filename, $args) = @_;

    my ($user, $err) = Model::User->new($args);
    return (undef, $err) if $err;

    File::Touch::touch($filename);

    open(my $fh, '>>', $filename) or die $!;
    print $fh marshal_json($user) . "\n";
    close $fh;

    my $id = Project::Util::count_lines $filename;

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

    my ($user, $err) = unmarshal_json($text);

    return (undef, 'unable to unmarshal database file: ' . $err)
        if defined $err;

    return (undef, 'not found') if defined $user->{deleted_at};

    return ($user, undef);
}

sub get_all {
    my ($filename) = @_;

    my @users = ();

    open(my $fh, '<', $filename) or die $!;
    while (<$fh>) {
        my ($user, $err) = unmarshal_json($_);

        return (undef, 'unable to unmarshal database file: ' . $err)
            if defined $err;

        push(@users, [$., $user]) unless defined $user->{deleted_at};
    }
    close $fh;

    return (\@users, undef);
}

sub update {
    my ($filename, $id, $updates) = @_;

    my @lines = ();
    open(my $read_fh, '<', $filename) or die $!;
    while (<$read_fh>) {
        unless ($. == $id) {
            push(@lines, $_);
            next;
        }

        my ($user, $err) = unmarshal_json($_);

        return (undef, 'database file corrupt') if defined $err;

        return if defined $user->{deleted_at};

        {
            my $err = $user->update($updates);
            return (undef, $err) if defined $err;
        }

        push(@lines, marshal_json($user) . "\n");
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

    return update($filename, $id, { deleted_at => Project::Util::now_iso() });
}

1;