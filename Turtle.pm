#!/usr/local/bin/perl

require 5.001;
package Area;
use English;
use Tk;
use Tk::Dialog;
use Tk::ErrorDialog;

sub new {
    shift;
    my $window = MainWindow->new;
    $window->geometry('+300+300');
    my $c = $window->Canvas(-width => $_[0], 
			    -height => $_[1], 
			    -relief => 'sunken', 
			    -bd => 2);
    bless \$c;
}
sub show {	
    my $self = shift;
    $$self->pack(-expand => 'yes', -fill => 'both');
    MainLoop;
}
sub draw {
    my $self = shift;
    ${$self}->create(@_);
}
sub cleanup {			# don't remove the turtle
  warn "not yet implemented";
}
sub empty {			# remove all
    my $self = shift;
    $$self->delete('all');
}

package Turtle;
@ISA = qw(Area);
$debug = 1;

# Default values
$H = 500;			# height of Area
$W = 500;			# width of Area
$X0 = $W / 2;			# Turtle position at creation
$Y0 = $H / 2;			# Turtle position at creation
$ORIENT = - 90 % 360;		# Initial orientation
$STATUS = 1;			# Pen down
$COLOR = 'black';		# Color
$WIDTH = 1;			# line width
$K = 3.14159265358979323846/180;

$ground = Area->new($H, $W);
sub show { $ground->show();}

sub new {
    shift;
    my($param);
    my(@param);
    my($i) = 0;
    while($#_ != -1) {
      $param = shift;
      if ($param eq '-fill' or $param eq '-color')  {
	$param[4] = shift;
      } elsif ($param eq '-width') {
	$param[5] = shift;
      } else {
	$param[$i++] = $param;
      }
    }
    bless [defined($param[0]) ? $param[0] : $X0,
	   defined($param[1]) ? $param[1] : $Y0,
	   defined($param[2]) ? $param[2] : $ORIENT,
	   defined($param[3]) ? $param[3] : $STATUS,
	   defined($param[4]) ? $param[4] : $COLOR,
	   defined($param[5]) ? $param[5] : $WIDTH
	   ];
}
sub home {			# 
  my $self = shift;		
  $self->[0] = $X0;
  $self->[1] = $Y0;
  $self->[2] = $ORIENT;
}
sub raise {
    my $self = shift;	       
    $self->[3] = 0;
}
sub lower {
    my $self = shift;	       
    $self->[3] = 1;
}
sub turn {
    my $self = shift;		# new orientation
    $self->[2] = ($self->[2] + $_[0]) % 360;
}
sub right {
    my $self = shift;		# turn right
    $self->[2] = ($self->[2] + $_[0]) % 360;
}
sub left {
    my $self = shift;		# turn left
    $self->[2] = ($self->[2] - $_[0]) % 360;
}
sub color {
    my $self = shift;
    if (defined $_[0]) {
      $self->[4] = $_[0];
    } else {
      $self->[4];
    }
}
sub width {
    my $self = shift;
    if (defined $_[0]) {
      $self->[5] = $_[0];
    } else {
      $self->[5];
    }
}
sub cape {
    my $self = shift;
    if (defined $_[0]) {
      $self->[2] = $_[0] % 360;
    } else {
      $self->[2];
    }
}
sub where {
    my $self = shift;		# give the current position
    ($self->[0], $self->[1]);
}
sub state {
  my $self = shift;		# return turtle characteristics
  if (defined $_[0]) {  
    my $param, $i;
    while($#_ != -1) {
      $param = shift;
      if ($param eq '-fill')  {
	$self->[4] = shift;
      } elsif ($param eq '-width') {
	$self->[5] = shift;
      } else {
	$self->[$i++] = $param;
      }
    }
  } else {
    @{$self}[0..5];
  }
}
sub backward { $_[0]->forward(-$_[1]) }
sub forward {			# return 0 if outside of the plane???
    my $self = shift;
    my $step = $_[0];
    my $cape = $self->[2];
				# line to draw
    my $x = $step * cos($self->[2]*$K);
    my $y = $step * sin($self->[2]*$K);
				# Origin
    my $xo = $self->[0];
    my $yo = $self->[1];
				# new position
    $self->[0] = $x + $xo;		
    $self->[1] = $y + $yo;
    if ($self->[3] == 1) {
	my @data = (int($xo), int($yo), int($self->[0]), int($self->[1]));
	if (defined $ground) {
	    $ground->draw('line', @data, 
			  -fill => $self->[4],
			  -width => $self->[5],
			 );
	} else {
	    @data, $self->[4], $self->[5];
	}
    }
}
__END__





