#!/usr/local/bin/perl -w
no strict qw(vars);
use strict qw(refs);
use strict qw(subs);

require 5.001;
package LLg;
use Lex;
use Carp;
sub new {		
  my $package = shift; 
  my @args = @_;
  my $ref;
  my $pre;
  my $post;
  my $elt;
				# user interface 
  ARGS:while (1) {	
      $elt = pop(@args);  
      $ref = ref($elt);
      if ($ref and $ref eq 'CODE') { # find anonymous routines   
	if ($#args >= 0 and $args[$#args] eq 'post') { # post => sub {...}
	  pop(@args);
	  $post = $elt;
	} elsif ($#args >= 0 and $args[$#args] eq 'pre') { # pre => sub {...}
	  pop(@args);
	  $post = $elt;
	} elsif (not defined($post)) {	# 
	  $post = $elt;
	} elsif ($post) {	# sub {...}, sub {...}
	  $pre = $post;
	  $post = $elt;
	}
      } else {
	push(@args, $elt);
	last ARGS;
      }
    }

  if ($package eq 'Do' and not defined($post)) {
    croak("$package object must have one anonymous routine as argument");
  }

  @args = ([ @args ],  ($pre or $post) ? ($post, $pre) : undef);

  # Number of objects
  if ($package ne 'Do') {
    if ($package eq 'Hook') {
      if ($#{$args[0]} > 0) {
	croak("$package object must have just one object as argument");
      }
    } elsif ($#{$args[0]} < 0) {
      croak("$package object must have at least one object as argument");
    }
    # Object type
    foreach (@{$args[0]}) {
      $ref = ref($_);
      if ($ref ne 'REF' and 
	  $ref ne 'SCALAR' and
	  $ref ne 'ARRAY') {
	croak("$_ isn't an ARRAY or a SCALAR reference");
      }
    }
  }
  bless [1, @args], $package;
}
sub pre { $_[0][3] }
sub post { $_[0][2] }
sub probe { print STDERR ref(shift), "\t", @_, "\n" }
sub status { defined($_[1]) ? $_[0]->[0] = $_[1] : $_[0]->[0] } 

package Hook;
@Hook::ISA = qw(LLg);

sub inherited { @_h }
sub next {
    my $self = shift;
    my $obj = ${${$self}[1]}[0];

    # Processing of inherited Attributes 
    # function: "pre" action
    # parameters: inherited attributes
    # return: inherited attributes
    local @_h = @_;  
    my $pre = $self->pre;
    if (defined($pre)) {	
      @_h = &{$pre}($self, @_);
    }
    # Processing of Sub-objects 
    # function: next
    # parameters: inherited attributes
    # return: transformed synthetized attributes
    local @_s = $$obj->next(@_h);

    # Semantic
    # function: semantic action
    # parameters: synthetized attributes
    # return: synthetized attributes
    if (not ($$obj->status)) {
	$self->status(0);
	();		
    } else {
      $self->status(1);
      my $post = $self->post;
      if (defined($post)) {
	&{$post}($self, @{_s});
      } else {
	@{_s}; 
      }
    } 
}
package And;
@And::ISA = qw(LLg);
sub inherited { @_h }
sub next {
    my $self = shift;
    my @objects = @{${$self}[1]};
    my @return;
    
    local @_h = @_;  
    my $pre = $self->pre;
    if (defined($pre)) {	
      @_h = &{$pre}($self, @_);
    }
    my $status = 1;
    my $obj;
    local @_s;
  OBJ:foreach $obj (@objects) { # sub-objects
      @return = $$obj->next(@_h);
      if (not $$obj->status) {
	$status = 0;
	last OBJ;
      } else {
	push(@_s, @return) if $#return >= 0;
      }
    }
    if ($status) { 
      $self->status(1);
      my $post = $self->post;
      if (defined($post)) {
	&{$post}($self, @_s);
      } else {
	@_s;
      }
    } else {
      $self->status(0);
      ();
    }
}
package Or;
@Or::ISA= qw(LLg);
my $reader = $Lex::reader;	# Default reader

sub inherited { @_h }
sub next {
    my $self = shift;
    my @objects = @{${$self}[1]};

    local(@_h) = @_;  
    my $pre = $self->pre;
    if (defined($pre)) {	
      @_h = &{$pre}($self, @_);
    }

    local @_s;
    my $obj;
    my @return;
    $Lex::reader->push;
 OBJ:foreach $obj (@objects) { 
    @return = $$obj->next(@_h);
    if ($$obj->status) {
      @_s = @return;
      $self->status(1);
      last OBJ;
    } else {			# failure!
      $Lex::reader->restore;	# backtracking
      $self->status(0);
    }
  } 
    $Lex::reader->pop;
    if ($self->status) {
      my $post = $self->post;
      if (defined($post)) {
	&{$post}($self, @_s);
      } else {
	@_s;
      }
    } else {
	();
    }
}
package Any;		
@Any::ISA= qw(LLg); 
my $reader = $Lex::reader;	# Default reader

sub inherited { @_h }
sub next {
    my $self = shift;
    my @objects = @{${$self}[1]};

    # action before
    local @_h = @_;  
    my $pre = $self->pre;
    if (defined($pre)) {	
      @_h = &{$pre}($self, @_);
    }

    $self->status(1);
    local @_s;
    my @return;
    my @tmpReturn;
    my $post = $self->post;
    my $obj;
  OBJ:while (1) {
      $Lex::reader->push;
      foreach $obj (@objects) {
	@return = $$obj->next(@_h);
	if (not $$obj->status) {
	  $Lex::reader->restore;
	  last OBJ;
	} 
	push(@_s, @return) if $#return >= 0;
      }
      $Lex::reader->pop;
      push(@tmpReturn, @_s);
      @_s = ();
  }
    $Lex::reader->pop;
    $self->status(1);
    @_s = @tmpReturn;
    if (defined($post)) {
      &{$post}($self, @_s);
    } else {
      @_s;
    }
}
package Opt;
@Opt::ISA = qw(LLg); 
my $reader = $Lex::reader;	# Default reader

sub inherited { @_h }
sub next {
  my $self = shift;
  my @objects = @{${$self}[1]};

  # action before
 local @_h = @_;  
  my $pre = $self->pre;
  if (defined($pre)) {	
    @_h = &{$pre}($self, @_);
  }
  local @_s;
  my @return;
  my @tmpReturn;
  my $post = $self->post;
  my $obj;
  $Lex::reader->push;
  OBJ:foreach $obj (@objects) {
      @return = $$obj->next(@_h);
      if (not $$obj->status) {
	$Lex::reader->restore;	
	$self->status(1);	
	@_s = ();
	last OBJ;
      } 
      push(@_s, @return) if $#return >= 0;
    }
  $Lex::reader->pop;
  $self->status(1);  
  if (defined($post)) {
    &{$post}($self, @_s);
  } else {
    @_s;
  }
}
package Do;
@Do::ISA = qw(LLg);
sub inherited { @_h }
sub next { 
  my $self = shift;
  local @_h = @_;
  &{$self->post}($self, @_s);
}
1;
__END__






