#!/usr/bin/perl

use v5.26;
use warnings;
use strict;

use Math::Utils qw/lcm/;

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

# find out how long it takes for each axis to repeat
my $x_repeats = when_state_repeats(\%moon, 'x');
my $y_repeats = when_state_repeats(\%moon, 'y');
my $z_repeats = when_state_repeats(\%moon, 'z');

# then, the lcm of all 3 is the first time they all repeat together
print "Full system state repeats at lcm of $x_repeats, $y_repeats, and $z_repeats : at ".lcm($x_repeats, $y_repeats, $z_repeats)." steps\n";


sub when_state_repeats {
  my ($moon, $axis) = @_;

  my $history;
  my $steps = 0;
  my $key;

  # apply gravity for just this axis
  while (1) {
    $key = join(' ', map { sprintf("%d:%d", $moon->{$_}->{$axis}//0, $moon->{$_}->{"v$axis"}//0) } (1..4) );
    return $steps if exists $history->{$key};
    $history->{$key} = $steps++;

    for my $first (1..4) {
      for my $second ($first+1..4) {
        gravity_for_an_axis($moon->{$first}, $moon->{$second}, $axis);
      }
      $moon->{$first}->{$axis} += $moon->{$first}->{"v$axis"}//0;
    }
  }
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


__DATA__
<x=0, y=6, z=1>
<x=4, y=4, z=19>
<x=-11, y=1, z=8>
<x=2, y=19, z=15>
