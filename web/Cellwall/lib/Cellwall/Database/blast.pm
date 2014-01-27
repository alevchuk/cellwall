# vim:sw=4 ts=4
# $Id: blast.pm 102 2005-02-11 05:15:45Z laurichj $

=head1 NAME

Cellwall::Database::blast - blast database interface

=head1 DESCRIPTION

This accesses a blastable database.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Database::blast;
use Carp;
use base qw/Cellwall::Database/;
use Date::Format;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/file alphabet updated/;
Cellwall::Database::blast->mk_accessors(@ACCESSORS);

sub new
{
	my $self = Cellwall::Root::new(@_);

	# Try to set the date
	if( $self->file() and $self->alphabet() ) {
		# Ok, now get the name of the database
		my $file = $self->file();

		if( $self->alphabet() eq 'nucleotide' ) {
			$file .= ".nsq";
		} elsif( $self->alphabet() eq 'protein' ) {
			$file .= ".psq";
		}

		$self->updated(  time2str("%Y%m%d%H%M%S", (stat $file)[9]) ) if stat $file;
	}
	
	
	return $self;
}

sub params
{
	my($self) = @_;
	return ( file => $self->file(), alphabet => $self->alphabet() );
}

1;
