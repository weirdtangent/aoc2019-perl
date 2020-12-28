#!/usr/bin/perl

use v5.26;
use warnings;
use strict;

use List::Util qw/max/;
use Math::Trig;
use POSIX qw/round/;

our @space;
our $max_row = 0;
our $max_col = 0;

# our space symbols
our $asteroid = '#';
our $empty_space = '.';
our $colored_station = "\033[32;1m❉\033[0m";
our $colored_asteroid = "\033[35;1m☀︎\033[0m";

my $total_asteroids = 0;

my $station_row = 19;
my $station_col = 22;

while (my $line = <DATA>) {
  chomp $line;
  if ($line eq '') {
    last;
  }
  else {
    $total_asteroids += () = $line =~ /$asteroid/g;
    @{$space[$max_row]} = split '', $line;
    $max_col = max ($max_col, scalar(@{$space[$max_row]})-1);
    $max_row++;
  }
}
$max_row--; # remove that final ++ after last line


print "\033[2J\033[1;0f";
print "Space is $max_row x $max_col with $total_asteroids asteroids\n";

# so much more fun to see the VERY LAST one blasted ($total_asteroids-1)
# but the puzzel calls for the 200th asteroid to be blasted!
start_blasting($station_row, $station_col, 200);

# color the asteriods we can see (that aren't blocked)
sub mark_visible {
  my ($row, $col) = @_;

  $space[$row][$col] = $colored_station;
  my $count = 0;
  for my $check_row (0..$max_row) {
    for my $check_col (0..$max_col) {
      next if $check_row == $row && $check_col == $col;
      next if $space[$check_row][$check_col] eq $empty_space; # only care if this is an asteroid to possibly see 
      $space[$check_row][$check_col] = $colored_asteroid if can_see($row,$col,$check_row,$check_col);
    }
  }
  return $count;
}

sub can_see {
  my ($row1, $col1, $row2, $col2) = @_;

  my $move_row = $row2 - $row1;
  my $move_col = $col2 - $col1;
  my $steps = max (abs($move_col), abs($move_row));
  my $row_step = $move_row / $steps;
  my $col_step = $move_col / $steps;

  for my $step (1..$steps-1) {
    $row1 += $row_step;
    $col1 += $col_step;
    if ($col1 =~ /^\d+$/ && $row1 =~ /^\d+$/) {
      # ok, make SURE our numbers that LOOK like ints ARE ints
      $row1 = round($row1);
      $col1 = round($col1);
      return 0 if $space[$row1][$col1] ne $empty_space;
    }
  }
  return 1;
}

# blast any VISIBLE asteroid starting at 90° and moving clockwise
# if we blast them all, clear out the rubble, recalc VISIBLE, and continue
sub start_blasting {
  my ($row, $col, $stop_at) = @_;

  my $count = 0;
  while ($count < $stop_at) {
    my %degree;
   
    # mark which asteroids we can see, so we know which ones we can hit!
    mark_visible($station_row,$station_col);
    show_space();

    # set degree reckoning for every "visible" asteroid
    for my $look_row (0..$max_row) {
      for my $look_col (0..$max_col) {
        next unless $space[$look_row][$look_col] eq $colored_asteroid;
        my $dx = $look_col - $col;
        my $dy = $look_row - $row;
        # atan2 of the deltas, converted to degrees, gives back an angle +180 .. -180 from our starting point
        my $radians = atan2($dy, $dx);
        my $degrees = sprintf("%.5f", $radians * (180 / pi()));
        # save the row,col position under the angle we use to get to it
        $degree{$degrees} = sprintf "%2d,%2d", $look_row, $look_col;
      }
    }

    # blast from 90° down to 0° down to -180°
    for my $key (sort { $a <=> $b } keys %degree) {
      next if $key < -90;
      print "Blast $degree{$key}\n";
      my ($blast_row, $blast_col) = split ',', $degree{$key};
      $count++;
      $space[$blast_row][$blast_col] = $empty_space;
      show_space();
      die "\nJust blasted #$stop_at, at $blast_row,$blast_col (".($blast_col * 100 + $blast_row).")\n" if $count == $stop_at;
    }
    # blast from 180° down to 90°
    for my $key (sort { $a <=> $b } keys %degree) {
      last if $key >= -90;
      print "Blast $degree{$key}\n";
      my ($blast_row, $blast_col) = split ',', $degree{$key};
      $count++;
      $space[$blast_row][$blast_col] = $empty_space;
      show_space();
      die "\nJust blasted #$stop_at, at $blast_row,$blast_col (".($blast_col * 100 + $blast_row).")\n" if $count == $stop_at;
    }
  }
}

sub show_space {
  print "\033[3;0f";
  for my $row (0..$max_row) {
    print join(' ', @{$space[$row]})."\n";
  }
}


__DATA__
###..#.##.####.##..###.#.#..
#..#..###..#.......####.....
#.###.#.##..###.##..#.###.#.
..#.##..##...#.#.###.##.####
.#.##..####...####.###.##...
##...###.#.##.##..###..#..#.
.##..###...#....###.....##.#
#..##...#..#.##..####.....#.
.#..#.######.#..#..####....#
#.##.##......#..#..####.##..
##...#....#.#.##.#..#...##.#
##.####.###...#.##........##
......##.....#.###.##.#.#..#
.###..#####.#..#...#...#.###
..##.###..##.#.##.#.##......
......##.#.#....#..##.#.####
...##..#.#.#.....##.###...##
.#.#..#.#....##..##.#..#.#..
...#..###..##.####.#...#..##
#.#......#.#..##..#...#.#..#
..#.##.#......#.##...#..#.##
#.##..#....#...#.##..#..#..#
#..#.#.#.##..#..#.#.#...##..
.#...#.........#..#....#.#.#
..####.#..#..##.####.#.##.##
.#.######......##..#.#.##.#.
.#....####....###.#.#.#.####
....####...##.#.#...#..#.##.
