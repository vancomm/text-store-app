package Store::Text::User;

use strict;
use warnings;

use JSON::XS qw//;
use List::Util qw//;
use File::Touch qw//;

use Project::Util qw//;

use Exporter 'import';
our @EXPORT_OK = qw/lookup_fmt new insert select_one select_all update remove/;

sub _prototype {
    return {
        name => undef,
        funds => undef,
        birthday => undef,
        created_at => Project::Util::now_iso(),
        updated_at => Project::Util::now_iso(),
        deleted_at => undef,
    }
}

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
    my ($field) = @_;

    return List::Util::first {
        List::Util::any { $_ eq $field } @{$datetime_fmt{$_}}
    } keys %datetime_fmt;
}

sub _normalize_timestamps {
    my ($user) = @_;

    while (my ($format, $fields) = each %datetime_fmt) {
        for my $field (@{$fields}) {
            next unless defined($user->{$field});

            my $value = $user->{$field};
            my ($normalized, $err) = Project::Util::normalize_timestamp(
                $value, $format,
            );

            return qq{field $field => "$value" does not match format "$format"}
                if defined($err);

            unless ($value eq $normalized) {
                $user->{$field} = $normalized;
            }
        }
    }

    return;
}

sub _validate {
    my ($user) = @_;

    for my $key (@required_keys) {
        return "user field $key is required" unless defined($user->{$key});
    }

    my $funds = $user->{funds};
    if (defined($funds)) {
        return 'funds: must be a number'
            unless $funds and $funds =~ /^-?\d+(.\d+)?$/;
    }

    my $err = _normalize_timestamps($user);
    return $err if defined $err;

    return;
}

sub _new_user {
    my ($args) = @_;

    my $user = _prototype();

    for (@all_keys) {
        $user->{$_} = $args->{$_} if defined($args->{$_});
    }

    my $err = _validate($user);
    return (undef, $err) if defined $err;

    return ($user, undef);
}

sub _update {
    my ($user, $updates) = @_;

    for my $key (@updateable_keys) {
        $user->{$key} = $updates->{$key} if exists($updates->{$key});
    }

    return _validate($user);
}

sub _unmarshal_json {
    my ($text) = @_;

    my ($user, $err) = _new_user(JSON::XS::decode_json($text));
    return ($user, $err);
}

sub _marshal_json {
    my ($user) = @_;

    my $text = JSON::XS::encode_json($user);
    return $text;
}

sub new {
    my ($class, $filename) = @_;

    my $self = {
        filename => $filename,
    };

    bless($self, $class);

    return $self;
}

sub _check_file {
    my ($self) = @_;

    die 'users file missing @ ' . $self->{filename} unless -f $self->{filename};
}

sub insert {
    my ($self, $params) = @_;

    my ($user, $err) = _new_user($params);
    return (undef, $err) if $err;

    File::Touch::touch($self->{filename});

    open(my $fh, '>>', $self->{filename}) or die $!;
    print {$fh} _marshal_json($user) . "\n";
    close $fh;

    my $id = Project::Util::count_lines $self->{filename};

    return ($id, undef);
}

sub select_one {
    my ($self, $id) = @_;

    $self->_check_file();

    open(my $fh, '<', $self->{filename}) or die $!;
    my $text;
    while (<$fh>) {
        $text = $_ if $. == $id;
    }
    close $fh;

    return (undef, 'not found') unless defined $text;

    my ($user, $err) = _unmarshal_json($text);

    return (undef, 'unable to unmarshal database file: ' . $err)
        if defined $err;

    $user->{id} = $id;

    return (undef, 'not found') if defined $user->{deleted_at};

    return ($user, undef);
}

sub select_all {
    my ($self) = @_;

    $self->_check_file();

    my @users = ();

    open(my $fh, '<', $self->{filename}) or die $!;
    while (<$fh>) {
        my ($user, $err) = _unmarshal_json($_);

        return (undef, 'unable to unmarshal database file: ' . $err)
            if defined $err;
        
        $user->{id} = $.;

        push(@users, $user) unless defined $user->{deleted_at};
    }
    close $fh;

    return (\@users, undef);
}


sub update {
    my ($self, $id, $updates) = @_;

    $self->_check_file();

    my @lines = ();
    my $target;
    my $err;

    open(my $read_fh, '<', $self->{filename}) or die $!;
    while (<$read_fh>) {
        unless ($. == $id) {
            push(@lines, $_);
            next;
        }

        my ($user, $_err) = _unmarshal_json($_);

        if (defined($_err)) {
            $err = 'database file corrupt';
            last;
        }

        if (defined($user->{deleted_at})) {
            last;
        }

        {
            my $_err = _update($user, $updates);
            if (defined($_err)) {
                $err = $_err;
                last;
            }
        }

        $target = $user;

        push(@lines, _marshal_json($user) . "\n");
    }
    close $read_fh;

    return $err if defined($err);
    return unless defined($target);

    open(my $write_fh, '>', $self->{filename}) or die $!;
    for (@lines) {
        print {$write_fh} $_;
    }
    close $write_fh;

    return;
}

sub remove {
    my ($self, $id) = @_;

    return $self->update($id, { deleted_at => Project::Util::now_iso() });
}
