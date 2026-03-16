#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

if ( $#ARGV < 1 ){
    print "Usage: ./bench.pl <BINARY> <N_columns>\n";
    exit;
}

my $BINARY = $ARGV[0];
my $N_cols = $ARGV[1];
my $N_rows = 1000;

print("# dmvm N_cols = $N_cols\n");
print("# N_rows   Mflop/s\n");

while ( $N_rows < 300000 ) {
    my @result =  split(' ',`likwid-pin -c S0:3 ./$BINARY $N_rows $N_cols`);
    print "$N_rows $result[3]\n";
    $N_rows = int($N_rows * 1.1);
}
