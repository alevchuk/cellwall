# vim:sw=4 ts=4
# $Id: CGI.pm 2 2004-04-01 23:09:24Z laurichj $

=head1 NAME

Cellwall::Web::Family

=head1 DESCRIPTION

This is the module for the Family information page.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Web::Family;
use Bio::AlignIO;
use Bio::Graphics::Image;
use Bio::Graphics::Widget::Tree;
use Bio::SeqIO;
use Bio::TreeIO;
use Cellwall;
use Error;
use base qw/Cellwall::Web::Index/;
use vars qw/@ACCESSORS/;
use strict;

sub new
{
	my $class = shift;

	# Call the inherited new
	my $self = $class->SUPER::new(@_);

	# Set some defaults

	# Allow a family_id through
	$self->allow_Request( family_id => '^(\d+)$' );

	# Allow a family_abrev through
	$self->allow_Request( family_abrev => '^(\w+)$' );

	# Allow a source_id through
	$self->allow_Request( source_id => '^(-?\d+)$' );

	# Allow the action parameter
	$self->allow_Request( action => '^([\w\s]+)$' );

	# Allow the format parameter
	$self->allow_Request( format => '^(\w+)$' );

	# Allow the selected parameter
	$self->allow_Request( selected => '^([\w\.;]+)$' );

	# Allow the collapsed parameter
	$self->allow_Request( collapsed => '^([\w\.;]+)$' );

	# Allow the sorter
	$self->allow_Request( sortkey => '^(\w+)$' );

	return $self;
}

sub parse
{
	my($self) = @_;

	# Call the inherited parse
	$self->SUPER::parse();

	# Set the family_id
	$self->family_id( scalar $self->get_Request('family_id') );

	# Set the family_abrev
	$self->family_abrev( scalar $self->get_Request('family_abrev') );

	# Set the source_id
	$self->source_id( scalar $self->get_Request('source_id') );

	# Set the action
	$self->action( scalar $self->get_Request('action') );

	# Set the format
	$self->format( scalar $self->get_Request('format') );

	# Set the selected
	$self->{_selected} = [];
	foreach my $select ( $self->get_Request('selected') ) {
		push(@{$self->{_selected}}, split(';', $select));
	}

	# Set the collapsed
	$self->{_collapsed} = [];
	foreach my $collapse ( $self->get_Request('collapsed') ) {
		push(@{$self->{_collapsed}}, split(';', $collapse));
	}

	# Add a menu into other family information
	$self->add_Menu(
		'Family',
		-link => [ 'Members',   'family.pl?action=show_Members&amp;family_id=' . $self->family_id() ],
		-link => [ 'Alignment', 'family.pl?action=show_Alignment&amp;family_id='  . $self->family_id() ],
		-link => [ 'Structure', sprintf('family.pl?action=show_Structure&amp;family_id=%d', $self->family_id()) ],
		-link => [ 'Tree',      'family.pl?action=show_Tree&amp;family_id=' . $self->family_id() ],
		-link => [ 'Genbank',   sprintf('family.pl?action=download_Family&amp;format=genbank&amp;family_id=%d', $self->family_id()) ],
		-link => [ 'Fasta',     sprintf('family.pl?action=download_Family&amp;format=fasta&amp;family_id=%d', $self->family_id()) ],
	);
}

sub family
{
	my($self, $family) = @_;
	$self->{_family} = $family if @_ == 2;
	return $self->{_family};
}

sub family_id
{
	my($self, $id) = @_;
	$self->{_family_id} = $id if @_ == 2;
	return $self->{_family_id};
}

sub family_abrev
{
	my($self, $id) = @_;
	$self->{_family_abrev} = $id if @_ == 2;
	return $self->{_family_abrev};
}

sub source_id
{
	my($self, $id) = @_;
	$self->{_source_id} = $id if @_ == 2;
	return $self->{_source_id};
}

sub action
{
	my($self, $id) = @_;
	$self->{_action} = $id if @_ == 2;
	return $self->{_action} || 'show_Members';
}

sub format
{
	my($self, $id) = @_;
	$self->{_format} = $id if @_ == 2;
	return $self->{_format} || 'genbank';
}

sub get_Selected
{
	my($self) = @_;
	return wantarray ? @{$self->{_selected}} : $self->{_selected};
}

sub get_Collapsed
{
	my($self) = @_;
	return wantarray ? @{$self->{_collapsed}} : $self->{_collapsed};
}

sub get_Family
{
	my($self) = @_;
	my $family;

	if( defined $self->family_id() ) {
		$family = $Cellwall::singleton->get_Family( id => $self->family_id() ) || die "no such family";
	} elsif( defined $self->family_abrev() ) {
		$family = $Cellwall::singleton->get_Family(
			abrev => $self->family_abrev()
		) || die "no such family";

		# Save the ID for internal redirects
		$self->family_id( $family->id() );
	}

	$self->family($family);

	return $family;
}


sub show_Members
{
	my($self, $family) = @_;

	# Make the basic prefix for the sorting link
	my $url = sprintf('family.pl?family_id=%d&amp;selected=%s', $family->id(), join(';', $self->get_Selected()));

	# Add the member list
	my @members = (
		-format => [
			[ -valign => 'top', -width =>  '15%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '10%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '10%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '60%', -align => 'left'  ],
			[ -valign => 'top', -width =>   '5%', -align => 'right' ],
		],
		-header => [
			-link => [ 'ID', "$url&amp;sortkey=accession", ], 
			-link => [ 'Name', "$url&amp;sortkey=display", ], 
			-link => [ 'Species', "$url&amp;sortkey=species", ], 
			-link => [ 'External Description', "$url&amp;sortkey=description", ], 
			-input => [
				-type   => 'submit',
				-target => 'memberform',
				-name   => 'action',
				-value  => 'Map in Tree',
			],
		],
		-row => [ [ -colspan => 5, '<small style="color: red;">Sort table by clicking on column titles!</small>' ] ],
	);

	# Get and sort the sequences
	my @sequences = $family->get_all_Sequences();
	my $key = $self->get_Request('sortkey');
	if( $key eq 'display' ) {
		@sequences = sort {
			# Since we deal with display_name == accession_number
			# this is complicated
			my $da = $a->display_name();
			my $db = $b->display_name();

			# They "don't have" a display_name if it is their accession
			$da = undef if defined $da and $da eq $a->accession_number();
			$db = undef if defined $db and $db eq $b->accession_number();
			
			# Do comparisons depending on who has a name
			return $da cmp $db if defined $da and defined $db;
			return -1 if defined $da;
			return  1 if defined $db;

			# Noone is defined. Bad Sequences!
			return 0;
		} @sequences;
	} elsif( $key eq 'species' ) {
		@sequences = sort { $a->species()->binomial() cmp $b->species()->binomial() } @sequences;
	} elsif( $key eq 'description' ) {
		@sequences = sort { $a->description() cmp $b->description() } @sequences;
	} elsif( $key eq 'accession' ){
		@sequences = sort { $a->accession_number() cmp $b->accession_number() } @sequences;
	} elsif( not defined $key  ) {
		@sequences = sort {
			# This puts arab first, then rice then everything else each sorting alphabetically
			my $an = $a->accession_number();
			my $bn = $b->accession_number();

			if( $an =~ /^At/o and $bn =~ /^At/o ) {
				return $an cmp $bn;
			} elsif( $an =~ /^At/o ) {
				return -1;
			} elsif( $bn =~ /^At/o ) {
				return  1;
			} elsif( $an =~ /^\d{4}\.[mt]/o and $bn =~ /^\d{4}\.[mt]/ ) {
				return $an cmp $bn;
			} elsif( $an =~ /^\d{4}\.[mt]/o ) {
				return -1;
			} elsif( $bn =~ /^\d{4}\.[mt]/o ) {
				return  1;
			} else {
				return $an cmp $bn;
			}
		} @sequences;
	}

	# Add each member:
	foreach my $seq (@sequences) {
		push(@members,
			-row => [
				-link => [ $seq->accession_number(), 'sequence.pl?sequence_id=' . $seq->primary_id() ],
				(defined($seq->display_name()) and $seq->display_name() ne $seq->accession ? $seq->display_name() : ''),
				$seq->species()->binomial(),
				$seq->description(),
				-input => [
					-type  => 'checkbox',
					-name  => 'selected',
					-value => join(';', $seq->accession_number(), $seq->display_id(), map { $_->accession_number() } $seq->get_all_Proteins()),
				]
			]
		);
	}

	# Add the member's table wrapped in a form
	$self->add_Form(
		-action => 'family.pl?family_id=' . $self->family_id(),
		-method => 'get',
		-name   => 'memberform',
		-input => [
			-type  => 'hidden',
			-name  => 'family_id',
			-value => $self->family_id(),
		],
		-input => [
			-type  => 'hidden',
			-name  => 'source_id',
			-value => -1,
		],
		-table  => [
			@members,
			-header => [
				"Actions:",
				[
					-colspan => 4,
					-align => 'right',
					-input => [
						-type   => 'submit',
						-target => 'memberform',
						-name   => 'action',
						-value  => 'Map in Tree',
					],
				]
			]
		]
	);
}

sub show_Alignment
{
	my($self, $family) = @_;

	# Figure out the file name
	my $filename = 'Align/' . $family->id();
	if( not defined $self->source_id() ) {
		if( -f $Cellwall::singleton->base() . '/' . $filename . '.3.png' ) {
			# Use arab
			$filename .= '.3';
			$self->source_id(3);
		} else {
			$self->source_id(-1);
		}
	} elsif( $self->source_id() != -1 ) {
		$filename .= '.' . $self->source_id();
	}

	# Check for file:
	if( -f $Cellwall::singleton->base() . '/' . $filename . '.png') {
		my %seen;
		my @sources = grep { ++$seen{ $_->id() } == 2 } map { $_->db() } $family->get_all_Proteins();

		# There's an alignment, so show it:
		$self->add_Para(
			-title => [ 'Alignment: ',
				-list => [
					( $self->source_id() == -1 ?
						( -link => [ 'Full*',     sprintf('family.pl?action=show_Alignment&amp;family_id=%d&amp;source_id=-1', $family->id() ) ] )
					   :( -link => [ 'Full',     sprintf('family.pl?action=show_Alignment&amp;family_id=%d&amp;source_id=-1', $family->id() ) ] )
				    ),
					map {
						$self->source_id() == $_->id() ?
							( -link => [ ( defined $_->genome() ? $_->genome()->name() : $_->name() ) . '*', sprintf('family.pl?action=show_Alignment&amp;family_id=%d&amp;source_id=%d', $family->id(), $_->id() ) ] )
						:	( -link => [ defined $_->genome() ? $_->genome()->name() : $_->name(), sprintf('family.pl?action=show_Alignment&amp;family_id=%d&amp;source_id=%d', $family->id(), $_->id() ) ] )
					} @sources,
				],
				' Download: ',
				(
					defined $self->source_id() ? (
						-list => [
							-link => [ 'Fasta',     sprintf('family.pl?action=download_Alignment&amp;family_id=%d&amp;source_id=%d&amp;format=fasta',   $family->id(), $self->source_id() ) ],
							-link => [ 'MSF',       sprintf('family.pl?action=download_Alignment&amp;family_id=%d&amp;source_id=%d&amp;format=msf',     $family->id(), $self->source_id() ) ],
							-link => [ 'HTML',      sprintf('family.pl?action=download_Alignment&amp;family_id=%d&amp;source_id=%d&amp;format=msfhtml', $family->id(), $self->source_id() ) ],
						]
					) : (
						-list => [
							-link => [ 'Fasta',     sprintf('family.pl?action=download_Alignment&amp;family_id=%d&amp;format=fasta',     $family->id() ) ],
							-link => [ 'MSF',       sprintf('family.pl?action=download_Alignment&amp;family_id=%d&amp;format=msf',       $family->id() ) ],
							-link => [ 'HTML',      sprintf('family.pl?action=download_Alignment&amp;family_id=%d&amp;format=msfhtml',   $family->id() ) ],
						]
					)
				),
				( -f sprintf('%s/HMMER/%s.hmm', $Cellwall::singleton->base(), $family->abrev()) ? (
					' HMM: ',
					-list => [
						-link => [ 'Model', sprintf('HMMER/%s.hmm', $family->abrev()) ],
					]
				) : ()
				),
			],
			-img => [ -src => "$filename.png", -width => '100%', -alt => 'Alignment' ],
		);
	} else {
		$self->add_Para(
			-title => 'Alignment:',
			'There is no alignment for this family.'
		);
	}
}

sub build_Tree
{
	my($self, $family) = @_;

	# Figure out the file name
	my $filename = $Cellwall::singleton->search_File('Tree', $family->id());
	if( not defined $self->source_id() ) {
		if( -f "$filename.3.dnd" ) {
			# Use arab
			$filename .= '.3';
			$self->source_id(3);
		} else {
			$self->source_id(-1);
		}
	} elsif( $self->source_id() != -1 ) {
		$filename .= '.' . $self->source_id();
	}

	$filename .= ".dnd";

	# Get the tree:
	my $in = new Bio::TreeIO(
		-format => 'newick',
		-file   => $filename
	);

	# Generate the image
	my $tree   = $in->next_tree();
	my $image  = new Bio::Graphics::Image(
		-width => 600,
		-fontcolor => 'blue',
	);
	my $widget = new Bio::Graphics::Widget::Tree( -tree => $tree );
	$image->widget($widget);

	# Highlight all of the nodes that are selected
	foreach my $id ($self->get_Selected()) {
		my $node = $widget->get_Leaf($id);
		next unless defined $node;
		$node->highlight(1);
	}
	
	# Collapse all of the collapsed nodes
	foreach my $id ($self->get_Collapsed()) {
		my $node = $widget->get_Node($id);
		next unless defined $node;
		$node->collapsed(1);
	}

	return $image;
}

sub show_Tree
{
	my($self, $family) = @_;

	# Get the tree image
	my $image = $self->build_Tree($family);

	# Make a hash of what is collapsed
	my %collapsed = map { $_ => 1 } ( $self->get_Collapsed() );

	# Build the area boxes
	my @areas;
	foreach my $box ($image->boxes()) {
		if( $box->[0]->is_Leaf() ) {
			# the box is a leaf, so make a link to the id
			my $id = $box->[0]->id();

			push( @areas,
				-area => [
					-href   => 'sequence.pl?sequence_accession=' . $box->[0]->id(),
					-coords => [ $box->[1], $box->[2], $box->[3], $box->[4] ],
					-shape  => 'rect',
				]
			);
		} else {
			# This is a collapse box
			my $id = $box->[0]->internal_id();

			# Toggle the collapsed state of the node
			$collapsed{$id} = not $collapsed{$id};

			# Make the area
			push(@areas,
				-area => [
					-href => ( defined $self->source_id() ? 
						sprintf('family.pl?action=show_Tree&amp;family_id=%s&amp;source_id=%d&amp;collapsed=%s&amp;selected=%s', $family->id(), $self->source_id(), join(';', grep { $collapsed{$_} } ( keys(%collapsed) ) ), join(';', $self->get_Selected()) ) :
						sprintf('family.pl?action=show_Tree&amp;family_id=%s&amp;collapsed=%s&amp;selected=%s', $family->id(), join(';', grep { $collapsed{$_} } ( keys(%collapsed) ) ), join(';', $self->get_Selected()) ),
					),
					-coords => [ $box->[1], $box->[2], $box->[3], $box->[4] ],
					-shape  => 'rect',
				]
			);

			# Toggle the collapsed state of the node
			$collapsed{$id} = not $collapsed{$id};
		}
	}

	# Add the paragram
	my $src;
	if( defined $self->source_id() ) {
		$src = sprintf('family.pl?action=render_Tree&amp;family_id=%s&amp;source_id=%d&amp;collapsed=%s&amp;selected=%s', $family->id(), $self->source_id(), join(';', $self->get_Collapsed()), join(';', $self->get_Selected()));
	} else {
		$src = sprintf('family.pl?action=render_Tree&amp;family_id=%s&amp;collapsed=%s&amp;selected=%s', $family->id(), join(';', $self->get_Collapsed()), join(';', $self->get_Selected()));
	}

	my %seen;

	### alevchuk 2013-06-15 - this causes the page the crash with 
	###                       Can't call method "id" on an undefined value
	#my @sources = grep { ++$seen{ $_->id() } == 3 } map { $_->db() } $family->get_all_Proteins();

	$self->add_Para(
		-title => [ "Tree: ",
			-list => [
				(
					$self->source_id() == -1 ?
					( -link => [ 'Full*',    sprintf('family.pl?action=show_Tree&amp;family_id=%d&amp;source_id=-1', $family->id() ) ] )
				   :( -link => [ 'Full',     sprintf('family.pl?action=show_Tree&amp;family_id=%d&amp;source_id=-1', $family->id() ) ] ),
			   ),
				### alevchuk 2013-06-15 ^
				# map {
				# 	$self->source_id() == $_->id() ?
				# 		( -link => [ ( defined $_->genome() ? $_->genome()->name() : $_->name() ) . '*', sprintf('family.pl?action=show_Tree&amp;family_id=%d&amp;source_id=%d', $family->id(), $_->id() ) ] )
				# 	:	( -link => [ defined $_->genome() ? $_->genome()->name() : $_->name(), sprintf('family.pl?action=show_Tree&amp;family_id=%d&amp;source_id=%d', $family->id(), $_->id() ) ] )
				# } @sources,
			], ' ',
			-link => ['Map in Tree', sprintf('family.pl?action=show_Members&amp;family_id=%d', $family->id() ) ],
			' ', 'Download: ',
			-list => [
				-link => [ 'Tree', sprintf('Tree/%s.dnd', $family->id()) ],
			],
		],
		'<small style="color: red;">To highlight sequences in tree, check them in the member list</small><br/>',
		-img => [
			-src => $src,
			-map => 'tree',
		],
		-map => [
			-name => 'tree',
			@areas,
		]
	);
}

sub render_Tree
{
	my($self, $family) = @_;

	# Get the tree image
	my $image = $self->build_Tree($family);

	# Change the MIME-type to png
	$self->mime('image/png');

	# render the tree
	my $gd = $image->draw();

	# Make the background transparent
	$gd->transparent($image->_color_cache($image->bgcolor()));

	# Print the tree out
	print $self->headers();
	print $gd->png();

	# Make sure nothing else is printed
	exit(0);
}

sub download_Family
{
	my($self, $family) = @_;

	# Setup the MIME type
	$self->mime('text/plain');

	# Print the headers
	print $self->headers();

	# Figure out what format
	if($self->format() eq 'genbank') {
		# Open STDOUT as a SeqIO
		my $seqout = new Bio::SeqIO(
			-format => 'genbank',
			-fh     => \*STDOUT,
		);

		# Print the seq
		$seqout->write_seq($_) foreach $family->get_all_Sequences();
	} elsif( $self->format() eq 'fasta' ) {
		# Open STDOUT as a SeqIO
		my $seqout = new Bio::SeqIO(
			-format => 'fasta',
			-fh     => \*STDOUT,
		);

		my @proteins = map { $_->get_all_Proteins() } $family->get_all_Sequences();

		foreach my $p (@proteins) {
			$p->display_name( $p->accession_number() ) unless defined $p->display_name();
		}

		# Print each protein
		$seqout->write_seq($_) foreach map { $_->get_all_Proteins() } $family->get_all_Sequences();
	}

	# Now exit to prevent anything else from being printed
	exit(0);
}

sub download_Alignment
{
	my($self, $family) = @_;

	# Figure out the file name
	my $filename;
	if( defined $self->source_id() and $self->source_id() ne '-1') {
		$filename = '/Align/' . $family->id() . '.' . $self->source_id();
	} else {
		$filename = '/Align/' . $family->id();
	}
	$filename = $Cellwall::singleton->base() . $filename . '.mul';

	# Check for file:
	if( not -f $filename ) {
		print STDERR "Foo: $filename ", $self->source_id(), "\n";
		$self->add_Para(
			-title => 'Alignment:',
			'There is no alignment for this family.'
		);
		return;
	}

	# Read in the alignment
	my $in = new Bio::AlignIO(
		-format => 'fasta',
		-file   => $filename,
	);

	# Get the alignment
	my $align = $in->next_aln();
	if( not defined $align ) {
		$self->add_Para(
			-title => 'Alignment:',
			'There is no alignment for this family.'
		);
		return;
	}

	# Setup the MIME type
	if($self->format() eq 'msfhtml') {
		$self->mime('text/html');
	} elsif($self->format() eq 'msfhtml2') {
		$self->mime('text/html');
	} else {
		$self->mime('text/plain');
	}

	# Print the headers
	print $self->headers();

	# Get the format or set it to fasta
	my($format) = grep { $self->format() eq $_ } ( 'fasta', 'msf', 'phylip', 'nexus', 'msfhtml' );
	$format = 'fasta' unless defined $format;

	# Open an AlignIO to stdout
	my $out = new Bio::AlignIO(
		-format => $format,
		-fh     => \*STDOUT,
	);

	# Print the alignment
	$out->write_aln($align);
	$out->close();

	# Now exit to prevent anything else from being printed
	exit(0);
}


sub show_all_Structures
{
	my($self, $family) = @_;

	# Add each sequence to the page
	foreach my $seq ($family->get_all_Sequences()) {
		$self->add_Para(
			-title => [ -link => [ $seq->accession_number(), sprintf('sequence.pl?sequence_id=%d', $seq->primary_id()) ] ],
			-link => [
				[ -img => [ -src => sprintf('sequence.pl?action=render_seqview&amp;sequence_id=%d', $seq->primary_id()) ] ],
				sprintf('sequence.pl?sequence_id=%d', $seq->primary_id()),
			],
		);
	}
}

1;

