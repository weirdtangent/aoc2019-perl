#!/usr/bin/perl

use v5.26;
use warnings;
use strict;

our $verbose = 0;

my %moon;
my $moonnum = 1;
while (my $line = <DATA>) {
  chomp $line;
  if ($line ne '') {
    if(my ($x, $y, $z) = $line =~ /\<x=([-\d]+), y=([-\d]+), z=([-\d]+)\>/) {
      $moon{$moonnum++} = { x => $x, y => $y, z => $z } ;
    }
    else {
      die "Could not decypher line: $line";
    }
  }
  else {
    last;
  }
}

for my $steps (1..1000) {
  apply_gravity(\%moon);
  apply_velocity(\%moon);
  dump_moons(\%moon, $steps) if $verbose;
}

my $te = calc_total_energy(\%moon);
print "Total energy for the system after 1000 steps is : $te\n";


sub apply_gravity {
  my ($moon) = @_;

  for my $first (1..3) {
    for my $second ($first+1..4) {
      gravity_for_a_pair($moon->{$first},$moon->{$second});
    }
  }
}

sub gravity_for_a_pair {
  my ($first, $second) = @_;

  gravity_for_an_axis($first, $second, 'x');
  gravity_for_an_axis($first, $second, 'y');
  gravity_for_an_axis($first, $second, 'z');
}

sub gravity_for_an_axis {
  my ($first, $second, $axis) = @_;

  if ($first->{$axis} > $second->{$axis}) {
    $first->{'v'.$axis}--;
    $second->{'v'.$axis}++;
  }
  elsif ($first->{$axis} < $second->{$axis}) {
    $first->{'v'.$axis}++;
    $second->{'v'.$axis}--;
  }
}

sub apply_velocity {
  my ($moon) = @_;

  for my $moonnum (keys %$moon) {
    velocity_for_a_moon($moon->{$moonnum});
  }
}

sub velocity_for_a_moon {
  my ($moon) = @_;

  $moon->{x} += $moon->{vx}//0;
  $moon->{y} += $moon->{vy}//0;
  $moon->{z} += $moon->{vz}//0;
}

sub dump_moons {
  my ($moon, $step) = @_;

  print "\nAfter $step steps:\n";
  for my $moonnum (keys %$moon) {
    dump_moon_values($moon->{$moonnum});
  }
}

sub dump_moon_values {
  my ($moon) = @_;

  printf("pos = <x = %d, y = %d, z = %d>, vel = <vx = %d, vy = %d, vz = %d>\n",
    $moon->{x}//0,  $moon->{y}//0,  $moon->{z}//0,
    $moon->{vx}//0, $moon->{vy}//0, $moon->{vz}//0
  );
}

sub calc_total_energy {
  my ($moon) = @_;

  my $total_energy = 0;

  for my $moonnum (keys %$moon) {
    my $potential_energy = abs($moon->{$moonnum}->{x}) + abs($moon->{$moonnum}->{y}) + abs($moon->{$moonnum}->{z});
    my $kinetic_energy = abs($moon->{$moonnum}->{vx}) + abs($moon->{$moonnum}->{vy}) + abs($moon->{$moonnum}->{vz});
    print "Moon $moonnum has $potential_energy potential energy and $kinetic_energy kinetic energy\n" if $verbose;
    $total_energy += ($potential_energy * $kinetic_energy);
  }
  print "\n" if $verbose;
  return $total_energy;
}


__DATA__
<x=0, y=6, z=1>
<x=4, y=4, z=19>
<x=-11, y=1, z=8>
<x=2, y=19, z=15>
