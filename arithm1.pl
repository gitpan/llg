#!/usr/local/bin/perl 

require 5.001;
#$| = 1;
BEGIN {		
  push(@INC,  ('.', "$ENV{'HOME'}/perl/lib"));
}
use LLg;
$Lex::debug = 0;

# A Small Grammar
# 
#   EXPR ::= FACTOR { ADDOP FACTOR }
#   ADDOP ::= '+' | '-'
#   FACTOR ::= INTEGER | '(' EXPR ')'
#   INTEGER ::= '0|[1-9][0-9]*'

@tokens = (
	   'ADDOP' => '[-+]', 
	   'LEFTP' => '[(]',
	   'RIGHTP' => '[)]',
	   'INTEGER' => '0|[1-9][0-9]*',
	  );
$reader = Lex->new(@tokens);
#$ADDOP->debug;

$expr = And->new(\($factor, Any->new(\$ADDOP, \$factor)),
                 sub { 
		   shift(@_);
		   my $result = shift(@_);
		   my ($op, $integer);
		   while ($#_ >= 0) {
		     ($op, $integer) = (shift(@_), shift(@_));
		     if ($op eq '+')  {
		       $result += $integer;
		     } else {
		       $result -= $integer;
		     }
		   }
		   $result;
		 });
$factor = Or->new(\$INTEGER, \$parexp);
$parexp = And->new(\$LEFTP, \$expr, \$RIGHTP,
		    sub { $_[2] });

print STDERR "Type your arithmetic expression: ";
print "Result: ", $expr->next, "\n";
1;

__END__
