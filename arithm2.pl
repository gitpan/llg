#!/usr/local/bin/perl

BEGIN {		
  push(@INC,  ('.', "$ENV{'HOME'}/perl/lib"));
}

use LLg;
use Lex;
use Tracer;

#$| = 1;
#$Lex::debug = 1;
#$Token::debug = 1;

# A Small Grammar
# 
#   EXPR ::= TERM { ADDOP TERM }
#   ADDOP ::= '+' | '-'
#   TERM ::= FACTOR { MULOP FACTOR }
#   MULOP ::= '*' | '/'
#   FACTOR ::= NUMBER | '(' EXPR ')'
# 

# 
# Parser
# 
# Tokens
@tokens = qw(
	   ADDOP [+-]
	   MULOP [\*\/] 
	   LEFTP [(]
	   RIGHTP [)]
	   NUMBER (?:\d+([.]\d*)?|[.]\d+)(?:[Ee][+-]?\d+)?
	  );
$reader = Lex->new(@tokens);
$reader->singleline;
$reader->chomp;

# Rules
$expr = And->new(\($term,  Any->new(\$ADDOP, \$term)), 
		    sub {
		      $DB::single = 1;
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
$term = And->new(\($factor, Any->new(\$MULOP, \$factor)),
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
$factor = Or->new(\$NUMBER, \$parexp,
		  sub {
		    $DB::single = 1;
		    $_[1] });
$parexp = And->new(\$LEFTP, \$expr, \$RIGHTP,
		   sub { $_[2] });
# 
# Interaction Loop
$prompt = '=> ';
EXPR:while (1) {
    print STDERR "$prompt";
    print STDERR $expr->next;
    last EXPR if $reader->eof;
    if (not $expr->status) {
      print STDERR "invalid expression: $_\n";
      print STDERR "unanalyzed text: ", 
      $reader->token->get, $reader->buffer, "\n";
    } else {
      print "\n";
    }
    $reader->reset;
}
print "\n";
1;

__END__




