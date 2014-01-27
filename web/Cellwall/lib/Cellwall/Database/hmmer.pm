# vim:sw=4 ts=4
# $Id: hmmer.pm 92 2004-08-09 15:40:04Z laurichj $

=head1 NAME

Cellwall::Database::hmmer - hmm database interface

=head1 DESCRIPTION

access the models in an hmm database

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Database::hmmer;
use Carp;
use base qw/Cellwall::Database/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/file/;
Cellwall::Database::hmmer->mk_accessors(@ACCESSORS);

sub new
{
	return Cellwall::Root::new(@_);
}

sub params
{
	my($self) = @_;
	return ( 'file' => $self->file() )
}

1;
