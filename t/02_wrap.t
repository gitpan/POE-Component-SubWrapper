#!/usr/bin/perl -w

use strict;
sub POE::Kernel::ASSERT_DEFAULT () {1}
sub POE::Kernel::TRACE_DEFAULT () { 0 }
use POE qw(Component::SubWrapper);
use Data::Dumper;
poeize Data::Dumper;
use Socket;
use vars qw($VAR1);

package TestMe;

sub various {
  if (wantarray) {
    return @_;
  } else {
    return scalar @_;
  }
}

package main;

sub DEBUG () { 0 }

$| = 1;

print "1..4\n";

# setup a tester

my $error = 0;
my $correct = 0;
my $array_ok = 0;
my $scalar_ok = 0;

sub test_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  DEBUG && print "Test start\n";
  #POE::Component::SubWrapper->spawn('Data::Dumper', 'data');
  POE::Component::SubWrapper->spawn('TestMe', 'testme');
  $kernel->post('Data::Dumper', 'Dumper', [ { a => 1, b => 2 } ], 'callback', 'SCALAR');
  $kernel->post('testme', 'various', [ 1, 2, 3, 4], 'callback_tm_scalar', 'SCALAR');
  $kernel->post('testme', 'various', [ 1, 2, 3, 4], 'callback_tm_array', 'ARRAY');

}

sub test_callback {
  my ($kernel, $heap, $result) = @_[KERNEL, HEAP, ARG0];
  my $hash = eval $result;
  if ($@) {
    $error++;
    print $@;
  }
  DEBUG && print "Generated hash is [", Dumper($hash), "]\n";
  if ($hash->{'a'} == 1 && $hash->{'b'} == 2) {
    $correct++;
  }  
  my $c = scalar keys %{$hash};
  if ($c == 2) {
    $correct++;
  }
  DEBUG && print "result is:\n$result\n";
}

sub test_callback_tm_scalar {
  my ($kernel, $heap, $result) = @_[KERNEL, HEAP, ARG0];
  DEBUG && print "result is:\n$result\n";
  if ($result == 4) {
    $scalar_ok++;
  }
  return;
}

sub test_callback_tm_array {
  my ($kernel, $heap, $result) = @_[KERNEL, HEAP, ARG0];
  DEBUG && print "result is $result\n";
  if ($result->[0] == 1 and
      $result->[1] == 2 and
      $result->[2] == 3 and
      $result->[3] == 4 and
      scalar(@{$result}) == 4 and
      ref($result) eq 'ARRAY'
     ) {
    $array_ok++;
  }      
  return;
}

sub test_stop {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  DEBUG && print "Test stop\n";
}

POE::Session->create (
  inline_states => {
              _start => \&test_start,
              _stop => \&test_stop,
              callback => \&test_callback,
              callback_tm_scalar => \&test_callback_tm_scalar,
              callback_tm_array => \&test_callback_tm_array,
                   }
  );

$poe_kernel->run();

# check results

my $count = 1;

if ($error) {
  print "not ";
} 

print "ok $count\n";
$count++;

if ($correct != 2) {
  print "not ";
}
print "ok $count\n";
$count++;

if ($scalar_ok != 1) {
  print "not ";
}
print "ok $count\n";
$count++;

if ($array_ok != 1) {
  print "not ";
}
print "ok $count\n";

