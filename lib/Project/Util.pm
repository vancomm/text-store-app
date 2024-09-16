package Project::Util;

use strict;
use warnings;

use Time::Piece qw//;
use DDP;

use Exporter 'import';
our @EXPORT_OK = qw/insert get get_all remove update/;

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

sub try_parse_ts {
    my ($string, $format) = @_;

    my $date;
    eval {
        $date = Time::Piece->strptime($string, $format);
    };
    if ($@) {
        return (undef, 'invalid timestamp');
    }
    return ($date, undef);
}

1;