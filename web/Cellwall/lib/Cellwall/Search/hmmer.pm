# vim:sw=4 ts=4
# $Id: hmmer.pm 93 2004-08-24 15:48:28Z laurichj $

package Cellwall::Search::hmmer;
use Carp;
use base qw/Cellwall::Search/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/file cutoff/;
Cellwall::Search::hmmer->mk_accessors(@ACCESSORS);

sub new
{
	return Cellwall::Root::new(@_);
}

sub execute
{
}

sub params
{
	my($self) = @_;
	return (
		file => $self->file(),
	);
}

1;
