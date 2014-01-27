# vim:sw=4 ts=4
# $Id: Genome.pm 102 2005-02-11 05:15:45Z laurichj $

=head1 NAME

Cellwall::Genome - interface for a genome's resources

=head1 DESCRIPTION

Since it is useful to have multiple databases holding differeing information
about a genome (aka: genbank files and blastable databases) the genome
class holds and provides an interface for these databases.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Genome;
use Carp;
use base qw/Cellwall::Root/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/id name/;
Cellwall::Genome->mk_accessors(@ACCESSORS);

=head2 new

 Title   : new
 Usage   : $genome = new Cellwall::Genome(...)
 Function: Creates a genome object
 Returns : a Cellwall::Genome object
 Args    :

=cut

# new is inheritited, I'm lazy.

=head2 add_Database

 Title   : add_Database
 Usage   : $genome->add_Database($db)
 Function: adds a database to this genome
 Returns : 
 Args    : a Cellwall::Database object

=cut

sub add_Database
{
	my($self, $db) = @_;
	throw Error::Simple('argument must be a Cellwall::Database')
		unless defined($db) and $db->isa('Cellwall::Database');
	
	$self->_add_Index('database', $db,
		name => lc($db->name()),
		type => lc($db->type()),
	);
}

=head2 get_Database

 Title   : get_Database
 Usage   : $genome->get_Database(type => 'blast')
 Function: retrieves a database of a given type
 Returns : a Cellwall::Database
 Args    : either type => $type or name => $name

=cut

sub get_Database
{
	my($self, $field, $value) = @_;
	throw Error::Simple('must have a field and a value')
		unless defined($field) and defined($value);
	
	return $self->_get_Index('database', $field => lc($value) );
}

=head2 get_all_Databases

 Title   : get_all_Databases
 Usage   : $genome->get_all_Databases()
 Function: gets an array of databases
 Returns : an array Cellwall::Databases
 Args    : 

=cut

sub get_all_Databases
{
	my($self) = @_;
	return $self->_get_Array('database');
}

=head2 get_Sequence

 Title   : get_Sequence
 Usage   : $genome->get_Sequence()
 Function: gets all the data known about a sequence from
           the databases in the genome.
 Returns : a Cellwall::Sequence
 Args    : 

 For now, this simply returns the results of get_Sequence
 from the first database that can find sequences.
 
=cut

sub get_Sequence
{
	my($self, $id) = @_;

	foreach my $db ($self->get_all_Databases()) {
		return $db->get_Sequence($id) if $db->can('get_Sequence');
	}
	$self->debug(0, "asked to get_Sequence on a genome which contains no sequence databases " . $self->name() );
	return undef;
}

1;
