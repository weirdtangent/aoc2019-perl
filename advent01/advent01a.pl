#!/usr/bin/perl -Tw

my $total = 0 ;
while (my $mass = <STDIN>) {
  chomp $mass;
  my $fuel = int($mass / 3) - 2;
  $total += $fuel;
}

print "$total fuel needed\n";
