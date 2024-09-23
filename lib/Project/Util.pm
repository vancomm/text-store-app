package Project::Util;

use strict;
use warnings;

use Time::Piece qw//;

sub now_iso {
    my $text = Time::Piece::gmtime->strftime('%Y-%m-%dT%H:%M:%S');
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

sub try_parse_timestamp {
    my ($string, $format) = @_;

    my $date;
    eval {
        $date = Time::Piece->strptime($string, $format);
    };
    if ($@) {
        return (undef, $@);
    }

    return ($date, undef);
}

sub normalize_timestamp {
    my ($timestamp_string, $format) = @_;

    my ($date, $err) = try_parse_timestamp($timestamp_string, $format);

    return (undef, $err) if defined $err;

    my $normalized = $date->strftime($format);

    return ($normalized, undef);
}

1;