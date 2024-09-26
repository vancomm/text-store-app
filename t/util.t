use strict;
use warnings;

use Test::Most tests => 4;
use File::Temp;

use FindBin qw//;
use lib "$FindBin::Bin/../lib";
use Project::Util qw//;

subtest now_iso => sub {
    plan tests => 1;

    like Project::Util::now_iso(), qr/\d{4}\-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, 
        'now_iso() must match YYYY-MM-DDTHH:MM:SS';
};

subtest count_lines => sub {
    my @cases = qw/0 1 2 10 42 255/;
    
    plan tests => scalar @cases;

    for my $count (@cases) {
        my $fh = File::Temp->new();
        my $filename = $fh->filename();
        print {$fh} "hello world\n" for (1..$count);
        $fh->close();

        my $actual = Project::Util::count_lines($filename);

        is $actual, $count, "have $actual, want $count";
    }
};

subtest try_parse_timestamp => sub {
    my @cases = ( # string, format, 0 for no error or 1 for error
        [qw/2001-01-01 %Y-%m-%d 0/],
        [qw/2001-13-01 %Y-%m-%d 1/],
    );

    plan tests => scalar @cases;

    for (@cases) {
        my ($string, $format, $errs) = @$_;
        my ($date, $err) = Project::Util::try_parse_timestamp($string, $format);
        
        is !defined($err), !$errs, 
            $string . ($errs ? ' should not' : ' should') . ' match ' . $format;
    }

};

subtest normalize_timestamp => sub {
    my @cases = (
        [qw/2001-01-01 %Y-%m-%dT%H:%M:%S 2001-01-01T00:00:00 0/],
        [qw/2001-13-01 %Y-%m-%dT%H:%M:%S NULL 1/],
    );

    plan tests => scalar @cases;

    for (@cases) {
        my ($string, $format, $expected, $errs) = @$_;
        my ($actual, $err) = Project::Util::normalize_timestamp($string, $format);

        if ($errs) {
            ok defined($err), 'must return error';
        } else {
            is $actual, $expected, "have $actual, want $expected";
        }
    }
};

done_testing;
