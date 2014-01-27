# vim:sw=4 ts=4
# $Id: blast.pm 133 2005-07-08 20:04:20Z laurichj $

package Cellwall::Search::blast;
use Bio::Graphics;
use Bio::SearchIO;
use Bio::SeqFeature::Generic;
use Bio::Tools::Run::StandAloneBlast;
use Carp;
use Date::Format;
use base qw/Cellwall::Search/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/file alphabet cutoff count processors/;
Cellwall::Search::blast->mk_accessors(@ACCESSORS);

# Hash to figure out what program to use
my %program = (
	protein => {
		protein    => 'blastp',
		nucleotide => 'tblastn',
	},
	nucleotide => {
		protein    => 'blastx',
		nucleotide => 'blastn',
	},
);

# This is here so we don't goto Cellwall::Search::new
sub new
{
	return Cellwall::Root::new(@_);
}

sub genome
{
	my($self, $genome) = @_;

	# Return if we aren't trying to set anything
	return $self->SUPER::genome() unless scalar @_ == 2;

	# Call the Setter from Cellwall::Search
	$genome = $self->SUPER::genome($genome);

	# Make sure there is a blast database
	my $db = $genome->get_Database( type => 'blast' );

	# There was a blastable database, so set and return
	if(defined( $db )) {
		$self->database( $db );
		return $genome;
	}

	# Raise an exception
	throw Bio::Root::Exception('Blast search object needs a blastable database');
}

sub execute
{
	my($self) = @_;

	# Search each group in the cellwall
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

	# Search each sequence
	foreach my $seq ($family->get_all_Sequences()) {
		$self->search_Sequence($seq);
	}
}

sub search_Sequence
{
	my($self, $seq) = @_;

	# Makesure the query is either protein or nucleotide
	throw Bio::Root::Exception('invalid blast search query tag') unless exists($program{ $self->query() });

	# Build a factory
	my $factory = new Bio::Tools::Run::StandAloneBlast(
		program  => $program{$self->query()}->{$self->database()->alphabet()},
		database => $self->database()->file(),
		outfile  => $Cellwall::singleton->search_File('Blast', $seq->accession_number() . ',' . $self->database()->name()),
		e        => $self->cutoff(),
		v        => $self->count(),
		b        => $self->count(),
		a        => $self->processors() || 1,
	);

	my @sequences;
	if($self->query() eq "protein") {
		# Get each of the proteins
		push(@sequences, $seq->get_all_Proteins());
	} elsif($self->query() eq "nucleotide") {
		push(@sequences, $seq) if $seq->alphabet() eq "nucleotide";
	}

	# Run the search on each sequence
	my $searchio;
	
	# Check the timestamp of the blast file:
	my $lastblast = 0;
	if( -f $factory->outfile() ) {
		$lastblast = time2str("%Y%m%d%H%M%S", (stat $factory->outfile())[9]);
	}

	if( $lastblast > $self->database()->updated() ) {
		$searchio = new Bio::SearchIO(
			-format => 'blast', -file => $factory->outfile()
		);

		while( my $result = $searchio->next_result() ) {
			$self->save_results($seq->primary_id(), $result);
		}
		# We don't need to blast
		return;
	} else {
		# Search a sequence
		$self->debug(1, "Running: " .
		                $program{$self->query()}->{$self->database()->alphabet()} .
		                " against: " . $self->database()->file()
		);

		# Run the blast
		while(1) {
			try {
				$searchio = $factory->blastall(@sequences);
				last;
			} except {
				my $E = shift;
				$self->debug(0, "Error running blast, retrying: $E");
			};
		}
	
		while( my $result = $searchio->next_result() ) {
			$self->save_results($seq->primary_id(), $result);
		}
	}
}

sub insert_File
{
	my($self, $id, $file) = @_;

	# read in the file
	my $in = new Bio::SearchIO(
		-format => 'blast',
		-file   => $file,
	);

	# Save the results
	while( my $result = $in->next_result() ) {
		$self->save_results($id, $result);
	}
}

sub save_results
{
	my($self, $query_id, $result) = @_;

	$query_id = $query_id->primary_id() if ref $query_id;

	my $get_hsp_id = $Cellwall::singleton->sql()->prepare("SELECT id FROM blast_hsp WHERE query = ? AND hit = ?");

	# Loop through each hit
	while( my $hit = $result->next_hit() ) {
		# Get the sequence, sometimes they have multiple IDs seperated
		# with pipes, try to get any of them
		my $seq = $self->genome()->get_Sequence( split( /\|/o, $hit->accession() ) );

		# see if we have a sequence
		unless($seq) {
			print STDERR "Unable to fetch: ", $hit->accession(), "\n";
			next;
		}

		# Get the hit's id number or add and get the number
		my $hit_id = $self->get_HitId($seq);
		
		# We only want the best hsp between a pair, so lets get that one,
		# based on the E value.
		my @hsps = $hit->hsps();
		my $hsp;
		if( scalar(@hsps) > 1 ) {
			($hsp) = sort { $a->evalue() <=> $b->evalue() } ($hit->hsps());
		} else {
			$hsp = $hsps[0];
		}

		if( defined $hsp ) {
			# Add that hsp:
			$self->add_HSP($query_id, $hit_id, $hsp);
		} else {
			$self->debug("unable to locate hsp for $query_id => $hit_id");
		}
	}
}

sub get_HitId
# This gets the id for a hit or adds the hit and returns the id
{
	my($self, $hit) = @_;

	# Get the queries
	my $hit_get_id = $Cellwall::singleton->sql()->prepare("SELECT id FROM blast_hit WHERE accession = ?");
	my $hit_add    = $Cellwall::singleton->sql()->prepare("INSERT INTO blast_hit VALUES(NULL, ?, ?, ?, ?, NULL)");

	# Try to get the id
	$hit_get_id->execute($hit->accession_number());
	my ($id) = $hit_get_id->fetchrow_array();
	$hit_get_id->finish();

	# Return the id if we have it
	return $id if defined $id;

	# Get the species
	my $species;

	# Most of this could probably be ditched, since
	# a select is really cheap...
	if( defined($hit->species()) ) {
		# Check the species cache
		if( $species = Cellwall::Species::get_Species( $hit->species()->genus(), $hit->species()->species() )) {
			# Make sure it has an id
			$species = undef unless $species->id();
		}
		
		if(!defined( $species )) {
			# Now try the database
			$species = $Cellwall::singleton->sql()->get_Species( name => $hit->species()->genus(), $hit->species()->species() );

			if( !defined($species) or !defined($species->id()) ) {
				# Its not their either, so rebless it and add it
				$species = $hit->species();
				bless $species, 'Cellwall::Species';
				$Cellwall::singleton->sql()->add_Species($species);
			}
		}
	}

	# Add the hit
	$hit_add->execute(
		$self->id(),
		$hit->accession_number() || $hit->display_name(),
		$species->id(),
		$hit->description()
	);	
	$self->debug(2, "Inserted hit " . $hit->accession_number());

	# Try to get the id
	$hit_get_id->execute($hit->accession_number());
	($id) = $hit_get_id->fetchrow_array();
	$hit_get_id->finish();
	

	# Return the id if we have it
	$self->debug(3, "New ID: $id");
	return $id if defined $id;

	# We couldn't get the id after adding it...
	throw Bio::Root::Exception("Couldn't get the id after inserting: " . $hit->primary_seq()->primary_id() );
}

sub add_HSP
{
	my($self, $query_id, $hit_id, $hsp) = @_;

	my $hsp_get_id = $Cellwall::singleton->sql()->prepare("SELECT id FROM blast_hsp WHERE query = ? AND hit = ?");
	my $hsp_add    = $Cellwall::singleton->sql()->prepare("INSERT INTO blast_hsp VALUES(NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL )");

	$hsp_add->execute(
		$query_id,
		$hit_id,
		$hsp->evalue(),
		$hsp->score(),
		$hsp->bits(),

		$hsp->range('query'),
		$hsp->range('hit'),
		
		$hsp->length('query'),
		$hsp->length('hit'),
		$hsp->length('total'),
		
		$hsp->frac_identical('query'),
		$hsp->frac_identical('hit'),
		$hsp->frac_identical('total'),
		$hsp->percent_identity(),
		
		$hsp->frac_conserved('query'),
		$hsp->frac_conserved('hit'),
		$hsp->frac_conserved('total'),
	);
	$self->debug(2, "Inserted hsp $query_id -> $hit_id");

	# Try to get the id
	$hsp_get_id->execute($query_id, $hit_id);
	my($id) = $hsp_get_id->fetchrow_array();
	$hsp_get_id->finish();

	$self->debug(3, "New ID: $id");
}

sub build_SeqInfo
{
	my($self, $cgi, $seq) = @_;

	# Make the query handle
	my $get_results = $Cellwall::singleton->sql()->prepare('SELECT STRAIGHT_JOIN hit.id, hit.accession, species.common_name, hsp.score, hsp.e, hsp.query_start, hsp.query_stop FROM blast_hsp AS hsp JOIN blast_hit AS hit ON hsp.hit = hit.id JOIN species ON hit.species = species.id WHERE hit.search = ? AND hsp.query = ? ORDER BY hsp.score DESC LIMIT 100');

	# Get all the results
	$get_results->execute($cgi->search_id(), $cgi->sequence_id());
	my $results = $get_results->fetchall_arrayref();
	$get_results->finish();

	# Get the length of the longest protein
	my($length) = sort { $b <=> $a } map { $_->length() } $seq->get_all_Proteins();

	# Create a new panel
	my $panel = new Bio::Graphics::Panel(
		-length     => $length,
		-key_style  => 'between',
		-width      => 600,
		-pad_top    => 5,
		-pad_left   => 10,
		-pad_right  => 10,
		-pad_bottom => 5,
		-bgcolor    => 'white',
	);


	# A simple feature to span the entire sequence
	my $entire = new Bio::SeqFeature::Generic(
		-start        => 1,
		-end          => $length,
		-display_name => $seq->accession_number(),
	);

	# Add the ruler at the top
	$panel->add_track(
		$entire,
		-glyph  => 'arrow',
		-bump   => 0,
		-dobule => 1,
		-tick  => 2,
		-fbcolor => 'black'
	);

	# Add the sequence track
	$panel->add_track(
		$entire,
		-glyph   => 'generic',
		-bgcolor => 'blue',
		-font2color => 'red',
		-label   => 1,
		-label   => $seq->accession_number(),
		-height => 12
	);

	# Setup the HSP track
	my $track = $panel->add_track(
		-glyph       => 'graded_segments',
		-label       =>  1,
		-connector   => 'dashed',
		-bgcolor     => 'blue',
		-font2color  => 'red',
		-sort_order  => 'high_score',
		-description => sub {
			my $feature = shift;
			return unless $feature->has_tag('species');
			my ($species) = $feature->each_tag_value('species');
			my $score = $feature->score;
			return "score=$score; $species"  if defined $species;
			return "score=$score";
		}
	);

	# Add each HSP to the panel
	foreach my $hit (@$results) {
		# Make some sensible names
		my($id, $acc, $common_name, $score, $e, $start, $end) = @$hit;

		# Make a feature for this hit
		my $feature = new Bio::SeqFeature::Generic(
			-primary      => $acc,
			-score        => $score,
			-display_name => $acc,
			-start        => $start,
			-end          => $end,
			-tag          => {
				species => $common_name
			},
		);
		
		$track->add_feature($feature);
	}

	return $panel;
}

sub add_SeqInfo
{
	my($self, $cgi, $seq) = @_;
	
	# Make the panel
	my $panel = $self->build_SeqInfo($cgi, $seq);

	# Make the image link
	$cgi->add_Para(
		-title => sprintf('Search %s:', $self->name()),
		-img => [
			-src => sprintf('sequence.pl?sequence_id=%s&action=render_results&search_id=%d', $cgi->sequence_id(), $self->id()),
			-map => 'blast_seqinfo',
		],
	);

	# Make the map
	my @areas;

	# This block is a quick and dirty optimization
	if( $self->genome_id() ) {
		# Redirect the areas to the genome level
		foreach my $box ( $panel->boxes() ) {
			my($feature, @points) = @$box;
			next unless defined $feature->primary_tag();

			push(@areas, -area => [
				-href   => sprintf('sequence.pl?genome_id=%d&sequence_accession=%s', $self->genome_id(), $feature->primary_tag()),
				-shape  => 'rect',
				-coords => \@points,
			]);
		}
	} elsif( $self->database_id() ) {
		# Send them to the database
		foreach my $box ( $panel->boxes() ) {
			my($feature, @points) = @$box;
			next unless defined $feature->primary_tag();

			push(@areas, -area => [
				-href   => sprintf('sequence.pl?database_id=%d&sequence_accession=%s', $self->database_id(), $feature->primary_tag()),
				-shape  => 'rect',
				-coords => \@points,
			]);
		}
	}

	# Add the map
	$cgi->add_Contents(
		-map => [
			-name => 'blast_seqinfo',
			@areas
		]
	);
}

sub render_SeqInfo
{
	my($self, $cgi, $seq) = @_;

	# Make the panel
	my $panel = $self->build_SeqInfo($cgi, $seq);

	# Make the background transparent
	$panel->gd()->transparent($panel->bgcolor());

	# Change the MIME-type to png
	$cgi->mime('image/png');

	# Print the image out
	print $cgi->headers();
	print $panel->png();

	# Make sure nothing else is printed
	exit(0);
}

sub params
{
	my($self) = @_;
	return (
		file       => $self->file(),
		alphabet   => $self->alphabet(),
		count      => $self->count(),
		cutoff     => $self->cutoff(),
		processors => $self->processors(),
	);
}

1;
