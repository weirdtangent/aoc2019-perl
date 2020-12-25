#!/usr/bin/perl

use v5.26;
use warnings;
use strict;

my $intcode = <DATA>;
chomp $intcode;
my @intcode = split ',', $intcode;

# BEFORE running the program
$intcode[1] = 12;
$intcode[2] = 2;

my $pos = 0;

while ($pos < scalar(@intcode) -3 && $intcode[$pos] != 99) {
  print "Processing ".$intcode[$pos];
  $intcode[$intcode[$pos+3]] = $intcode[$intcode[$pos+1]] + $intcode[$intcode[$pos+2]] if $intcode[$pos] eq 1;
  $intcode[$intcode[$pos+3]] = $intcode[$intcode[$pos+1]] * $intcode[$intcode[$pos+2]] if $intcode[$pos] eq 2;
  print ": ".($pos+3)." is now ".($intcode[$pos+3])."\n";
  $pos += 4;
}

die "\nProgram halted at opcode 99. Position 0 is ".$intcode[0]."\n";

__DATA__
1,0,0,3,1,1,2,3,1,3,4,3,1,5,0,3,2,13,1,19,1,9,19,23,2,23,13,27,1,27,9,31,2,31,6,35,1,5,35,39,1,10,39,43,2,43,6,47,1,10,47,51,2,6,51,55,1,5,55,59,1,59,9,63,1,13,63,67,2,6,67,71,1,5,71,75,2,6,75,79,2,79,6,83,1,13,83,87,1,9,87,91,1,9,91,95,1,5,95,99,1,5,99,103,2,13,103,107,1,6,107,111,1,9,111,115,2,6,115,119,1,13,119,123,1,123,6,127,1,127,5,131,2,10,131,135,2,135,10,139,1,13,139,143,1,10,143,147,1,2,147,151,1,6,151,0,99,2,14,0,0
