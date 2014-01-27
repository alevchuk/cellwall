# vim:sw=4 ts=4
# $Id: Group.pm 27 2004-05-20 06:04:15Z laurichj $

=head1 NAME

Cellwall::Group

=head1 DESCRIPTION

A Group object is a container and organization unit which contains Families and
other groups.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Group;
use Carp;
use base qw/Cellwall::Root/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/id parent_id rank name updated/;
Cellwall::Group->mk_accessors(@ACCESSORS);

=head2 add_Child

 Title   : add_Child
 Usage   : $group->add_Child($fam);
 Function: adds a child to a group
 Returns :
 Args    : A family or another group

=cut

sub add_Child
{
	my($self, $child) = @_;
	
	$self->_add_Index('children', $child, 
		name  => lc $child->name(),
	);
	$child->group($self);
}

=head2 get_all_Children

 Title   : get_all_Children
 Usage   : @families = $group->get_all_Children();
 Function: Get the children in the group
 Returns : an array of child objects
 Args    : 

=cut

sub get_all_Children
{
	my($self) = @_;
	return $self->_get_Array('children');
}

=head2 group

 Title   : group
 Usage   : $parent = $group->parent( $new );
 Function: access the parent object for a group
 Returns : a Cellwall::Group object
 Args    : optional new parent

 This should not be called directly, use parent

=cut

sub group
{
	parent(@_);
}

=head2 parent

 Title   : parent
 Usage   : $parent = $group->parent( $new );
 Function: access the parent object for a group
 Returns : a Cellwall::Group object
 Args    : optional new parent

=cut

sub parent
{
	my ($self, $new) = @_;
	if( $new and $new->isa('Cellwall::Group')) {
		# Set the parent reference
		$self->{_parent} = $new;
	} elsif( $new ) {
		# Try to get it from Cellwall if its not an object
		$new = $Cellwall::singleton->get_Group( name => $new );

		# Throw an error if we don't have one
		throw Error::Simple("unable to find parent object: $_[1]")
			unless defined $new;

		# Set the parent reference
		$self->parent( $new );
	} elsif( scalar(@_) == 2 ) {
		# Setting the parent to undef
		$self->{_parent} = $new;
	}

	# Now, lets see if we have a parent id without a parent
	if( !defined($self->{_parent}) and defined( $self->parent_id() ) ) {
		# Try to grab the parent
		$self->{_parent} = $Cellwall::singleton->get_Group( id => $self->parent_id() );
	}
	
	# Return the parent
	return $self->{_parent};
}

1;
