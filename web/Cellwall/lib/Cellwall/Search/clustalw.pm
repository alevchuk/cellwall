# vim:sw=4 ts=4
# $Id: blast.pm 9 2004-04-06 01:44:31Z laurichj $

package Cellwall::Search::clustalw;
use Bio::AlignIO;
use Bio::Graphics;
use Bio::Tools::Run::Alignment::Clustalw;
use Carp;
use base qw/Cellwall::Search/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/factory/;
Cellwall::Search::clustalw->mk_accessors(@ACCESSORS);

sub new
{
	my $self = Cellwall::Root::new(@_);

	# Build the clustalw factory
	$self->factory( new Bio::Tools::Run::Alignment::Clustalw( QUIET => 1 ) );

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
		$self->align_Family($family) if $family->isa('Cellwall::Family');
	}
}

sub search_Family
{
	my($self, $family) = @_;
	$self->align_Family($family);
}

sub align_Family
{
	my($self, $family) = @_;

	my @proteins = $family->get_all_Proteins();
	$_->display_name( $_->accession_number )
		foreach grep { not defined $_->display_name() } @proteins;

	# Make the base file name
	my $file = $Cellwall::singleton->search_File('Align', $family->id());

	# Make the full family alignment:
	$self->align_Proteins($file, \@proteins);

	# Sort the proteins into their sources
	my %sources;
	foreach my $protein (@proteins) {
		push(@{$sources{ $protein->database_id() }}, $protein);
	}

	# Align each source
	foreach my $source (keys(%sources)) {
		$self->align_Proteins(join('.', $file, $source), $sources{$source});
	}
}

sub align_Proteins
{
	my($self, $file, $proteins) = @_;

	# Only align if 2 or more protins
	return if scalar(@$proteins) < 2;

	# Don't align if there is an alignment file
	my $align;
	if(not -f "$file.mul") {

		# Make the alignment
		$align = $self->factory()->align( $proteins );

		# Save it to a file
		my $out = new Bio::AlignIO(
			-format => 'fasta',
			-file   => ">$file.mul"
		);
		$out->write_aln( $align );
		$out->close();
	} else {
		
		# Read the alignment in
		my $in = new Bio::AlignIO(
			-format => 'fasta',
			-file   => "$file.mul"
		);
		$align = $in->next_aln();
	}

	# Make the panel
	my $panel = $self->build_Panel($align);

	# Make the background transparent
	$panel->gd()->transparent($panel->bgcolor());

	# Write the panel
	open(CLUSTALW_IMAGE, ">$file.png");
	print CLUSTALW_IMAGE $panel->png();
	close CLUSTALW_IMAGE;
}

sub build_Panel
{
	my($self, $align) = @_;

	# Make the panel
	my $panel = new Bio::Graphics::Panel(
		-length     => $align->length(),
		-key_style  => 'between',
		-width      => 700,
		-pad_top    => 5,
		-pad_left   => 10,
		-pad_right  => 10,
		-pad_bottom => 5,
		-bgcolor    => 'white',
	);

	# This feature spans the alignment for the ruler
	my $entire = new Bio::SeqFeature::Generic(
		-start => 1,
		-end   => $align->length(),
	);

	# Add the ruler
	$panel->add_track(
		$entire,
		-glyph   => 'arrow',
		-bump    => 0,
		-double  => 1,
		-tick    => 2,
		-fbcolor => 'black',
	);

	# Add each sequence in the alignment
	foreach my $seq ($align->each_seq()) {
		my $track = $panel->add_track(
			-glyoh      => 'graded_segments',
			-label      => 1,
			-bump    => 0,
			-connector  => 'dashed',
			-bgcolor    => 'blue',
			-font2color => 'red',
		);

		# make a feature to hold the chunks
		my $feature = new Bio::SeqFeature::Generic(
			-display_name => $seq->display_name(),
		);

		# Add all the conserved sections
		my $start = 1;
		foreach my $chunk ( grep { $_ } split(/(\.{5,})/o, $seq->seq()) ) {
			if( $chunk !~ /^\.+$/o ) {
				# Add a conserved section
				my $sub = new Bio::SeqFeature::Generic(
					-start => $start,
					-end   => $start + length($chunk) - 1,
					-score => sqrt( length($chunk) ),
				);

				$feature->add_sub_SeqFeature($sub, 'EXPAND');
			}

			# increment start
			$start += length($chunk);
		}

		# Add the row
		$track->add_feature($feature);
	}
	
	return $panel;
}

sub get_Alignment
{
	my($self, $base) = @_;

	# Make the base file name
	my $file = sprintf('%s.mul', $Cellwall::singleton->search_File('Align', $base));

	if( defined $Cellwall::parallel ) {
		# Sleep until there is a file to read
		sleep(5) until -f $file;
	}

	# Open the file
	my $in = new Bio::AlignIO(
		-format => 'fasta',
		-file   => $file,
	);

	return $in->next_aln();
}

1;

