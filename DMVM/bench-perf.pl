#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

if ( $#ARGV < 2 ){
    print "Usage: ./bench.pl <BINARY> <N_columns> <GROUP>\n";
    exit;
}

my $BINARY = $ARGV[0];
my $N_cols = $ARGV[1];
my $group = $ARGV[2];
my $N_rows = 1000;
my $match = $group;

if ($group eq 'MEM'){
    $match = 'Memory';
}

if ($group eq 'L2'){
    $match = 'L2D load';
}

print("# dmvm $N_cols $group\n");

while ( $N_rows < 300000 ) {
    my @output =  split("\n",`likwid-perfctr -C S0:3 -g $group -O -m  ./$BINARY $N_rows $N_cols`);
    my ($iter, $NR, $NC, $count, $perf, $datavolume);

    foreach my $line ( @output ) {
        if ($line =~ /([0-9]+) +([0-9]+) +([0-9]+) +([0-9.]+)/) {
            # printf("%d %d %d %d\n",$1,$2,$3,$4);
            $iter = $1;
            $NR = $2;
            $NC = $3;
            $perf = $4;
        } elsif ($line =~ /^call count/) {
            my @str = split(',',$line);
            $count = $str[1];

        } elsif ($line =~ /^$match data volume/) {
            my @str = split(',',$line);
            $datavolume = $str[1];
        }
    }

    $datavolume = ($datavolume*1.e9)/($iter*$NR*$NC*$count);
    printf("%d %.2f %.2f\n",$N_rows,$perf,$datavolume);
    $N_rows = int($N_rows * 1.1);
}
