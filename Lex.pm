#!/usr/local/bin/perl -w
# Copyright (c) 1995 Philippe Verdret. 

use strict qw(vars);
use strict qw(refs);
use strict qw(subs);

require 5.001;
package Lex;
use Carp;
@Lex::ISA = qw(Carp Debug);	#

my $sub = sub {};
my $FH = \*STDIN;		# Filehandle name on which to read
my $buffer = '';		# string to tokenize
my $eof = 0;			# if eof is met
$Lex::skip = '[ \t]+';		# characters to skip
my $defaultToken = Token->new('default token'); # default token
my $chomp = 0;			# remove newline at end of line
my $read = 0;			# read or not read
my $singleline = 0;		# reading of singleline expressions
my $pendingToken = 0;		# if 1 there is a pending token
$Lex::debug = 0;

my $idx = 0;
my $sub_idx = $idx++;
my $fh_idx = $idx++;
$Lex::buffer_idx = $idx++;
$Lex::skipped_idx = $idx++;
$Lex::eof_idx = $idx++;
$Lex::skip_idx = $idx++;
$Lex::pendingToken_idx = $idx++;
$Lex::chomp_idx = $idx++;
$Lex::read_idx = $idx++;
$Lex::singleline_idx = $idx++;
$Lex::debug_idx = $idx++;
$Lex::reader = bless [		# Default reader
		      $sub,	# 
		      $FH,	# 
		      $Lex::buffer, # 
		      $Lex::skipped,
		      $Lex::eof, # 
		      $Lex::skip, # 
		      $defaultToken,
		      $chomp,
		      $read,
		      $singleline,
		      $Lex::debug,
		      ];
sub nextToken { &{$_[0]->[$sub_idx]} }
sub eof { 
  my $self = shift;
  $self->[$Lex::eof_idx];
} 
sub token {			# always return a Token object
  my $self = shift;
  $self->[$Lex::pendingToken_idx] or
    $defaultToken 
} 
sub set { 
  my $self = shift;
  $self->[$Lex::buffer_idx] = $_[0];
} 
sub get { 
  my $self = shift;
  $self->[$Lex::buffer_idx]; 
} 
sub buffer { 
  my $self = shift;
  if (defined $_[0]) {
    $self->[$Lex::buffer_idx] = $_[0] 
  } else {
    $self->[$Lex::buffer_idx];
  }
} 
sub less { 
  my $self = shift;
  if (defined $_[0]) {
    $self->[$Lex::buffer_idx] = $_[0] . 
      $self->[$Lex::buffer_idx];
  }
}
sub reset { 
  my $self = shift;
  $self->[$Lex::read_idx] = 0; 
  $self->[$Lex::buffer_idx] = ''; 
  if ($self->[$Lex::pendingToken_idx]) { 
    $self->[$Lex::pendingToken_idx]->set();
    $self->[$Lex::pendingToken_idx] = 0;
  }
}

				# Lexer configuration
sub from {
  my $self = shift;
  if (ref($_[0]) eq 'GLOB' and 
      defined fileno($_[0])) {	# Read data from a filehandle
    $self->[$fh_idx] = $_[0];
  } elsif ($_[0]) {		# Data in a variable or a list
    $self->[$fh_idx] = '';
    $self->[$Lex::buffer_idx] = join($", @_); # Data from an array
  } else {
    $self->[$fh_idx];
  }
}
sub skip { 
  my $self = shift;
  defined($_[0]) ? 
    $self->[$Lex::skip_idx] = $_[0] :
      $self->[$Lex::skip_idx];
}
				# switches
sub chomp { 
  my $self = shift;
  $self->[$Lex::chomp_idx] = $self->[$Lex::chomp_idx] ?
    0 : 
      1;
}
sub singleline { 
  my $self = shift;
  $self->[$Lex::singleline_idx] = $self->[$Lex::singleline_idx] ? 
    0 : 
      1;
}
# parts to substitute are inclosed between << >>
sub preprocess {
  my $code = shift;
  $code =~ s/<<(.+?)>>/"$1"/eeg;
  if ($code =~ /<<.*?>>/) {
    warn "<<>> found in code: $&\n";
  }
  $code;
}
my $header = q!
{		
    my $skipped = '';
    my $buffer = $_[0]->[<<$Lex::buffer_idx>>];
    if (not $_[0]->[<<$Lex::eof_idx>>] and     # not EOF
	$buffer eq '') { # $buffer is empty
      do {
	$buffer = $_[0]->readline;	# OPT
	$buffer =~ s/^<<$Lex::skip>>//o;
	$skipped .= $&;
      } while (not $_[0]->[<<$Lex::eof_idx>>] and 
	       $buffer eq '');
      # record is read if singleline mode
      $_[0]->[<<$Lex::read_idx>>] = 1 if $_[0]->[<<$Lex::singleline_idx>>] == 1;
    } else {
      $buffer =~ s/^<<$Lex::skip>>//o;
      $skipped = $&;		
    }
    my $content = '';
    my $pendingToken = 0;
    $_[0]->[<<$Lex::buffer_idx>>] = $buffer;
  SWITCH:{!;my $rowHeader = q!  
      $buffer =~ s/^<<$Lex::regexp>>//o and do {
      print STDERR "Token consumed(<<$Lex::regexp>>): ", $<<$Lex::id>>->name, " $&\n" 
	if $_[0]->[<<$Lex::debug_idx>>];
      $content = $&;
      $_[0]->[<<$Lex::buffer_idx>>] = $buffer; # for associated anonymous sub
      $pendingToken = $<<$Lex::id>>;
      $_[0]->[<<$Lex::pendingToken_idx>>] = $pendingToken;!;my $rowSub = q!
      $content = &{$<<$Lex::id>>->mean}($_[0], $content);!;my $rowFooter = q!
      $<<$Lex::id>>->set($content);
      last SWITCH;
    };!;my $footer = q!
  }#SWITCH
  if ($skipped ne '') {
    $_[0]->[<<$Lex::skipped_idx>>] = $skipped;
  }
  return $pendingToken;
}!;

sub new {			# Generation of a Lexer and 
				# of the nextToken associated routine
  shift;
  if (not defined($_[0])) {
    croak("no parameters for the new method");
    return;
  }

  my $reader = bless [		# 
		      $sub,	# 
		      $FH,	#
		      $Lex::buffer, # 
		      $Lex::skipped,
		      $Lex::eof, # 
		      $Lex::skip, # 
		      0,
		      $chomp,
		      $read,
		      $singleline,
		      $Lex::debug,
		      @_,	# not used for the moment
		      ];
  $Lex::reader = $reader;

  my $body = preprocess($header);
  my $package = (caller(0))[0];
  my $sub;
  local($Lex::id);
  local($Lex::regexp);
  while ($#_ > -1) {
    ($Lex::id, $Lex::regexp) = (shift, shift);
    $Lex::id = "$package" . "::" . "$Lex::id";
    if (ref($_[0]) eq 'CODE') {	# next arg is a sub reference
      $sub = shift;
    } else {
      $sub = undef;
    }
    $Lex::regexp =~ s{
	((?:[^\\]|^)(?:\\{2,2})*)  (?# Context before)
	([/!\"])	           (?# Delimiters)
    }{$1\\$2}xg;
				# creation of a Token object
    eval "\$$Lex::id = Token->new(\$Lex::id, \$Lex::regexp, \$sub, \$reader);";
    $body .= preprocess($rowHeader);
    if ($sub) {
      $body .= preprocess($rowSub);
    }
    $body .= preprocess($rowFooter);
  }
  $body .= preprocess($footer);
  eval qq!\$reader->[$sub_idx] = sub $body!;
  if ($@ or $Lex::debug)		# can be usefull ;-)
    {
      print STDERR "$body\n";
      print STDERR "$@\n";
      die "\n" unless $Lex::debug;
    }
  $reader;			# reader identity
}
sub readline {
  my $fh = $_[0]->[$fh_idx];
  $_ = <$fh>;
  if (not defined($_)) {
    $_[0]->[$Lex::eof_idx] = 1;
  } else {
    chomp($_) if $_[0]->[$Lex::chomp_idx];
    $_;
  }
}
				
$Lex::stack = Stack->new;	# Warning! just one buffer stack
sub select {
  my $self = shift;
  $Lex::reader = $self;
}
sub restore {
  my $self = shift;
  my $stack = $Lex::stack;
  my $num = $#{$stack};
#  print STDERR "buffer content ", $self->[$Lex::buffer_idx] , "\n" if $Lex::debug;
  return unless $num >= 0 and ${$stack}[$num] ne '';
				# Current pending Token
  my $token = $self->[$Lex::pendingToken_idx];
  if ($token) {
    $self->save($self->[$Lex::skipped_idx] . $token->get);
    $token->set;
    $self->[$Lex::pendingToken_idx] = 0;	
  }
				# Content in current buffer Stack
  $self->[$Lex::buffer_idx] = ${$stack}[$num] .  $self->[$Lex::buffer_idx];
#  print STDERR "restored from $num: ", ${$stack}[$num] , "\n" if $Lex::debug;
  ${$stack}[$num] = ''; # now discard the content
}
sub save {			
  my $self = shift;
  my $stack = $Lex::stack;
  my $num = $#{$stack};
  return unless $num >= 0;
  print "saved in $num: $_[0]\n" if $Lex::debug;
  ${$stack}[$num] .= $_[0];
  print "now in $num->${$stack}[$num]<-\n" if $Lex::debug;
}
sub pop  { $Lex::stack->pop  }
sub push { $Lex::stack->push }

1;

package Token;
@Token::ISA = qw(Debug);
$Token::debug = 0;
my $idx = 0;
my $status_idx = $idx++;
my $string_idx = $idx++;
my $name_idx = $idx++;
my $regexp_idx = $idx++;
my $sub_idx = $idx++;
my $reader_idx = $idx++;
my $debug_idx = $idx++;		
sub new {
  bless [
	 0,			# object status
	 '',			# readed string 
	 $_[1],			# name
	 $_[2],			# regexp
	 $_[3],			# sub
 	 $_[4],			# reader identity
	 $Token::debug,
	 ];
}
sub status { 
  defined($_[1]) ? 
    $_[0]->[$status_idx] = $_[1] : 
      $_[0]->[$status_idx];
} 
sub set {    $_[0]->[$string_idx] = $_[1] } # hold string
sub get {    $_[0]->[$string_idx] }	# return recognized string 
sub name {   $_[0]->[$name_idx] }	# name of the token
sub type {   $_[0]->[$name_idx] }	# synonym of the name method
sub regexp { $_[0]->[$regexp_idx] }	# regexp
sub mean {   $_[0]->[$sub_idx] }	# anonymous fonction
sub reader { $_[0]->[$reader_idx] }	# id of the reader

sub next {
  my $self = shift;
  my $reader = $self->reader;
  my $pendingToken = $reader->[$Lex::pendingToken_idx];
  if ($reader->[$Lex::read_idx] and # expression is already readed
      $reader->[$Lex::buffer_idx] eq '' and 
      not $pendingToken) {
    $self->status(0);
    return;
  }
  if (not $pendingToken) {
    $reader->nextToken();
  }
  print STDERR "Try to find: ", $self->[$name_idx], "\n" if $Token::debug;
  if ($self == $reader->[$Lex::pendingToken_idx]) {
    print STDERR "Token found: ", $self->[$name_idx], " ", 
    $self->[$string_idx], "\n" if $Token::debug;
    $reader->[$Lex::pendingToken_idx] = 0; # now no pending token
    my $content = $self->get();		
    $reader->save($reader->[$Lex::skipped_idx] . $content);
    $self->set();
    $self->status(1);
    $content;			# return token string
  } else {
    $self->status(0);
    undef;
  }
}
1;

package Stack;		
my @ISA= qw(Debug);
my $debug = 0;
sub new { bless [];}
sub top {
    my $num = $#{$_[0]};
    defined($_[1]) ? ${$_[0]}[$num] = $_[1] : ${$_[0]}[$num];
}
sub push { push(@{$_[0]}, $_[1]) }
sub pop { pop(@{$_[0]}) }
sub purge { @{$_[0]} = () }

package Debug;
sub debug { 
  my $self = shift;
  my $package = ref($self);
  if ($debug) {
    $debug = 0;
    print STDERR "debug OFF in ", $package, "\n";
  } else {
    $debug = 1;
    print STDERR "debug ON in ", $package, "\n";
  }
  if ($package eq 'Lex') {	# not elegant, change this!!!
    if ($self->[$Lex::debug_idx]) {
      print STDERR "debug OFF for $package object\n";
    } else {
      print STDERR "debug ON for $package object\n";
    }
    $self->[$Lex::debug_idx] ^= 1;
  }
}

1;
__END__
