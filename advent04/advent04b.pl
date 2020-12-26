#!/usr/bin/perl

use v5.26;
use warnings;
use strict;

my $low = 272091;
my $high = 815432;

my $count = 0;

TEST: for my $test ($low..$high) {
  my @digits = split '', $test;
  for my $num (0..4) {
    next TEST if $digits[$num + 1] < $digits[$num];
  }
  my $stillgood = 0;
  while ($test =~ /(\d)\1+/g) {
    my $repeat = $1;
    $test =~ /($repeat+)/;
    $stillgood = 1 if length($1) == 2;
  }
  next unless $stillgood;
  $count++;
}

print "$count possible passwords\n";
