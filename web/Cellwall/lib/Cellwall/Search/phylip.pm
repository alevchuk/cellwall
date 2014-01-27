# vim:sw=4 ts=4
# $Id: blast.pm 9 2004-04-06 01:44:31Z laurichj $

package Cellwall::Search::phylip;
use Bio::AlignIO;
use Bio::Tools::Run::Phylo::Phylip::DrawGram;
use Bio::Tools::Run::Phylo::Phylip::Neighbor;
use Bio::Tools::Run::Phylo::Phylip::ProtDist;
use Bio::Tools::Run::Phylo::Phylip::Retree;
use Bio::TreeIO;
use Carp;
use base qw/Cellwall::Search/;
use vars qw/@ACCESSORS/;
use strict;

# Set the phylipdir to the Debian default.
$ENV{PHYLIPDIR} = '/usr/lib/phylip/bin' unless defined $ENV{PHYLIPDIR};

@ACCESSORS = qw/protdist neighbor retree/;
Cellwall::Search::phylip->mk_accessors(@ACCESSORS);

sub new
{
	my $self = Cellwall::Root::new(@_);

	# Make the factories
	$self->protdist( new Bio::Tools::Run::Phylo::Phylip::ProtDist() );
	$self->neighbor( new Bio::Tools::Run::Phylo::Phylip::Neighbor( -type => 'NJ' ) );
	$self->retree( new Bio::Tools::Run::Phylo::Phylip::Retree() );
	
	return $self;
}

sub execute
{
	my($self) = @_;

	# algin each group in the cellwall
	foreach my $group ($Cellwall::singleton->get_all_Groups()) {
		$self->search_Group($group);
	}
}

sub search_Group
{
	my($self, $group) = @_;

	# Search each family
	foreach my $family ($group->get_all_Children()) {
		$self->search_Family($family) if $family->isa('Cellwall::Family');
	}
}

sub search_Family
{
	my($self, $family) = @_;

	my @proteins = $family->get_all_Proteins();

	# Do them all
	$self->search_Align($family->id()) unless scalar(@proteins) < 3;

	# Sort the proteins into their sources
	my %sources;
	foreach my $protein (@proteins) {
		push(@{$sources{ $protein->database_id() }}, $protein);
	}

	# Run each source
	foreach my $source (keys(%sources)) {
		next if scalar(@{$sources{$source}}) < 3;
		$self->search_Align(join('.', $family->id(), $source));
	}
}

sub search_Align
{
	my($self, $base) = @_;

	# Don't do anything if there is an alignment file
	return if -f $self->treefile( $base ) and not -z $self->treefile( $base );

	my $orig_align = Cellwall::Search::clustalw->get_Alignment($base);

	# Transform the alignment
	my( $align, $ids ) = $self->translate_Alignment($orig_align);

	# Make the matrix
	my($matrix) = $self->protdist()->run($align);

	# Make the tree
	my($tree) = $self->neighbor()->run($matrix);

	# Retree
	$tree = $self->retree()->midpoint($tree);
	$self->retree()->cleanup();

	# Translate the tree back into the real IDS
	$self->translate_Tree($tree, $ids);

	# Write out the tree
	$self->save_Tree( $base, $tree );
}

sub translate_Alignment
{
	my($self, $align) = @_;

	# Make a new alignment
	my $newalign = new Bio::SimpleAlign();
	my @ids;

	# Copy and translate each 
	foreach my $sequence ($align->each_seq()) {
		# get the next id number
		push(@ids, $sequence->id());

		# Make a copy
		my $newseq = new Bio::LocatableSeq(
			-id    => scalar(@ids),
			-seq   => $sequence->seq(),
			-start => $sequence->start(),
			-end   => $sequence->end(),
		);

		# Add to the alignment:
		$newalign->add_seq($newseq);
	}

	# This returns an alignment and an arrayref to the
	# id table
	return( $newalign, \@ids );
}

sub translate_Tree
{
	my($self, $tree, $ids) = @_;
	$self->translate_Node($tree->get_root_node(), $ids);
}

sub translate_Node
{
	my($self, $node, $ids) = @_;

	if( $node->is_Leaf() ) {
		# Only leaves are sequences
		$node->id( $ids->[ $node->id() - 1] );
	} else {
		# Transform all the descendents
		foreach my $child ($node->each_Descendent()) {
			$self->translate_Node($child, $ids);
		}
	}
}

sub treefile
{
	my($self, $base) = @_;
	return $Cellwall::singleton->search_File('Tree', $base . '.dnd');
}

sub save_Tree
{
	my($self, $base, $tree) = @_;

	# Make the IO
	my $out = new Bio::TreeIO(
		-format => 'newick',
		-file   => '>' . $self->treefile( $base ),
	);

	# Write the tree
	$out->write_tree( $tree );
}

sub get_Tree
{
	my($self, $family) = @_;

	# Make the IO
	my $in = new Bio::TreeIO(
		-format => 'newick',
		-file   => $self->treefile( $family ),
	);

	return $in->next_tree();
}

1;
