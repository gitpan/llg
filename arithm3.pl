#!/usr/local/bin/perl

require 5.001;
BEGIN {		
  push(@INC, ("$ENV{'HOME'}/perl/lib"));
}
use LLg;
use Lex;

#$| = 1;
#$Lex::debug = 1;
#$Token::debug = 1;

# Grammar of Arithmetic Expressions
# 
#   LINES ::= { LINE }
#   LINE  ::= '\n' |
#             EXPR '\n' |
#             ERROR 
#   EXPR ::= TERM { ADDOP TERM }
#   ADDOP ::= '+' | '-'
#   TERM ::= FACTOR { MULOP FACTOR }
#   MULOP ::= '*' | '/'
#   FACTOR ::= NUMBER | '(' EXPR ')'
# 

# Parser
# 
# Token definitions
$reader = Lex->new(
		   'MINUS' => '-',
		   'ADDOP' => '[+]',
		   'MULOP' => '[*\/]',
		   'LEFTP' => '[(]',
		   'RIGHTP' => '[)]',
		   'NUMBER' => '(?:\d+([.]\d*)?|[.]\d+)(?:[Ee][+-]?\d+)?',
		   'NEWLINE' => '\n',
		   'ERROR' => '.+', sub {
		     warn "impossible to recognize: ", $&; 
		     $_[0]->reset;
		   }
		  );
# Rules
$LINES = Any->new(\$LINE);
$LINE = Or->new(\(
		$NEWLINE,
		And->new(\$EXPR, \$NEWLINE),
		$ERROR,
		Do->new(sub {
		    print STDERR "\n", exit if $reader->eof;
		    print STDERR "syntax error in $_";
		    print STDERR "unanalyzed text: ", 
		    $reader->token->get, $reader->buffer, "";
		    $reader->reset;
		}),
	       ), sub {
		 shift; 
		 pop;		# pop the newline
		 if (defined($_[0])) {
		     print STDERR "@_\n";
		 } else {
		     print "";
		 }
	       }, sub { 
		 print STDERR "$prompt" if $prompt; 
	       });

$EXPR = And->new(\($TERM, Any->new(\(Or->new(\$MINUS, \$ADDOP), $TERM))),	 
		    sub {
		      shift;
		      my $result = shift;
		      while ($#_ >= 0) {
			if ($_[0] eq '+')  {
			  $result += $_[1];
			} else {
			  $result -= $_[1];
			}
			shift; shift;
		      }
		      $result;
		    });
$TERM = And->new(\($FACTOR, Any->new(\$MULOP, \$FACTOR)),
		    sub {
		      shift;
		      my $result = shift;
		      while ($#_ >= 0) {
			if ($_[0] eq '*')  {
			  $result *= $_[1];
			} else {
			  $result /= $_[1] or
			    warn "Illegal division by zero\n";
			}
			shift; shift;
		      }
		      $result;
		    });
$FACTOR = And->new(\(Opt->new(\$MINUS),
		   Or->new(\$NUMBER, \$PAREXP, sub { $_[1] })
		   ), sub { $_[1] eq '-' ? -$_[2] : $_[1] }
		  );
$PAREXP = And->new(\$LEFTP, \$EXPR, \$RIGHTP, sub { $_[2] });


# Prompt or not?
if (-t STDIN && -t STDERR) {
    $| = 1;
    print STDERR "A very simple interpreter for arithmetic expressions\n";
    print STDERR "P. Verdret, 1995\n";
    $prompt = '=> ';
} else {
    $prompt = '';
}

$LINES->next;
print "\n";
1;
__END__






