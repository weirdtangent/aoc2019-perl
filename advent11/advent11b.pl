#!/usr/bin/perl

use v5.26;
use warnings;
use strict;

use List::Util qw/min max/;

my $intcode = <DATA>;
chomp $intcode;
my @intcode = split ',', $intcode;

my @grid;
my $dir = 0;
my $x = 500;
my $y = 500;
$grid[$x][$y] = 1;
my ($min_x, $max_x, $min_y, $max_y);

my ($result, $halted, $iptr, $base);
do {
  ($result, $halted, $iptr, $base) = run_intcode(\@intcode, $iptr//0, $base//0, [ $grid[$x][$y]//0 ], 0);
  if (defined $result && !$halted) {
    $grid[$x][$y] = $result;
    ($result, $halted, $iptr, $base) = run_intcode(\@intcode, $iptr//0, $base//0, [ $grid[$x][$y] ], 0);
    if (defined $result && !$halted) {
      $dir-- if $result == 0; $dir = 3 if $dir < 0;
      $dir++ if $result == 1; $dir = 0 if $dir > 3;
      $y++ if $dir == 0;
      $x++ if $dir == 1;
      $y-- if $dir == 2;
      $x-- if $dir == 3;
      $min_x = $min_x ? min $min_x, $x : $x;
      $max_x = $max_x ? max $max_x, $x : $x;
      $min_y = $min_y ? min $min_y, $y : $y;
      $max_y = $max_y ? max $max_y, $y : $y;
    }
  }
} while !$halted;

# apprently it is upside down, print in reverse-row order
for $y (reverse $min_y..$max_y) {
  for $x ($min_x..$max_x) {
    print $grid[$x][$y] ? ' ◼︎ ' : '   ';
  }
  print "\n";
}

exit;


sub run_intcode {
  our ($code, $iptr, $relative_base, $input, $verbose) = @_;

  my $count = 0;
  my $output;

  # if we need the VALUE STORED AT the positional, immediate, or relative place (for GETTING a value)
  sub _get_value {
    my ($mode, $value) = @_;

    return $code->[$value]//0                  if $mode eq '0'; # positional mode
    return $value                              if $mode eq '1'; # immediate mode
    return $code->[$relative_base + $value]//0 if $mode eq '2'; # relative mode
    die "Invalid _get_value : $mode, $value\n";
  }

  # if we need the positional, immediate, or relative POSITION (for STORING a value)
  sub _get_pos {
    my ($mode, $value) = @_;

    return $value                   if $mode eq '0'; # positional mode
    return $relative_base + $value  if $mode eq '2'; # relative mode
    die "Invalid _get_value : $mode, $value\n";
  }

  while ($code->[$iptr] && $code->[$iptr] != 99 && !defined $output) {
    print "Process opcode '".$code->[$iptr]."' at $iptr\n" if $verbose;
    my $command = sprintf("%05d", $code->[$iptr]);
    my ($mode, $opcode) = $command =~ /^(\d\d\d)(\d\d)$/;
    my @param_mode = split '', $mode;

    if ($opcode eq '01') {
      print '  add '._get_value($param_mode[2], $code->[$iptr+1]).' and '._get_value($param_mode[1], $code->[$iptr+2]).' and store in pos:'._get_pos($param_mode[0], $code->[$iptr+3])."\n" if $verbose;
      $code->[_get_pos($param_mode[0], $code->[$iptr+3])] = _get_value($param_mode[2], $code->[$iptr+1]) + _get_value($param_mode[1], $code->[$iptr+2]);
      print '  pos:'.($code->[$iptr+3]).' = '.$code->[$code->[$iptr+3]]."\n" if $verbose;
      $iptr += 4;
    }
    elsif ($opcode eq '02') {
      print '  multiply '._get_value($param_mode[2], $code->[$iptr+1]).' and '._get_value($param_mode[1], $code->[$iptr+2]).' and store in pos:'._get_pos($param_mode[0], $code->[$iptr+3])."\n" if $verbose;
      $code->[_get_pos($param_mode[0], $code->[$iptr+3])] = _get_value($param_mode[2], $code->[$iptr+1]) * _get_value($param_mode[1], $code->[$iptr+2]);
      print '  pos:'.($code->[$iptr+3]).' now = '.$code->[$code->[$iptr+3]]."\n" if $verbose;
      $iptr += 4;
    }
    elsif ($opcode eq '03') {
      print '  store input: '.$input->[0].' into intcode at pos:'._get_pos($param_mode[2], $code->[$iptr+1])."\n" if $verbose;
      $code->[_get_pos($param_mode[2], $code->[$iptr+1])] = shift @$input;
      $iptr += 2;
    }
    elsif ($opcode eq '04') {
      print '  set output to '._get_value($param_mode[2], $code->[$iptr+1])."\n" if $verbose;
      $output = _get_value($param_mode[2], $code->[$iptr+1]);
      $iptr += 2;
    }
    elsif ($opcode eq '05') {
      my $test = _get_value($param_mode[2], $code->[$iptr+1]);
      print '  jump to '._get_value($param_mode[1], $code->[$iptr+2]).' if test ('._get_value($param_mode[2], $code->[$iptr+1]).") is != 0\n" if $verbose;
      $iptr = ($test != 0) ? _get_value($param_mode[1], $code->[$iptr+2]) : $iptr + 3;
    }
    elsif ($opcode eq '06') {
      print '  jump to '._get_value($param_mode[1], $code->[$iptr+2]).' if test ('._get_value($param_mode[2], $code->[$iptr+1]).") is == 0\n" if $verbose;
      my $test = _get_value($param_mode[2], $code->[$iptr+1]);
      $iptr = ($test == 0) ? _get_value($param_mode[1], $code->[$iptr+2]) : $iptr + 3;
    }
    elsif ($opcode eq '07') {
      my $compare1 = _get_value($param_mode[2], $code->[$iptr+1]);
      my $compare2 = _get_value($param_mode[1], $code->[$iptr+2]);
      print "  compare $compare1 and $compare2, set pos:"._get_pos($param_mode[0], $code->[$iptr+3])." to 1 if a<b, else 0\n" if $verbose;
      $code->[_get_pos($param_mode[0], $code->[$iptr+3])] = ($compare1 < $compare2) ? 1 : 0;
      print '  pos:'.($code->[$iptr+3]).' now = '.$code->[$code->[$iptr+3]]."\n" if $verbose;
      $iptr += 4;
    }
    elsif ($opcode eq '08') {
      my $compare1 = _get_value($param_mode[2], $code->[$iptr+1]);
      my $compare2 = _get_value($param_mode[1], $code->[$iptr+2]);
      print "  compare $compare1 and $compare2, set pos:"._get_pos($param_mode[0], $code->[$iptr+3])." to 1 if a==b, else 0\n" if $verbose;
      $code->[_get_pos($param_mode[0], $code->[$iptr+3])] = ($compare1 == $compare2) ? 1 : 0;
      print '  pos:'.($code->[$iptr+3]).' now = '.$code->[$code->[$iptr+3]]."\n" if $verbose;
      $iptr += 4;
    }
    elsif ($opcode eq '09') {
      print '  adjust relative_base by '._get_value($param_mode[2], $code->[$iptr+1]) if $verbose;
      $relative_base += _get_value($param_mode[2], $code->[$iptr+1]);
      print ", value now $relative_base\n" if $verbose;
      $iptr += 2;
    }

    $count++;
  }

  my $halted = ($code->[$iptr] == 99) ? 1 : 0;
  if ($halted) {
    print "HALTING!" if $verbose;
    $iptr = 0;
    $relative_base = 0;
  }
  return ($output, $halted, $iptr, $relative_base);
}

__DATA__
3,8,1005,8,336,1106,0,11,0,0,0,104,1,104,0,3,8,102,-1,8,10,1001,10,1,10,4,10,108,1,8,10,4,10,101,0,8,28,1006,0,36,1,2,5,10,1006,0,57,1006,0,68,3,8,102,-1,8,10,1001,10,1,10,4,10,108,0,8,10,4,10,1002,8,1,63,2,6,20,10,1,106,7,10,2,9,0,10,3,8,102,-1,8,10,101,1,10,10,4,10,108,1,8,10,4,10,102,1,8,97,1006,0,71,3,8,1002,8,-1,10,101,1,10,10,4,10,108,1,8,10,4,10,1002,8,1,122,2,105,20,10,3,8,1002,8,-1,10,1001,10,1,10,4,10,108,0,8,10,4,10,101,0,8,148,2,1101,12,10,1006,0,65,2,1001,19,10,3,8,102,-1,8,10,1001,10,1,10,4,10,108,0,8,10,4,10,101,0,8,181,3,8,1002,8,-1,10,1001,10,1,10,4,10,1008,8,0,10,4,10,1002,8,1,204,2,7,14,10,2,1005,20,10,1006,0,19,3,8,102,-1,8,10,101,1,10,10,4,10,108,1,8,10,4,10,102,1,8,236,1006,0,76,1006,0,28,1,1003,10,10,1006,0,72,3,8,1002,8,-1,10,101,1,10,10,4,10,108,0,8,10,4,10,102,1,8,271,1006,0,70,2,107,20,10,1006,0,81,3,8,1002,8,-1,10,1001,10,1,10,4,10,108,1,8,10,4,10,1002,8,1,303,2,3,11,10,2,9,1,10,2,1107,1,10,101,1,9,9,1007,9,913,10,1005,10,15,99,109,658,104,0,104,1,21101,0,387508441896,1,21102,1,353,0,1106,0,457,21101,0,937151013780,1,21101,0,364,0,1105,1,457,3,10,104,0,104,1,3,10,104,0,104,0,3,10,104,0,104,1,3,10,104,0,104,1,3,10,104,0,104,0,3,10,104,0,104,1,21102,179490040923,1,1,21102,411,1,0,1105,1,457,21101,46211964123,0,1,21102,422,1,0,1106,0,457,3,10,104,0,104,0,3,10,104,0,104,0,21101,838324716308,0,1,21101,0,445,0,1106,0,457,21102,1,868410610452,1,21102,1,456,0,1106,0,457,99,109,2,22101,0,-1,1,21101,40,0,2,21101,0,488,3,21101,478,0,0,1106,0,521,109,-2,2105,1,0,0,1,0,0,1,109,2,3,10,204,-1,1001,483,484,499,4,0,1001,483,1,483,108,4,483,10,1006,10,515,1101,0,0,483,109,-2,2105,1,0,0,109,4,2101,0,-1,520,1207,-3,0,10,1006,10,538,21101,0,0,-3,22102,1,-3,1,21202,-2,1,2,21101,0,1,3,21101,557,0,0,1105,1,562,109,-4,2105,1,0,109,5,1207,-3,1,10,1006,10,585,2207,-4,-2,10,1006,10,585,22101,0,-4,-4,1106,0,653,21201,-4,0,1,21201,-3,-1,2,21202,-2,2,3,21102,604,1,0,1106,0,562,21202,1,1,-4,21101,0,1,-1,2207,-4,-2,10,1006,10,623,21102,0,1,-1,22202,-2,-1,-2,2107,0,-3,10,1006,10,645,21202,-1,1,1,21101,0,645,0,106,0,520,21202,-2,-1,-2,22201,-4,-2,-4,109,-5,2105,1,0
