#!/usr/bin/perl -Tw

my $total = 0 ;
while (my $mass = <STDIN>) {
  chomp $mass;
  my $fuel = int($mass / 3) - 2;
  $total += $fuel;
  $mass = $fuel;
  while ($mass > 0) {
    $mass = int($mass /3) - 2;
    $mass = 0 if $mass < 0;
    $total += $mass;
  }
}

print "including the mass of the fuel, $total fuel needed\n";
