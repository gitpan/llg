#!/usr/local/bin/perl

BEGIN {
  push(@INC, "$ENV{HOME}/perl/lib");
}
require 5.000;
use LLg;
use Turtle;

($level, $step, $factor) = (4, 80, 2);

print "Nombre de niveaux : ", $level, "\n",
       "Longueur initiale : ", $step, "\n",
       "Facteur de réduction: ", $factor, "\n";

$turtle = Turtle->new(300, 300, 0, 1);
$FLOCON = And->new(\(
		   $BROKEN_LINE, Do->new(sub{ $turtle->right(120) }),
		   $BROKEN_LINE, Do->new(sub{ $turtle->right(120) }),
		   $BROKEN_LINE
		  ));

$BROKEN_LINE =  
    Or->new(\(
	    Do->new(sub { 
	      my $self = shift;
	      my @inheritedAtt =  $self->inherited();
	      if ($inheritedAtt[0] == 1) {
		$turtle->forward($inheritedAtt[1]);
		$self->status(1);
	      } else {
		$self->status(0);
	      }
	    }),
	    And->new(\(
		     Hook->new(\$BROKEN_LINE, 
			       sub { $turtle->left(60) },
			       sub { ($_[1] - 1, $_[2]/$_[3], $_[3]) }
			      ),
		     Hook->new(\$BROKEN_LINE, 
			       sub { $turtle->right(120) }, 
			       sub { ($_[1] - 1, $_[2]/$_[3], $_[3]) }
			      ),
		     Hook->new(\$BROKEN_LINE, 
			       sub { $turtle->left(60) }, 
			       sub { ($_[1] - 1, $_[2]/$_[3], $_[3]) }
			      ),
		     Hook->new(\$BROKEN_LINE, 
			       sub { }, 
			       sub { ($_[1] - 1, $_[2]/$_[3], $_[3]) }
			      ),
		    )),
 ));

$FLOCON->next($level, $step, $factor);
$turtle->show;
__END__

