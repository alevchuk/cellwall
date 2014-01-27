# vim:sw=4 ts=4
# $Id: Species.pm 33 2004-06-10 22:25:48Z laurichj $

=head1 NAME

Cellwall::Species

=head1 DESCRIPTION

A Cellwall::Species represents a species.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Species;
use Bio::Species;
use Carp;
use Cellwall::Root;
use vars qw/@ISA @ACCESSORS %OBJECTS/;
use strict;

@ISA = qw/Bio::Species Cellwall::Root/;
@ACCESSORS = qw/id updated/;
Cellwall::Species->mk_accessors(@ACCESSORS);

=head2 new

 Title   : new
 Usage   : $species = new Cellwall::Species()
 Function: Creates a Cellwall::Species
 Returns : a Cellwall::Species
 Args    :

=cut

sub new
{
	my($class, %args) = @_;

	if( my $species = get_Species( $args{-genus}, $args{-species} ) ) {
		# Check to see if we've gotten an id to tack on, and while
		# we're at it make sure they match if there's one there
		if(defined($args{-id}) and defined($species->id())) {
			throw Error::Simple('species object has an id which doesnt match the id we were called with') unless $species->id() == $args{-id};
		} elsif(defined($args{-id})) {
			$species->id( $args{-id} );
		}
		
		return $species;
	}

	# so, lets make one:
	my $self = $class->SUPER::new();

	# and setup the values:
	$self->id( $args{-id} );
	$self->genus( $args{-genus} );
	$self->species( $args{-species} );
	$self->sub_species( $args{-sub_species} );
	$self->common_name( $args{-common_name} );
	
	# Add it to the cache
	add_Species( $self );

	return $self;
}

=head2 get_Species

 Title   : get_Species
 Usage   : my $species = Cellwall::Species::get_Species($genus, $species)
 Function: returns the species from the cache or undef if not there
 Returns : a Cellwall::Species
 Args    : the genus and species

=cut

sub get_Species
{
	my($genus, $species) = @_;

	# Make the key
	my $key = $genus . $species;

	# return it if it's there
	return $OBJECTS{ $key } if defined $OBJECTS{ $key };
	return undef;
}

=head2 add_Species

 Title   : add_Species
 Usage   : Cellwall::Species::add_Species($genus, $species)
 Function: add a species object to the cache
 Returns : 
 Args    : a Cellwall::Species

=cut

sub add_Species
{
	my($species) = @_;
	$OBJECTS{ $species->genus() . $species->species() } = $species;
}

# Overload the validate_* information to cope with the fact that ESTs
# can have bad names sometimes.

sub validate_species_name
{
	return 1;
}

sub validate_name
{
	return 1;
}

1;
