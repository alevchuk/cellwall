# vim:sw=4 ts=4
# $Id: Sequence.pm 103 2005-02-11 05:22:22Z laurichj $

=head1 NAME

Cellwall::Executor

=head1 DESCRIPTION

Cellwall::Executor is a simple abstraction to "distributed" execution systems
allowing the Cellwall database to be built.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Executor;
use base qw/Cellwall::Root/;
use Error qw/:try/;
use vars qw/@ISA @ACCESSORS/;
use strict;

@ACCESSORS = qw/type/;
Cellwall::Executor->mk_accessors(@ACCESSORS);

=head2 new

 Title   : new
 Usage   : $exec = new Cellwall::Executor(...)
 Function: Create an executor object
 Returns : a Cellwall::Executor::* object
 Args    :

=cut

sub new
{
	my $class = shift(@_);
	my %args = @_;
	my $type = lc($args{-type}) || throw Error::Simple("Cellwall::Executor::new needs a type");

	my $name = "Cellwall::Executor::$type";
	my $mod = $class->_load_module($name);

	eval "require $name";
	throw Error::Simple("unable to load $name\: $@") if $@;

	return $name->new(@_);
}

1;
