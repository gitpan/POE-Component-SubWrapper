package POE::Component::SubWrapper;

use strict;
use Carp qw(croak);
use POE;
use Devel::Symdump;
use vars qw(@ISA %EXPORT_TAGS @EXPORT @EXPORT_OK $VERSION);

require Exporter;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use POE::Component::SubWrapper ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw( poeize 
	
);
$VERSION = '0.06';

sub DEBUG () { 0 }

sub poeize (*) {
  my $package = shift;
  spawn($package, $package);
}

# create a new PoCo::SubWrapper session
sub spawn {
  DEBUG && print "PoCo::SubWrapper->spawn: Entering\n";
  my $type = shift;
  my $package = shift;
  my $alias = shift;
  croak "Too many args" if scalar @_;
  $alias = $package unless defined($alias) and length($alias);

  DEBUG && print "PoCo::SubWrapper->spawn: type = [$type], package = [$package], alias = [$alias]\n";

  # get subroutines defined by package.
  my @subs;

  my $sym = Devel::Symdump->new($package);
  {
    no strict 'refs';
    foreach my $function ($sym->functions) {
      *p = *$function;
      my $coderef = *p{CODE};
      my ($key) = ($function =~ /([^:]*)$/);
      use Data::Dumper;
      DEBUG && print "Symbol is $function\n";
      DEBUG && print "key is $key\n";
      DEBUG && print "Coderef is [", Dumper($coderef), "]\n";
      push @subs, { name => $key, code => $coderef };      
    }
  }

  my %states;
  foreach my $sub (@subs) {
    DEBUG && print "Building state for ", $sub->{name}, "\n";
    $states{$sub->{name}} = build_handler($package, $sub->{code});
  }

  $states{'_start'} = \&wrapper_start;
  $states{'_stop'} = \&wrapper_stop;
  POE::Session->create(
          inline_states => \%states,
          args => [ $alias ],
                      );
  undef;
}

sub wrapper_start {
  my ($kernel, $heap, $alias) = @_[KERNEL, HEAP, ARG0];
  $kernel->alias_set($alias);
}

sub wrapper_stop {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

}

# return a closure that knows how to call the specified sub and post
# the results back.
sub build_handler {
  my ($package, $sub) = @_;

  my $ref = sub {
    my ($kernel, $heap, $args_ref, $callback, $context, $sender) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, SENDER];
    DEBUG && print "Handler called for package=[$package], sub = [$sub]\n"; 
    my @sub_args = @{$args_ref};
    my $result;
    #my $name = "${package}::${sub}";
    DEBUG && print "handler: calling [$sub]\n";
    if (defined($context) and $context eq 'SCALAR') {
      # scalar context. default if not supplied.
        DEBUG && print "handler: calling in scalar context\n";
        $result = scalar &{$sub}(@sub_args);
    } else {
      # array context.
      my @result;
        DEBUG && print "handler: calling in array context\n";
        @result = &{$sub}(@sub_args);
        $result = \@result;
    }

    $kernel->post($sender, $callback, $result);
    return;
  };

  return $ref;
}

1;

__END__

=head1 NAME

POE::Component::SubWrapper - event based wrapper for subs

=head1 SYNOPSIS

  use POE::Component::SubWrapper;
  POE::Component::SubWrapper->spawn('main');
  $kernel->post('main', 'my_sub', [ $arg1, $arg2, $arg3 ], 'callback_state');

=head1 DESCRIPTION

This is a module which provides an event based wrapper for subroutines.

SubWrapper components are not normal objects, but are instead 'spawned'
as separate sessions. This is done with with PoCo::SubWrapper's 
'spawn' method, which takes one required and one optional argument.
The first argument is the package name to wrap. This is required. The
second argument is optional and contains an alias to give to the session
created. If no alias is supplied, the package name is used as an alias.

Another way to create SubWrapper components is to use the C<poeize> method,
which is included in the default export list of the package. You can simply
do:

  poeize Data::Dumper;

and Data::Dumper will be wrapped into a session with the alias 'Data::Dumper'.

When a SubWrapper component is created, it scans the package named for
subroutines, and creates one state in the session created with the same name
of the subroutine.

The states each accept 3 arguments:

=over 4

=item *

An arrayref to a list of arguments to give the subroutine.

=item *

A state to callback with the results.

=item *

A string, either 'SCALAR', or 'ARRAY', allowing you to decide which
context the function handled by this state will be called in.

=back

The states all call the function with the name matching the state, and
give it the supplied arguments. They then postback the results to the named
callback state. The results are contained in C<ARG0> and are either a scalar
if the function was called in scalar context, or an arrayref of results
if the function was called in list context.

=head1 EXAMPLES

The test scripts are the best place to look for examples of POE::Component::Subwrapper usage. A short example is given here:

  use Data::Dumper;
  poeize Data::Dumper;
  $kernel->post('Data::Dumper', 'Dumper', [ { a => 1, b => 2 ], 'callback_state, 'SCALAR');

  sub callback_handler {
    my $result = @_[ARG0];
    # do something with the string returned by Dumper({ a => 1, b => 2})
  }

Data::Dumper is the wrapped module, Dumper is the function called, C<{a =E<gt> 1, b =E<gt> 2}> is the data structure that is dumped, and C<$result>
is the resulting string form.

=head2 EXPORT

The module exports the following functions by default:

=over 4

=item C<poeize>

A function called with a single bareword argument specifying the package
to be wrapped.

=back

=head1 AUTHOR

Michael Stevens - michael@etla.org.

=head1 SEE ALSO

perl(1).

=cut
