# vim:sw=4 ts=4
# $Id: Database.pm 102 2005-02-11 05:15:45Z laurichj $

=head1 NAME

Cellwall::Database - web, sql and flatfile interface to a database

=head1 DESCRIPTION

Objects inheriting from Cellwall::Database are used to hold information
about a database. The Cellwall::Database::blast is a container to hold
data about a blastable database, Cellwall::Database::hmmer containes
information about a hmmer database ( a pfam database ).

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Database;
use Carp;
use base qw/Cellwall::Root/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/id genome_id type name/;
Cellwall::Database->mk_accessors(@ACCESSORS);

=head2 new

 Title   : new
 Usage   : $db = new Cellwall::Databse(...)
 Function: Creates a database object, this function loads a module
           to handle the specified database type and returnes an
		   object of that type.
 Returns : a Cellwall::Database::* object
 Args    :

=cut

sub new
{
	my $class = shift(@_);
	my %args = @_;
	my $type = lc($args{-type}) || throw Error::Simple("Cellwall::Database::new needs a type");

	my $name = "Cellwall::Database::$type";
	my $mod = $class->_load_module($name);

	print "$name\n";
	eval "require $name";
	throw Error::Simple("unable to load $name\: $@") if $@;

	return $name->new(@_);
}

=head2 genome

 Title   : genome
 Usage   : $genome = $gb->genome( $new );
 Function: access the genome object for a database
 Returns : a Cellwall::Genome object
 Args    : optional new genome

=cut

sub genome
{
	my ($self, $new) = @_;
	if( $new and $new->isa('Cellwall::Genome')) {
		# Set the genome reference
		$self->{_genome} = $new;
	} elsif( $new ) {
		# Try to get it from Cellwall if its not an object
		$new = $Cellwall::singleton->get_Genome( name => $new );

		# Throw an error if we don't have one
		throw Error::Simple("unable to find genome object: $_[1]")
			unless defined $new;

		# Set the genome reference
		$self->genome( $new );
	} elsif( scalar(@_) == 2 ) {
		# Setting the genome to undef
		$self->{_genome} = $new;
	}

	# Now, lets see if we have a genome id without a genome
	if( !defined($self->{_genome}) and defined( $self->genome_id() ) ) {
		# Try to grab the genome
		$self->{_genome} = $Cellwall::singleton->get_Genome( id => $self->genome_id() );
	}
	
	# Return the genome
	return $self->{_genome};
}

1;
