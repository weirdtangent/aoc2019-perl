#!/usr/bin/perl

use v5.26;
use warnings;
use strict;

use Algorithm::Combinatorics qw(permutations);

my $intcode = <DATA>;
chomp $intcode;
my @intcode = split ',', $intcode;

my $max_thrust = 0;
my $remember;
my @phases = (0, 1, 2, 3, 4);
my @perms = permutations(\@phases);
for my $perm (@perms) {
  my $param = 0;
  for my $run (0..4) {
    $param = run_intcode(\@intcode, [ $perm->[$run], $param ]);
  }
  if ($param > $max_thrust) {
    $max_thrust = $param;
    $remember = $perm;
  }
}

print "Phase order [@$remember] gave us a max thrust of $max_thrust\n";

exit;

my $result = run_intcode(\@intcode, [ 0 ]);



sub run_intcode {
  my $code = shift;
  my $input = shift;

  my $count = 0;
  my $output;
  my $iptr = 0;

  while ($iptr < scalar(@$code) && $code->[$iptr] != 99) {
    my $command = sprintf("%05d", $code->[$iptr]);
    my ($mode, $opcode) = $command =~ /^(\d\d\d)(\d\d)$/;
    my @param_mode = split '', sprintf("%03d", $mode);

    # print "Command ".($count + 1).": $command gives me '".join('',@param_mode)."' and '$opcode'\n";

    if ($opcode eq '01') {
      $code->[$code->[$iptr+3]] = ($param_mode[2] eq '0' ? $code->[$code->[$iptr+1]] : $code->[$iptr+1])
                                + ($param_mode[1] eq '0' ? $code->[$code->[$iptr+2]] : $code->[$iptr+2]);
      $iptr += 4;
    }
    elsif ($opcode eq '02') {
      $code->[$code->[$iptr+3]] = ($param_mode[2] eq '0' ? $code->[$code->[$iptr+1]] : $code->[$iptr+1])
                                * ($param_mode[1] eq '0' ? $code->[$code->[$iptr+2]] : $code->[$iptr+2]);
      $iptr += 4;
    }
    elsif ($opcode eq '03') {
      $code->[$code->[$iptr+1]] = shift @$input;
      $iptr += 2;
    }
    elsif ($opcode eq '04') {
      $output = ($param_mode[2] eq '0' ? $code->[$code->[$iptr+1]] : $code->[$iptr+1]);
      die "Failure: output was $output and next opcode was ".$code->[$iptr+2]."\n" unless $output == 0 || $code->[$iptr+2] == 99;
      $iptr += 2;
    }
    elsif ($opcode eq '05') {
      my $test = ($param_mode[2] eq '0' ? $code->[$code->[$iptr+1]] : $code->[$iptr+1]);
      $iptr = ($test != 0) ? ($param_mode[1] eq '0' ? $code->[$code->[$iptr+2]] : $code->[$iptr+2]) : $iptr + 3;
    }
    elsif ($opcode eq '06') {
      my $test = ($param_mode[2] eq '0' ? $code->[$code->[$iptr+1]] : $code->[$iptr+1]);
      $iptr = ($test == 0) ? ($param_mode[1] eq '0' ? $code->[$code->[$iptr+2]] : $code->[$iptr+2]) : $iptr + 3;
    }
    elsif ($opcode eq '07') {
      my $compare1 = ($param_mode[2] eq '0' ? $code->[$code->[$iptr+1]] : $code->[$iptr+1]);
      my $compare2 = ($param_mode[1] eq '0' ? $code->[$code->[$iptr+2]] : $code->[$iptr+2]);
      $code->[$code->[$iptr+3]] = $compare1 < $compare2 ? 1 : 0;
      $iptr += 4;
    }
    elsif ($opcode eq '08') {
      my $compare1 = ($param_mode[2] eq '0' ? $code->[$code->[$iptr+1]] : $code->[$iptr+1]);
      my $compare2 = ($param_mode[1] eq '0' ? $code->[$code->[$iptr+2]] : $code->[$iptr+2]);
      $code->[$code->[$iptr+3]] = $compare1 == $compare2 ? 1 : 0;
      $iptr += 4;
    }

    $count++;
  }
  print "For input(s) [".join(',', @$input)."], diagnostic code was $output\n" if @$input && $output;

  return $output;
}

__DATA__
3,8,1001,8,10,8,105,1,0,0,21,38,55,68,93,118,199,280,361,442,99999,3,9,1002,9,2,9,101,5,9,9,102,4,9,9,4,9,99,3,9,101,3,9,9,1002,9,3,9,1001,9,4,9,4,9,99,3,9,101,4,9,9,102,3,9,9,4,9,99,3,9,102,2,9,9,101,4,9,9,102,2,9,9,1001,9,4,9,102,4,9,9,4,9,99,3,9,1002,9,2,9,1001,9,2,9,1002,9,5,9,1001,9,2,9,1002,9,4,9,4,9,99,3,9,101,1,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,99,3,9,1001,9,1,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,2,9,4,9,99,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,99
