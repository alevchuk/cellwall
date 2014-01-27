# vim:sw=4 ts=4
# $Id: Family.pm 90 2004-08-09 15:38:59Z laurichj $

=head1 NAME

Cellwall::Family

=head1 DESCRIPTION

This object handles accessing and modifying all data regaurding a family.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Family;
use Carp;
use base qw/Cellwall::Root/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/id rank name abrev group_id updated/;
Cellwall::Family->mk_accessors(@ACCESSORS);

=head2 add_Sequence

 Title   : add_Sequence
 Usage   : $family->add_Sequence($seq);
 Function: adds a sequence to a family
 Returns :
 Args    : A sequence

=cut

sub add_Sequence
{
	my($self, $sequence) = @_;
	throw Error::Simple('argument must be a Cellwall::Sequence')
		unless defined($sequence) and $sequence->isa('Cellwall::Sequence');
	
	$self->_add_Index('sequence', $sequence,
		accession => $sequence->accession_number(),
	);
	$sequence->family($self);
}

sub add_all_Sequences
{
	my($self, @sequences) = @_;

	foreach my $sequence (@sequences) {
		$self->_add_Index('sequence', $sequence,
			accession => $sequence->accession_number(),
		);
		$sequence->family($self);
	}
}


=head2 get_all_Sequences

 Title   : get_all_Sequences
 Usage   : @seqs = $family->get_all_Sequences();
 Function: Get the sequences in the group
 Returns : an array of Cellwall::Sequence objects
 Args    : 

=cut

sub get_all_Sequences
{
	my($self) = @_;
	return $self->_get_Array('sequence');
}

=head2 get_all_Proteins

 Title   : get_all_Proteins
 Usage   : @seqs = $family->get_all_Proteins();
 Function: Get the proteins in the group
 Returns : an array of sequnce objects
 Args    : 

=cut

sub get_all_Proteins
{
	my($self) = @_;
	my @proteins;

	foreach my $seq ($self->get_all_Sequences()) {
		push(@proteins, $seq->get_all_Proteins());
	}

	return wantarray ? @proteins : \@proteins;
}

=head2 group

 Title   : group
 Usage   : $group = $family->group( $new );
 Function: access the group object for a family
 Returns : a Cellwall::Group object
 Args    : optional new group

=cut

sub group
{
	my ($self, $new) = @_;
	if( $new and $new->isa('Cellwall::Group')) {
		# Set the group reference
		$self->{_group} = $new;
	} elsif( $new ) {
		# Try to get it from Cellwall if its not an object
		$new = $Cellwall::singleton->get_Group( name => $new );

		# Throw an error if we don't have one
		throw Error::Simple("unable to find group object: $_[1]")
			unless defined $new;

		# Set the group reference
		$self->group( $new );
	} elsif( scalar(@_) == 2 ) {
		# Setting the group to undef
		$self->{_group} = $new;
	}

	# Now, lets see if we have a group id without a group
	if( !defined($self->{_group}) and defined( $self->group_id() ) ) {
		# Try to grab the group
		$self->{_group} = $Cellwall::singleton->get_Group( id => $self->group_id() );
	}
	
	# Return the group
	return $self->{_group};
}

sub add_SubFamily
{
	my($self, @subfamilies) = @_;
	push(@{$self->{_sub_families}}, @subfamilies);
}

sub get_SubFamilies
{
	my($self) = @_;
	return wantarray ? () : [] if not defined $self->{_sub_families};
	return wantarray ? @{$self->{_sub_families}} : $self->{_sub_families};
}

1;
