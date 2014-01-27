# vim:sw=4 ts=4
# $Id: genbank.pm 19 2004-04-30 21:49:06Z laurichj $

=head1 NAME

Cellwall::Database::genbank - genbank flatfile interface

=head1 DESCRIPTION

this module accesses an index genbank flat file(s).

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Database::genbank;
use Bio::Index::GenBank;
use Error qw/:try/;
use Cellwall::Species;
use Cellwall::Sequence;
use Date::Format;              
use base qw/Cellwall::Database/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/index date/;
Cellwall::Database::genbank->mk_accessors(@ACCESSORS);

sub new
{
	my $self = Cellwall::Root::new(@_);


	throw Error::Simple('Cellwall::Database::genbank needs an index')
		unless defined $self->index();

	$self->{_index} = new Bio::Index::GenBank(
		-filename => $self->index(),
	);

	# Set the databases date based on the last modified time of the
	# index, then convert it into the numerical format used by MySQL
	$self->date(time2str("%Y%m%d%H%M%S", (stat $self->index())[9]));
	return $self;
}

sub get_Sequence
{
	my $self = shift @_;

	# If we have more than one sequence then try each ID until one is
	# found

	foreach my $id (@_) {
		# Get the sequence
		my $seq = $self->{_index}->fetch($id);

		if(!defined( $seq )) {
			$self->debug(4, "Couldn't get $id, trying next.");
			next;
		}

		# Just rebless the sequence
		bless $seq, 'Cellwall::Sequence';

		# set its source db
		$seq->db( $self );
	
		# Since we cache the species we need to build one:
		my @classification = $seq->species()->classification();
		$seq->species(
			new Cellwall::Species(
				-genus       => $seq->species()->genus(),
				-species     => $seq->species()->species(),
				-sub_species => $seq->species()->sub_species(),
				-common_name => $seq->species()->common_name(),
			)
		);
		$seq->species()->classification( @classification );

		return $seq;
	}

	return undef;
}

sub params
{
	my($self) = @_;
	return ( 'index' => $self->index() )
}

1;
