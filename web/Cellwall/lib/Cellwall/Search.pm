# vim:sw=4 ts=4
# $Id: Search.pm 12 2004-04-09 01:09:15Z laurichj $

=head1 NAME

Cellwall::Database

=head1 DESCRIPTION

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Search;
use Carp;
use base qw/Cellwall::Root/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/id genome_id database_id type name query/;
Cellwall::Search->mk_accessors(@ACCESSORS);

=head2 new

 Title   : new
 Usage   : $search = new Cellwall::Search(...)
 Function: Creates a search object, this function loads a module
           to handle the specified search type and returnes an
		   object of that type.
 Returns : a Cellwall::Search::* object
 Args    :

=cut

sub new
{
	my $class = shift(@_);
	my %args = @_;
	my $type = lc($args{-type}) || throw Error::Simple("Cellwall::Search::new needs a type");
	my $name = "Cellwall::Search::$type";

	# Load the module
	$class->_load_module($name);

	# Make a new object
	return $name->new(@_);
}

=head2 execute

 Title   : execute
 Usage   : $search->execute()
 Function: Execute a search
 Returns : 
 Args    :

 This is a virtual function that must be provided by each
 Search module.

=cut

=head2 id

 Title   : id
 Usage   : $search->id($new)
 Function: get the database id for a search object
 Returns : the id
 Args    : an optional new id

 This is a generic accessor/mutator.

=cut

=head2 genome_id

 Title   : genome_id
 Usage   : $search->genome_id($new)
 Function: get the database genome_id for a search object
 Returns : the genome_id
 Args    : an optional new genome_id

 This is a generic accessor/mutator.

=cut

=head2 database_id

 Title   : database_id
 Usage   : $search->database_id($new)
 Function: get the database database_id for a search object
 Returns : the database_id
 Args    : an optional new database_id

 This is a generic accessor/mutator.

=cut

=head2 type

 Title   : type
 Usage   : $search->type($new)
 Function: get the type for a search object
 Returns : the type
 Args    : an optional new type

 This is a generic accessor/mutator.

=cut

=head2 query

 Title   : name
 Usage   : $search->name($new)
 Function: get the name for a search object
 Returns : the name
 Args    : an optional new name

 This is a generic accessor/mutator.

=cut

=head2 query

 Title   : query
 Usage   : $search->query($new)
 Function: get the query for a search object
 Returns : the query
 Args    : an optional new query

 This is a generic accessor/mutator.

=cut

=head2 database

 Title   : database
 Usage   : $search->database($new)
 Function: get the database for a search object
 Returns : the database
 Args    : an optional new database

=cut

sub database
{
	my ($self, $new) = @_;
	if( $new and $new->isa('Cellwall::Database')) {
		# Set the database reference
		$self->{_database} = $new;
	} elsif( $new ) {
		# Try to get it from Cellwall if its not an object
		$new = $Cellwall::singleton->get_Database( name => $new );

		# Throw an error if we don't have one
		throw Error::Simple("unable to find database object: $_[1]")
			unless defined $new;

		# Set the database reference
		$self->database( $new );
	} elsif( scalar(@_) == 2 ) {
		# Setting the database to undef
		$self->{_database} = $new;
	}
	
	# Now, lets see if we have a db id without a db
	if( !defined($self->{_database}) and defined( $self->database_id() ) ) {
		# Try to grab the database
		$self->{_database} = $Cellwall::singleton->get_Database( id => $self->database_id() );
	}

	# Return the database
	return $self->{_database};
}

=head2 genome

 Title   : genome
 Usage   : $search->genome($new)
 Function: get the genome for a search object
 Returns : the genome
 Args    : an optional new genome

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
		$self->genome( $Cellwall::singleton->get_Genome( id => $self->genome_id() ) );
	}
	
	# Return the genome
	return $self->{_genome};
}

sub params
{
	return ();
}

1;
