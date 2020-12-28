#!/usr/bin/perl

use v5.26;
use warnings;
use strict;

use List::Util qw/max/;
use POSIX qw/round/;

our $verbose = 0;

our @space;
our $max_row = 0;
our $max_col = 0;

our $asteroid = '#';
our $empty_space = '.';

my $total_asteroids = 0;

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

print "Space is $max_row x $max_col with $total_asteroids asteroids\n";

my $max_count = 0;
my ($max_count_row, $max_count_col);
for my $row (0..$max_row) {
  for my $col (0..$max_col) {
    next unless $space[$row][$col] eq $asteroid; # have to put monitoring station ON an asteroid
    my $count = count_visible($row,$col);
    if (!$max_count || $count >= $max_count) {
      $max_count = $count;
      $max_count_row = $row;
      $max_count_col = $col;
    }
  }
}

print "Positioned at $max_count_row,$max_count_col, monitoring station could see $max_count asterioids\n\n";
$verbose = 0;
mark_visible($max_count_row,$max_count_col);
show_space();

sub count_visible {
  my ($row, $col) = @_;

  my $count = 0;
  for my $check_row (0..$max_row) {
    for my $check_col (0..$max_col) {
      next if $check_row == $row && $check_col == $col;
      next if $space[$check_row][$check_col] eq $empty_space; # only care if this is an asteroid to possibly see
      $count++ if can_see($row,$col,$check_row,$check_col);
      print "\n" if $verbose;
    }
  }
  return $count;
}

sub mark_visible {
  my ($row, $col) = @_;

  $space[$row][$col] = "\033[32;1m❉\033[0m";
  my $count = 0;
  for my $check_row (0..$max_row) {
    for my $check_col (0..$max_col) {
      next if $check_row == $row && $check_col == $col;
      next if $space[$check_row][$check_col] eq $empty_space; # only care if this is an asteroid to possibly see 
      $space[$check_row][$check_col] = "\033[35;1m☀︎\033[0m" if can_see($row,$col,$check_row,$check_col);
    }
  }
  return $count;
}

sub show_space {
  for my $row (0..$max_row) {
    print join(' ', @{$space[$row]})."\n";
  }
}

sub can_see {
  my ($row1, $col1, $row2, $col2) = @_;

  my $move_row = $row2 - $row1;
  my $move_col = $col2 - $col1;
  my $steps = max (abs($move_col), abs($move_row));
  my $row_step = $move_row / $steps;
  my $col_step = $move_col / $steps;

  printf "Going from $row1,$col1 to $row2,$col2 in $steps steps by %2.5f,%2.5f\n",$row_step,$col_step if $verbose;

  for my $step (1..$steps-1) {
    $row1 += $row_step;
    $col1 += $col_step;
    printf "Checking %2.5f,%2.5f",$row1,$col1 if $verbose;
    if ($col1 =~ /^\d+$/ && $row1 =~ /^\d+$/) {
      # ok, make SURE our numbers that LOOK like ints ARE ints
      $row1 = round($row1);
      $col1 = round($col1);
      print ": ".$space[$row1][$col1] if $verbose;
      if ($space[$row1][$col1] ne $empty_space) {
        print " blocked!\n" if $verbose;
        return 0;
      }
      print " clear!\n" if $verbose;
    }
    else {
      print " not exact grid position\n" if $verbose;
    }
  }
  print "Clear path!\n" if $verbose;
  return 1;
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
