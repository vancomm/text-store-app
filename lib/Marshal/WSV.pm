package Marshal::WSV;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/marshal_fields unmarshal_fields/;

sub quote_value {
    $_ = shift;

    return '-' unless defined $_;

    my $quoted = $_;
    $quoted =~ s/\"/\"\"/gm;
    $quoted =~ s/\n/\"\/\"/gm;
    $quoted = qq/"$quoted"/ if /(\s|\n|\"|\#|^$|^-$)/x;
    return $quoted;
}

sub marshal_fields {
    return join ' ', map { quote_value $_ } @_;
}

sub unquote_value {
    $_ = shift;

    return if $_ eq '-';
    return $_ unless /\"/;

    my $value = $_;
    $value =~ s/\"\"/\"/gm;
    $value =~ s/\"\/\"/\n/gm;
    $value =~ s/(^"|"$)//gm;
    return $value;
}

sub unmarshal_fields {
    my $line = shift;

    return map { scalar unquote_value($_) } split(' ', $line); # BUG: cannot split by space
}

1;