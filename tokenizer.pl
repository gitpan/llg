#!/usr/local/bin/perl

require 5.000;

BEGIN {		
  push(@INC,  ("$ENV{'HOME'}/perl/lib")); # for example
}
use Lex;
$Lex::debug = 1;
#$| = 1;
@tokens = (
	   'ADDOP' => '[-+]', 
	   'LEFTP' => '[(]',
	   'RIGHTP' => '[)]',
	   'INTEGER' => '[1-9][0-9]*',
	   'NEWLINE' => '\n',
	   'STRING' => '["]', sub {
	     my $self = shift;
	     my $string = $';
	     my $buffer = $string;
	     while($string !~ /"/) {
                   $string = $self->readline;
		   $buffer .= $string;
             }
             $buffer =~ s/^[^"]*"//;
	     $self->set($buffer);
	     qq!"$&!;		# token content
	   },
	   'ERROR' => '.*',
	  );

$lexer = Lex->new(@tokens);
$lexer->from(\*DATA);
print "Tokenization of DATA:\n";

TOKEN:while (1) {
  $token = $lexer->nextToken;
  if (not $lexer->eof) {
    print "Line $.\t";
    print "Type: ", $token->name, "\t";
    print "Content:->", $token->get, "<-\n";
  } else {
    last TOKEN;
  }
}

__END__
1+2-5
"multiline
string"
