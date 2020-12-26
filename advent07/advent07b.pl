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
my @phase = (5, 6, 7, 8, 9);
my @perms = permutations(\@phase);
my $all_halted;
for my $perm (@perms) {
  # we need to remember the output of each previous call to be used as
  # input for the next call, but it all starts with a 0
  my $params = [ 0 ];
  # we need to remember where we are in the code for each of the 5
  # running processes we'll have, so when we get the output from one
  # we can pass to the next and so on... but when we get BACK to that
  # ONE, we know where to continue processing now that we have another
  # input it can use
  my $iptr = [ 0, 0, 0, 0, 0 ];
  do {
    # we really only need to watch when the 5th run halts with a final answer
    # but easier to just watch when they have ALL signaled they have halted
    $all_halted = 1;
    for my $run (0..4) {
      my ($result, $halted);
      # the phase is sent as the first parameter to the intcode, but ONLY on the first call
      # after that, we are continuing off where it PAUSED to send us output, so we only
      # need to send the next input value for it to use
      ($result, $halted, $iptr->[$run]) = run_intcode(\@intcode, $iptr->[$run], [ $iptr->[$run] == 0 ? $perm->[$run] : (), $params->[$run] ]);
      # store this $run output as the input for the next $run
      # (which might loop us from 4 back to 0, thus the %
      $params->[($run + 1) % 5] = $result;
      $all_halted = 0 unless $halted;
    }
  } while !$all_halted;

  if ($params->[0] > $max_thrust) {
    $max_thrust = $params->[0];
    $remember = $perm;
  }
}

print "Phase order [@$remember] gave us a max thrust of $max_thrust\n";

exit;

my $result = run_intcode(\@intcode, [ 0 ]);



sub run_intcode {
  my $code = shift;
  my $iptr = shift;
  my $input = shift;

  my $count = 0;
  my $output;

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
      # print("PAUSED output was $output\n") unless $output == 0 || $code->[$iptr+2] == 99;
      $iptr += 2;
      return ($output, 0, $iptr) unless $code->[$iptr] == 99;
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

  return ($output, 1, $iptr);
}

__DATA__
3,8,1001,8,10,8,105,1,0,0,21,38,55,68,93,118,199,280,361,442,99999,3,9,1002,9,2,9,101,5,9,9,102,4,9,9,4,9,99,3,9,101,3,9,9,1002,9,3,9,1001,9,4,9,4,9,99,3,9,101,4,9,9,102,3,9,9,4,9,99,3,9,102,2,9,9,101,4,9,9,102,2,9,9,1001,9,4,9,102,4,9,9,4,9,99,3,9,1002,9,2,9,1001,9,2,9,1002,9,5,9,1001,9,2,9,1002,9,4,9,4,9,99,3,9,101,1,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,99,3,9,1001,9,1,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,2,9,4,9,99,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,99
