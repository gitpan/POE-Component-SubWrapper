#!/usr/bin/perl -w

use strict;

$| = 1;

print "1..1\n";

eval "
  use POE;
  use POE::Component::SubWrapper;
";

if ($@) {
  print "not ";
}

print "ok 1\n";
