# vim:sw=4 ts=4
# $Id: CGI.pm 2 2004-04-01 23:09:24Z laurichj $

=head1 NAME

Cellwall::Web::Sequence

=head1 DESCRIPTION

This is the module for the Sequence information page.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Web::Sequence;
use Bio::SeqIO;
use Bio::TreeIO;
use Bio::Graphics;
use Bio::Graphics::Image;
use Bio::Graphics::Widget::Tree;
use Cellwall;
use Error;
use base qw/Cellwall::Web::Index/;
use strict;

sub new
{
	my $class = shift;

	# Call the inherited new
	my $self = $class->SUPER::new(@_);

	# Set some defaults

	# Allow the sequence_locator through
	$self->allow_Request( sequence_locator => '(?:[\w_\.]+\:[\w\._]+;)*[\w_\.]+\:[\w\._]+' );

	# Allow a sequence_id through
	$self->allow_Request( sequence_id => '^(\d+)$' );

	# Allow the sequence_accession parameter
	$self->allow_Request( sequence_accession => '^([\w\.;_]+)$' );

	# Allow the sequence_protein parameter
	$self->allow_Request( sequence_protein => '^([\w\.;]+)$' );

	# Allow a genome_id through
	$self->allow_Request( genome_id => '^(\d+)$' );

	# Allow a database_id through
	$self->allow_Request( database_id => '^(\d+)$' );

	# Allow the action parameter
	$self->allow_Request( action => '^(\w+)$' );

	# Allow the format parameter
	$self->allow_Request( format => '^(\w+)$' );

	# Allow the highlight parameter
	$self->allow_Request( highlight => '(\w+:(?:\d+..\d+,)*(?:\d+..\d+))' );

	# Allow the search_id parameter
	$self->allow_Request( search_id => '^(\d+)$' );

	# Allow the external_database parameter
	$self->allow_Post( external_database => '^(\w+)$' );

	# Allow the external_link parameter
	$self->allow_Post( external_link => '^(?:https?:\/\/)?([a-zA-Z][\w\.\-]+[\/\w\+\?\.\&\=]+)$' );

	# Allow the comment through
	$self->allow_Request( comment_id   => '^(\d+)$' );
	$self->allow_Post( comment   => '^\s*([^><]+)\s*$' );
	$self->allow_Post( reference => '^\s*([^><]+)\s*$' );

	# Editing
	$self->allow_Request( confirmed => '(yes|no)');

	return $self;
}

sub parse
{
	my($self) = @_;

	# Call the inherited parse
	$self->SUPER::parse();

	# Set the sequence_id
	$self->sequence_id( scalar $self->get_Request('sequence_id') );

	# Set the sequence_accession
	$self->sequence_accession( scalar $self->get_Request('sequence_accession') );

	# Set the sequence_protein
	$self->sequence_protein( scalar $self->get_Request('sequence_protein') );

	# Set the database_id
	$self->database_id( scalar $self->get_Request('database_id') );

	# Set the genome_id
	$self->genome_id( scalar $self->get_Request('genome_id') );

	# Set the action
	$self->action( scalar $self->get_Request('action') );

	# Set the format
	$self->format( scalar $self->get_Request('format') );

	# Set the highlights
	$self->highlight( $self->get_Request('highlight') );

	# Set the search_id
	$self->search_id( scalar $self->get_Request('search_id') );

	# Set the sequence_locator
	$self->sequence_locator( scalar $self->get_Request('sequence_locator') );

	## Get the sequence
	$self->fetch_Sequence();

	# Add a menu into other sequence information
	$self->add_Menu(
		'Sequence',
		-link => [ 'Information', sprintf('sequence.pl?action=sequence&sequence_locator=%s'               , $self->sequence_locator()) ],
		-link => [ 'Features',    sprintf('sequence.pl?action=features&sequence_locator=%s#features'      , $self->sequence_locator()) ],
		-link => [ 'Genbank',     sprintf('sequence.pl?action=download&sequence_locator=%s&format=genbank', $self->sequence_locator()) ],
		-link => [ 'Fasta',       sprintf('sequence.pl?action=download&sequence_locator=%s&format=fasta'  , $self->sequence_locator()) ],
	);

	## No more link to Blast ESTs Jul 1 01:33:31 2009 / Jun 8, 2013
	# # Add the results menu if there are any results for this level in
	# # the database
	# if( defined $self->sequence_id() and my @searches = grep { $_->query() eq 'protein' or $_->query() eq 'nucleotide' } $Cellwall::singleton->get_all_Searches() ) {
	# 	$self->add_Menu(
	# 		'Results',
	# 		map {
	# 			-link => [ $_->name(), sprintf('sequence.pl?action=results&search_id=%s&sequence_id=%s',  $_->id(), $self->sequence_id() ) ]
	# 		} @searches
	# 	);
	# }

}

sub fetch_Sequence
{
	my( $self ) = @_;

	# This is the database object we're going to fetch out of
	my $object;

	# This is the sequence
	my $seq;

	if( defined($self->genome_id()) ) {
		# Get the genome
		$object = $Cellwall::singleton->get_Genome( id => $self->genome_id() );
		die "unable to get the genome" unless defined $object;

	} elsif( defined($self->database_id()) ) {
		# Get the database
		$object = $Cellwall::singleton->get_Database( id => $self->database_id() );
		die "unable to get the database" unless defined $object;

	} else {
		# Okay, we're going to try to get it from the SQL database
		if( defined $self->sequence_id() ) {

			# Get the sequence by the ID number, and set the accession number
			$seq = $Cellwall::singleton->sql()->get_Sequence( id => $self->sequence_id() );
			$self->sequence_accession( $seq->accession_number() );

		} elsif( defined $self->sequence_accession() ) {
			# Get it by the accession, and set the id number
			$seq = $Cellwall::singleton->sql()->get_Sequence( accession => $self->sequence_accession() );
			$self->sequence_id( $seq->primary_id() );
		} elsif( defined $self->sequence_protein() ) {
			# Get it by the protein, and set the id number and accession
			$seq = $Cellwall::singleton->sql()->get_Sequence( accession => $self->sequence_protein() );
			$self->sequence_id( $seq->primary_id() );
			$self->sequence_accession( $seq->accession_number() );
		}

		# Now set the object
		$object = $seq->database();
	}

	# alevchuk
	print STDERR "unable to fetch sequence\n" unless defined $object;

	# Now get the sequence from its database
	if( defined( $self->sequence_accession() ) ) {
		# Try to get it with its accession number

                # Removed a major bug

                # When loading a new row in the sequence table
                # The original line chocked whit:
                #   [error] Can't locate object method "get_Sequence"
                #   via package "Cellwall::Database::blast" at
                #   /srv/web/Cellwall/lib/Cellwall/Web/Sequence.pm line 193,
                #   <GEN0> line 2.\n

                # The $debug99 is copied from above OBJECT C case
                # the original lines were the composition of $debug1 and $debug2


                #print STDERR "TEST\n";
                #my $debug1 = $self->sequence_accession();
                #my $debug2 = $object->get_Sequence($debug1);
                my $debug99 = $Cellwall::singleton->sql()->get_Sequence( id => $self->sequence_id() );
               $self->sequence($debug99) ;
                #print STDERR "TEST2\n";

	} elsif( defined( $self->sequence_id() ) ) {
		# try with the id number
		$self->sequence( $object->get_Sequence($self->sequence_id()) );
	}

	# If we had a sequence, set the info:
	if( defined $seq ) {
		$seq->species( $self->sequence()->species() );
		$self->sequence( $seq );
#		$self->sequence()->primary_id(   $seq->primary_id()   );
#		$self->sequence()->family_id(    $seq->family_id()    );
#		$self->sequence()->family(       $seq->family()       );
#		$self->sequence()->gene_name(    $seq->gene_name()    );
#		$self->sequence()->fullname(     $seq->fullname()     );
#		$self->sequence()->alt_fullname( $seq->alt_fullname() );
#		$self->sequence()->symbols(      $seq->symbols()      );
	}

	# Now figure out if we really want to view a protein
	if( defined $self->sequence_protein() ) {
		# We probably want to fetch a protein....
		foreach my $protein ($self->sequence()->get_all_Proteins()) {
			next unless $self->sequence_protein() eq $protein->accession_number();

			# Okay, we found it
			$self->sequence( $protein );
			last;
		}
	}

	die "unable to fetch sequence" unless defined $self->sequence();

	# Set the primary id
	$self->sequence()->primary_id( $self->sequence_id() );
}

sub add_Sequence
{
	my($self, $seq) = @_;

	# Build the table
	my ($species, $genus, @class) = $seq->species()->classification();
	my @accessions = grep { $_ ne $seq->accession_number() } $seq->get_secondary_accessions();
	my @header = (
		-format => [
			[ -valign => 'top', -width =>  '25%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '55%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '20%', -align => 'right' ],
		],
		-header => [
			'Locus:', $seq->accession_number(),

			### alevchuk 2013-06-15 User login is broaken so don't show
			[ -list => [ 'Login' ] ],
			# [ -list => [
			# 	( defined $self->get_Session('uid') ?
			# 		( -link => [ 'Add Annotations', sprintf('sequence.pl?action=edit&sequence_locator=%s', $self->sequence_locator()) ] )
			# 	:
			# 		( -link => [ 'Login', 'users.pl' ] )
			# 	)
			# ] ]
		],
		( defined $seq->display_name() ? ( -row => [ 'Display Name:', $seq->display_name() ] ) : () ),
		( scalar(@accessions) > 0 ?
			( -row => [ 'IDs:', [ -colspan => 2, -list => [ @accessions ] ] ] ) :
			()
		),
		-row    => [ 'Source Description:',  [ -colspan => 2, $seq->description()                                    ] ],
		-row    => [ 'Length:',              [ -colspan => 2, $seq->length()                                         ] ],
		( defined $seq->family() ? ( -row => [ 'Family:',      [ -colspan => 2, -link => [ $seq->family()->name(), sprintf('family.pl?family_id=%d', $seq->family()->id()) ] ] ] ) : () ),
		-row    => [ 'Species:',             [ -colspan => 2, $seq->species()->common_name()                         ] ],
		-row    => [ 'Lineage:',             [ -colspan => 2, join('; ', reverse(@class)) ] ],
	);

	# Add any mutant information
	if( defined $seq->gene_name() ) {
		push(@header, -header => [[ -colspan => 3, 'Mutant' ]] );
		push(@header, -row    => [ 'Gene Name:',     [ -colspan => 2, $seq->gene_name() ] ] );
		push(@header, -row    => [ 'Full Name:',     [ -colspan => 2, $seq->fullname()     ] ] ) if defined $seq->fullname();
		push(@header, -row    => [ 'Alt Full Name:', [ -colspan => 2, $seq->alt_fullname() ] ] ) if defined $seq->alt_fullname();
		push(@header, -row    => [ 'Symbols:',       [ -colspan => 2, -list => [ split('; ', $seq->symbols()) ] ] ] ) if defined $seq->symbols();
	}

	# Add any external links
	my @dblinks = $seq->annotation()->get_Annotations('dblink');
	if(scalar @dblinks > 0) {
		my %sections;
		push(@{$sections{lc $_->{_CW_Section} || 'Other'}}, $_) foreach @dblinks;
		
		foreach my $key (qw/Annotation Literature Functional Expression Knockout/) {
			next unless defined $sections{lc $key};
			my $name = $key eq 'Literature' ? "Gene Specific Literature" : $key;

			my @links = map {
				-link => [ -class => lc($_->database()),  $_->database(), $_->primary_id() ]
			} @{$sections{lc $key}};


			push(@header,
				-header => [     [ -colspan => 3, "$name Links" ] ],
				-row    => [ '', [ -colspan => 2, -list => [ @links ] ] ],
			);
		}

		# Possibly add the family links
		my( $cwd ) = ( $ENV{SCRIPT_FILENAME} =~ /^(.*)\/[^\/]+$/o );
		my $file = sprintf('%s/Families/%s.xml', $cwd, $seq->family()->abrev());
		if( -f $file ) {
			open(FAMILY_FILE, $file);
			my $line  = <FAMILY_FILE>;
			close(FAMILY_FILE);
			chomp($line);
			push(@header,
				-header => [     [ -colspan => 3, "Family Links" ] ],
				-row    => [ '', [ -colspan => 2, $line ] ],
			);
		}

		if( defined $sections{other}) {
			my @links = map {
				-link => [ $_->database(), $_->primary_id() ]
			} @{$sections{Other}};

			push(@header,
				-header => [     [ -colspan => 3, "User Links:" ] ],
				-row    => [ '', [ -colspan => 2, -list => [ @links ] ] ],
			);
		}
	}

	# Add any Comments
	my @comments = $seq->annotation()->get_Annotations('comment');
	if( scalar @comments > 0 ) {
		push(@header, -header => [ [ -colspan => 3, 'User Comments' ] ]);

		foreach my $comment (@comments) {
			if(defined $comment->{_CW_Name}) {
				# Check to see if the user is logged in and this is theirs
				my $uid = $self->get_Session('uid');
				if( defined $uid and $comment->{_CW_Uid} == $uid ) {
					push(@header,
						-row => [ 'Comment:', [ -colspan => 2, -tt => [
							$comment->{_CW_Name} . '<br/>',
							-list => [
								-link => [ 'Edit', sprintf('sequence.pl?action=edit_Comment&sequence_locator=%s&comment_id=%d', $self->sequence_locator(), $comment->{_CW_Id}) ],
								-link => [ 'Delete', sprintf('sequence.pl?action=delete_Comment&sequence_locator=%s&comment_id=%d', $self->sequence_locator(), $comment->{_CW_Id}) ],
							],
						] ] ],
						-row => [ '', [ -colspan => 2, -tt => [ $comment->text() ] ] ],
					);
				} else {
					push(@header,
						-row => [ 'Comment:', [ -colspan => 2, -tt => [ $comment->{_CW_Name} ] ] ],
						-row => [ '', [ -colspan => 2, -tt => [ $comment->text() ] ] ],
					);
				}
			} else {
				push(@header,
					-row => [ 'Comment:', [ -colspan => 2, -tt => [ $comment->text() ] ] ]
				);
			}

			if( defined $comment->{_CW_Reference} ) {
				push(@header,
					-row => [ '', [ -colspan => 2, -tt => [ $comment->{_CW_Reference} ] ] ],
				);
			}
		}
	}

	push(@header,
		-header => [ [ -colspan => 3, 'View Protein', ] ],
		-row =>    [ '', [ -colspan => 2,
			-list => [
				-link => [ 'Gene', sprintf('sequence.pl?action=features&amp;sequence_locator=%s', $self->sequence_locator(undef, "genome_id database_id sequence_id sequence_accession" )) ],
				map {
					-link => [ "Protein: $_", sprintf('sequence.pl?action=features&amp;sequence_id=%d&amp;sequence_protein=%s', $self->sequence_id(), $_) ],
				} map { $_->accession_number()} $seq->get_all_Proteins()
			]
		] ]
	);

	push(@header,
		-header => [ 'Structure', '<small style="color: red;">Click feature to highlight in sequence text</small>', '' ],
		-row    => [ '', [ -colspan => 2, 
			-img => [
				-src => 'sequence.pl?action=render_seqview&amp;sequence_locator=' . $self->sequence_locator(),
				-map => 'seqview',
			]],
		],
		-header => [ 'Sequence', '', '' ],
	);
	
	# Add the sequence
	if( my @highlight = $self->highlight() ) {
		my @segments;

		# Figure out the order to highlight them in
		foreach my $hl (@highlight) {
			my( $class, @chunks ) = map { split ',' } split(':', $hl);

			foreach my $chunk (@chunks) {
				my ($start, $end) = map { $_ - 1 } split(/\.\./o, $chunk);
				push(@segments, [ $class, $start, $end ]);
			}
		}

		# Order the segments
		@segments = sort { $a->[1] <=> $b->[1] || $a->[2] <=> $b->[2] } @segments;

		# Get the first segment
		my($class, $start, $end) = @{ shift @segments };

		# Split the sequence up into chunks and loop through each
		my @blocks = ($seq->seq() =~ /(\S{1,10})/go);

		for(my $i = 0; $i < scalar( @blocks ); $i++) {
			if( defined($class) and $end < $i * 10 + 10 ) {
				# Stick the end in there
				substr($blocks[$i], ($end + 1) % 10, 0) = "</tt>";
			} elsif( defined($class) and $i * 10 + 10 >= $start and $i * 10 < $end ) {
				$blocks[$i] .= '</tt>';
			}
	
			if( defined($class) and $i*10 <= $start && $start < $i * 10 + 10 ) {
				# Stiick the open tag in there
				substr($blocks[$i], $start % 10, 0) = "<tt class='$class'>";
			} elsif( defined($class) and $i * 10 + 10 >= $start and $i * 10 < $end ) {
				$blocks[$i] = "<tt class='$class'>" . $blocks[$i];
			}
	
			if( defined $end and $end < $i * 10 + 10 ) {
				if( scalar( @segments ) > 0 ) {
					( $class, $start, $end ) = @{ shift @segments };
				} else {
					$class = $start = $end = undef;
				}
			}
	
			# Join the space or \n on the block
			if( ($i + 1) % 7 ) {
				$blocks[$i] .= ' ';
			} else {
				$blocks[$i] .= "\n";
			}
		}

		push(@header, -row    => [ '', [ -colspan => 2, -pre => [ join('', @blocks) ] ] ] );
	} else {
		push(@header, -row    => [ '', [ -colspan => 2, -pre => [ join("\n", map { join(' ', ($_ =~ /(\S{1,10})/go)) } ( $seq->seq() =~ /(\S{1,70})/go )) ] ] ] );
	}

	# Add the table to the page
	$self->add_Table(@header);

	# Add the seqview map
	$self->add_SeqViewMap($seq);
}

sub add_FeatureTable
{
	my($self, $seq) = @_;

	# Create the first bit of the feature table
	my @features = (
		-format => [
			[ -valign => 'top', -width =>  '10%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '85%', -align => 'left'  ],
			[ -valign => 'top', -width =>   '5%', -align => 'right'  ],
		],
		-header => [ '<a name="features"></a>Features', 'Location/Qualifiers', 'Select' ],
	);

	# Now, add each SeqFeature
	foreach my $feature ($seq->get_SeqFeatures()) {
		# Make the string for the highlighter
		my $hlstring = join(',', map { $_->start() . '..' . $_->end() } ( $feature->location()->isa('Bio::Location::Split') ? $feature->location()->sub_Location() : $feature ) );

		if($feature->primary_tag() eq 'MODEL' and my($protein) = $feature->get_tagset_values('pub_locus', 'locus', 'feat_name' ) ) {
			push(@features,
				-row => [
					$feature->primary_tag(),
					[ [
						[ -tt => join("\n", ($feature->location()->to_FTstring() =~ /(.{1,65}$|.{1,65},|.{1,65})/go)) ],
						-list => [
							-link => [ 'View Protein', sprintf('sequence.pl?action=features&amp;sequence_locator=%s&amp;sequence_protein=%s', $self->sequence_locator(), $protein ) ],
						],
					] ],
					-input => [
						-type =>'radio',
						-name => 'highlight',
						-value => "MISC:$hlstring",
					]
				]
			);
		} else {
			push(@features,
				-row => [
					$feature->primary_tag(),
					[ -tt => join("\n", ($feature->location()->to_FTstring() =~ /(.{1,65}$|.{1,65},|.{1,65})/go)) ],
					-input => [
						-type =>'radio',
						-name => 'highlight',
						-value => "MISC:$hlstring",
					]
				]
			);
		}

		# Build all of the tag info
		my $tags;
		foreach my $tag ($feature->get_all_tags()) {
			my $length = length("/$tag=\"");
			my $width  = 65 - $length;
			
			foreach my $value ( $feature->get_tag_values($tag) ) {
				$value = join("\n" . ' ' x $length, ( $value =~ /(.{1,$width}$|.{1,$width} |.{1,$width})/g ));
				$tags = sprintf("%s/%s=\"%s\"\n", $tags || '', $tag, $value);
			}
		}
		push(@features, -row => [ '', -pre => $tags ]) if defined $tags;
	}

	# Add the table to the page
	$self->add_Form(
		-action => sprintf("sequence.pl?action=features&amp;sequence_locator=%s", $self->sequence_locator()),
		-method => 'get',
		-name   => 'featureform',
		-input  => [
			-type => 'hidden',
			-name => 'sequence_locator',
			-value => $self->sequence_locator(),
		],
		-table => [
			@features,
			-header => [
				'Actions:',
				[
					-colspan => 2,
					-input => [
						-type => 'submit',
						-target => 'featureform',
						-name => 'action',
						-value => 'Highlight'
					],
				]
			]
		]
	);
}

sub edit_Sequence
{
	my($self, $seq) = @_;

	$self->add_Form(
		-action => 'sequence.pl',
		-method => 'post',
		-name   => 'linkform',
		-input  => [
			-type => 'hidden',
			-name => 'sequence_locator',
			-value => $self->sequence_locator(),
		],
		-input  => [
			-type => 'hidden',
			-name => 'action',
			-value => 'add_ExternalLink',
		],
		-table => [
			-format => [
				[ -width => '15%' ],
				[ -width => '85%' ],
			],
			-header => [ [ -colspan => 2, 'Add an external link:' ] ],
			-row => [
				'Database:',
				-input => [
					-type  => 'text',
					-name  => 'external_database',
					-width => 64,
				],
			],
			-row => [
				'Link',
				-input => [
					-type  => 'text',
					-name  => 'external_link',
					-width => 64,
				],
			],
			-header => [
				'Actions:',
				[
					-colspan => 2,
					-input => [
						-type => 'submit',
						-target => 'linkform',
						-name => 'button',
						-value => 'Add Link'
					],
				]
			]
		]
	);

	$self->add_Form(
		-action => 'sequence.pl',
		-method => 'post',
		-name   => 'commentform',
		-input  => [
			-type => 'hidden',
			-name => 'sequence_locator',
			-value => $self->sequence_locator(),
		],
		-input  => [
			-type => 'hidden',
			-name => 'action',
			-value => 'view_Comment',
		],
		-table => [
			-format => [
				[ -width => '15%' ],
				[ -width => '85%' ],
			],
			-header => [ [ -colspan => 2, 'Add a comment' ] ],
			-row => [
				'Comment',
				-input => [
					-type  => 'textarea',
					-name  => 'comment',
					-width => 64,
					-height => 10,
				],
			],
			-row => [
				'Reference',
				-input => [
					-type  => 'textarea',
					-name  => 'reference',
					-width => 64,
					-height => 3,
				],
			],
			-header => [
				'Actions:',
				[
					-colspan => 2,
					-input => [
						-type => 'submit',
						-target => 'commentform',
						-name => 'button',
						-value => 'Add Comment'
					],
				]
			]
		]
	);
}

sub add_ExternalLink
{
	my($self, $seq) = @_;

	# Check for a database
	if(not defined $self->get_Post('external_database')) {
		$self->add_Para(
			-title => 'Missing Database',
			'A database needs to be specified'
		);

		# And edit it again
		$self->edit_Sequence($seq);
	} elsif(not defined $self->get_Post('external_link')) {
		# Check for a link
		$self->add_Para(
			-title => 'Missing Link',
			'A URL needs to be specified'
		);

		# And edit it again
		$self->edit_Sequence($seq);
	} else {
		my $url = $self->get_Post('external_link');

		$url = "http://$url" unless $url =~ /^http:\/\//o;
		
		# Add the link
		$Cellwall::singleton->sql()->add_DBLink(
			$seq->primary_id(),
			'Other',
			$self->get_Post('external_database'),
			$url,
		);

		# Set the referal
		$self->add_Meta(
			'-http-equiv' => 'Refresh',
			'-content'    => sprintf('5;URL=sequence.pl?sequence_locator=%s', $self->sequence_locator()),
		);

		# Tell the user
		$self->add_Para(
			-title => 'Link Added',
			'The specified external link has been added to the database. ' .
			'You will be redirected back in 5 seconds. If your browser ' .
			'doesn\'t support this, click ',
			-link => [ 'here', sprintf('sequence.pl?sequence_locator=%s', $self->sequence_locator()) ], '.'
		);
	}
}

sub view_Comment
{
	my($self, $seq) = @_;

	if(not defined $self->get_Post('comment')) {
		$self->add_Para(
			-title => 'Missing Comment',
			'A valid comment is required. Comments are restricted to plain alphanumeric ' .
			'characters and simple punctuation.'
		);

		# And edit it again
		$self->edit_Sequence($seq);
	} else {
		# Save the comment
		$self->set_Session( comment    => $self->get_Post('comment') );
		$self->set_Session( comment_id => $self->get_Post('comment_id') );
		$self->set_Session( reference  => $self->get_Post('reference') );

		# View it
		$self->add_Para( -title => 'Comment Preview:',
			$self->get_Post('comment'),
			defined $self->get_Post('reference') ? ('<br><br>', $self->get_Post('reference')) : ()
		);

		$self->add_Para(
			'If the above is satisfactory, click ',
			-link => [ here => sprintf("sequence.pl?action=add_Comment&amp;sequence_locator=%s", $self->sequence_locator()) ],
			'. Otherwise, click back in your browser and edit your entry.',
		);
	}
}

sub add_Comment
{
	my($self, $seq) = @_;

	if( my $id = $self->get_Session('comment_id') ) {
		# There's a comment already there
		$Cellwall::singleton->sql()->replace_Comment(
			$id,
			$seq->primary_id(),
			$self->get_Session('uid'),
			$self->get_Session('comment'),
			$self->get_Session('reference'),
		);
	} else {
		# Add it to the SQL database
		$Cellwall::singleton->sql()->add_Comment(
			$seq->primary_id(),
			$self->get_Session('uid'),
			$self->get_Session('comment'),
			$self->get_Session('reference'),
		);
	}

	# Set the referal
	$self->add_Meta(
		'-http-equiv' => 'Refresh',
		'-content'    => sprintf('5;URL=sequence.pl?sequence_locator=%s', $self->sequence_locator()),
	);

	# Tell the user
	$self->add_Para(
		-title => 'Added',
		'The comment has been added to the database. ' .
		'You will be redirected back in 5 seconds. If your browser ' .
		'doesn\'t support this, click ',
		-link => [ here => sprintf("sequence.pl?sequence_locator=%s", $self->sequence_locator()) ], '.',
	);

	# Delete all session items
	$self->delete_Session(qw/comment comment_id reference/);
}

sub edit_Comment
{
	my($self, $seq) = @_;

	# Get the comment
	my($comment) = grep { $_->{_CW_Id} == $self->get_Request('comment_id') }
		$seq->annotation()->get_Annotations('comment');

	# Make sure the user is allowed to edit it
	if($comment->{_CW_Uid} != $self->get_Session('uid')) {
		$self->add_Para(-title => 'Permission Denied',
			'You are not the owner of this comment and thus cannot edit it.'
		);
		return;
	}

	$self->add_Form(
		-action => 'sequence.pl',
		-method => 'post',
		-name   => 'commentform',
		-input  => [
			-type => 'hidden',
			-name => 'sequence_locator',
			-value => $self->sequence_locator(),
		],
		-input  => [
			-type => 'hidden',
			-name => 'action',
			-value => 'view_Comment',
		],
		-input  => [
			-type => 'hidden',
			-name => 'comment_id',
			-value => $self->get_Request('comment_id'),
		],
		-table => [
			-format => [
				[ -width => '15%' ],
				[ -width => '85%' ],
			],
			-header => [ [ -colspan => 2, 'Edit a comment' ] ],
			-row => [
				'Comment',
				-input => [
					-type  => 'textarea',
					-name  => 'comment',
					-width => 64,
					-height => 10,
					-value => $comment->text(),
				],
			],
			-row => [
				'Reference',
				-input => [
					-type  => 'textarea',
					-name  => 'reference',
					-width => 64,
					-height => 3,
					-value => $comment->{_CW_Reference} || '',
				],
			],
			-header => [
				'Actions:',
				[
					-colspan => 2,
					-input => [
						-type => 'submit',
						-target => 'commentform',
						-name => 'button',
						-value => 'Submit Changes'
					],
				]
			]
		]
	);
}

sub delete_Comment
{
	my($self, $seq) = @_;

	if( not defined $self->get_Request( 'confirmed' ) ) {
		# Get the comment
		my($comment) = grep { $_->{_CW_Id} == $self->get_Request('comment_id') }
			$seq->annotation()->get_Annotations('comment');

		# Make sure the user is allowed to edit it
		if($comment->{_CW_Uid} != $self->get_Session('uid')) {
			$self->add_Para(-title => 'Permission Denied',
				'You are not the owner of this comment and thus cannot delete it.'
			);
			return;
		}

		$self->set_Session(comment_id  => $comment->{_CW_Id});

		$self->add_Para( -title => 'Are you sure?',
			'Really delete this comment? ',
			-list => [
				-link => [ 'yes', sprintf("sequence.pl?action=delete_Comment&amp;confirmed=yes&amp;sequence_locator=%s", $self->sequence_locator()) ],
				-link => [ 'no',  sprintf("sequence.pl?action=delete_Comment&amp;confirmed=no&amp;sequence_locator=%s", $self->sequence_locator()) ],
			]
		);
	} elsif( 'yes' eq $self->get_Request('confirmed') ) {
		# delete it

		my $id = $self->get_Session('comment_id');

		eval {
			$Cellwall::singleton->sql()->delete_Comment(
				$self->get_Session('comment_id'),
				$self->get_Session('uid')
			);
		};
		if($@) {
			$self->add_Para(
				'Unable to delete comment: either its already deleted '.
				'or you don\'t own it.'
			);
		} else {
			# Set the referal
			$self->add_Meta(
				'-http-equiv' => 'Refresh',
				'-content'    => sprintf('5;URL=sequence.pl?sequence_locator=%s', $self->sequence_locator()),
			);

			$self->add_Para( -title => 'Comment deleted',
				'You will be redirected back in 5 seconds. If your browser ' .
				'doesn\'t support this, click ',
				-link => [ 'here', sprintf('sequence.pl?sequence_locator=%s', $self->sequence_locator()) ], '.'
			);
		}

		# Delete all session items
		$self->delete_Session(qw/comment comment_id/);
	} else {
		# Don't delete

		# Set the referal
		$self->add_Meta(
			'-http-equiv' => 'Refresh',
			'-content'    => sprintf('2;URL=sequence.pl?sequence_locator=%s', $self->sequence_locator()),
		);

		$self->add_Para( -title => 'Not deleting comment',
			'You will be redirected back in 2 seconds. If your browser ' .
			'doesn\'t support this, click ',
			-link => [ 'here', sprintf('sequence.pl?sequence_locator=%s', $self->sequence_locator()) ], '.'
		);

		# Delete all session items
		$self->delete_Session(qw/comment comment_id/);
	}
}


sub add_Results
{
	my($self, $seq) = @_;

	# Make sure we have a search id
	if( !defined($self->search_id()) ) {
		$self->add_Para('Invalid Search Id');
		return;
	}

	# Get the search to add:
	my $search = $Cellwall::singleton->get_Search( id => $self->search_id() );
	
	# Make sure we have a search id
	if( !defined($search) ) {
		$self->add_Para('Invalid Search Id');
		return;
	}

	# Add the search
	$search->add_SeqInfo($self, $seq);
}

sub render_Results
{
	my($self, $seq) = @_;

	# Make sure we have a search id
	if( !defined($self->search_id()) ) {
		$self->add_Para('Invalid Search Id');
		return;
	}

	# Get the search to add:
	my $search = $Cellwall::singleton->get_Search( id => $self->search_id() );
	
	# Make sure we have a search id
	if( !defined($search) ) {
		$self->add_Para('Invalid Search Id');
		return;
	}

	# Add the search
	$search->render_SeqInfo($self, $seq);
}

sub build_SeqView
{
	my($self, $seq) = @_;

	# Create a new panel
	my $panel = new Bio::Graphics::Panel(
		-length     => $seq->length(),
		-key_style  => 'between',
		-width      => 600,
		-pad_top    => 5,
		-pad_left   => 10,
		-pad_right  => 10,
		-pad_bottom => 5,
		-bgcolor    => 'white',
	);


	# A feature to span the sequence
	my $entire = new Bio::SeqFeature::Generic(
		-start   => 1,
		-end     => $seq->length(),
		-seq_id  => $seq->accession_number(),
	);

	# Add the ruler
	$panel->add_track(
		$entire,
		-glyph  => 'arrow',
		-bump   => 0,
		-dobule => 1,
		-tick   => 2,
	);

	# Add the sequence track
	$panel->add_track(
		$entire,
		-glypy       => 'generic',
		-bgcolor     => 'blue',
		-font2color  => 'black',
		-label       => $seq->accession_number(),
		-description => $seq->description(),
		-height      => 12
	);

	# We use references for the models and features
	my $models;
	my $features;

	# Loop through all the sequence features
	foreach my $f ($seq->all_SeqFeatures()) {
		# save the tag
		my $tag = $f->primary_tag();
		my $id;

		if( $f->has_tag('feat_name') ) {
			( $id ) = $f->get_tag_values('feat_name');
		} elsif( $f->has_tag('model') ) {
			( $id ) = $f->get_tag_values('model');
		} elsif( $f->has_tag('locus') ) {
			( $id ) = $f->get_tag_values('locus');
		} elsif( $f->has_tag('locus_tag') ) {
			( $id ) = $f->get_tag_values('locus_tag');
		};

		# Put the special cases in their spots
		if($tag eq 'MODEL') {
			$models->{$id}->{MODEL} = $f;
		} elsif($tag eq 'CDS') {
			$models->{$id}->{CDS} = $f;
		} elsif($tag eq 'EXON') {
			$models->{$id}->{EXON} = $f;
		} elsif($tag eq 'LEFT_UTR') {
			push(@{$models->{$id}->{UTR}}, $f);
		} elsif($tag eq 'RIGHT_UTR') {
			push(@{$models->{$id}->{UTR}}, $f);
		} elsif($tag eq 'EXTENDED_UTR') {
			push(@{$models->{$id}->{UTR}}, $f);
		} else {
			push(@{$features->{$f->primary_tag()}}, $f);
		}
	}

	# add tracks for each of the models
	foreach my $k (sort(keys(%$models))) {
		if(defined($models->{$k}->{MODEL})) {
			$panel->add_track(
				$models->{$k}->{MODEL},
				-glyph => 'generic',
				-bgcolor => 'lightblue',
				-fgcolor => 'black',
				-font2color => 'black',
				-key => 'MODEL',
				-label => $k,
				-bump => +1,
				-height => 12
			);
		}

		# Handle the EXONs first
		if(defined($models->{$k}->{EXON})) {
			$panel->add_track(
				$models->{$k}->{EXON},
				-glyph => 'generic',
				-bgcolor => 'cyan',
				-fgcolor => 'black',
				-font2color => 'black',
				-key => 'EXON',
				-bump => +1,
				-height => 12
			);
		}

		# Handle the CDS second
		if(defined($models->{$k}->{CDS})) {
			$panel->add_track(
				$models->{$k}->{CDS},
				-glyph => 'transcript2',
				-bgcolor => 'orange',
				-fgcolor => 'black',
				-font2color => 'black',
				-key => 'CDS',
				-bump => +1,
				-height => 12
			);
		}
		
		# Then the UTRs
		if(defined($models->{$k}->{UTR})) {
			# We want to join all the UTRs onto one line
			my $location = new Bio::Location::Split();

			# Sort the UTRs
			my @utrs = sort {
				$a->start() <=> $b->start()
			} @{$models->{$k}->{UTR}};
		
			# Add each UTR as a sublocation
			foreach my $utr (@utrs) {
				$location->add_sub_Location(
					new Bio::Location::Simple(
						-start => $utr->start(),
						-end   => $utr->end()
					)
				);
			}
		
			# Create a feature for the UTRs
			my $feat = new Bio::SeqFeature::Generic(
				-primary  => 'UTRs',
				-location => $location
			);
		
			# Add the UTRs to the panel
			$panel->add_track(
				$feat,
				-glyph      => 'generic',
				-bgcolor    => 'lime',
				-fgcolor    => 'black',
				-font2color => 'black',
				-key        => 'UTRs',
				-bump       => +1,
				-height     => 12
			);
		}
	}

	return $panel;
}

sub render_SeqView
{
	my($self, $seq) = @_;

	# Make the panel
	my $panel = $self->build_SeqView($seq);

	# Make the background transparent
	$panel->gd()->transparent($panel->bgcolor());

	# Change the MIME-type to png
	$self->mime('image/png');

	# Print the image out
	print $self->headers();
	print $panel->png();

	# Make sure nothing else is printed
	exit(0);
}

sub add_SeqViewMap
{
	my($self, $seq) = @_;

	# Make the panel
	my $panel = $self->build_SeqView($seq);

	# Make all the areas
	my @areas;
	foreach my $box ($panel->boxes()) {
		# Skip it unless there is a tag
		next unless defined($box->[0]->primary_tag());

		my $location;
		if(ref($box->[0]->location()) eq 'Bio::Location::Split') {
			# If the location is split, join each section:
			$location = join(',', map {
					sprintf("%d..%d", $_->start, $_->end())
			} sort { $a->start() <=> $b->start() } ($box->[0]->location()->sub_Location()));
		} else {
			# Make the single location
			$location = sprintf("%d..%d", $box->[0]->start(), $box->[0]->end() );
		}

		# Make the highlight request
		my $hl = sprintf("%s\:%s", $box->[0]->primary_tag(), $location);

		# Push the area
		push(@areas,
			-area => [
				-href   => sprintf("sequence.pl?action=sequence&amp;sequence_locator=%s&amp;highlight=%s", $self->sequence_locator(), $hl),
				-shape  => 'rect',
				-coords => [ $box->[1], $box->[2], $box->[3], $box->[4] ],
			]
		);
	}

	$self->add_Contents(
		-map => [
			-name => 'seqview',
			@areas,
		]
	);
}

sub download_Sequence
{
	my($self, $seq) = @_;

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
		$seqout->write_seq($seq);
	} elsif( $self->format() eq 'fasta' ) {
		# Open STDOUT as a SeqIO
		my $seqout = new Bio::SeqIO(
			-format => 'fasta',
			-fh     => \*STDOUT,
		);

		# Print each protein
		$seqout->write_seq($_) foreach ($seq, $seq->get_all_Proteins());
	}

	# Now exit to prevent anything else from being printed
	exit(0);
}


sub sequence
{
	my($self, $seq) = @_;
	if( @_ == 2 ) {
		$self->{_sequence} = $seq;
	}
	return $self->{_sequence};
}

sub sequence_id
{
	my($self, $id) = @_;
	$self->{_sequence_id} = $id if @_ == 2;
	return $self->{_sequence_id};
}

sub sequence_accession
{
	my($self, $id) = @_;
	$self->{_sequence_accession} = $id if @_ == 2;
	return $self->{_sequence_accession};
}

sub sequence_protein
{
	my($self, $id) = @_;
	$self->{_sequence_protein} = $id if @_ == 2;
	return $self->{_sequence_protein};
}

sub action
{
	my($self, $id) = @_;
	$self->{_action} = $id if @_ == 2;
	return $self->{_action} || 'sequence';
}

sub format
{
	my($self, $id) = @_;
	$self->{_format} = $id if @_ == 2;
	return $self->{_format} || 'genbank';
}

sub highlight
{
	my($self, @segments) = @_;
	$self->{_highlight} = \@segments if @_ >= 2;
	return defined($self->{_highlight}) ? @{$self->{_highlight}} : ();
}

sub search_id
{
	my($self, $id) = @_;
	$self->{_search_id} = $id if @_ == 2;
	return $self->{_search_id};
}

sub database_id
{
	my($self, $id) = @_;
	$self->{_database_id} = $id if @_ == 2;
	return $self->{_database_id};
}

sub genome_id
{
	my($self, $id) = @_;
	$self->{_genome_id} = $id if @_ == 2;
	return $self->{_genome_id};
}

sub sequence_locator
{
	my($self, $locator, $keywords) = @_;

	if( defined $locator ) {
		# Parse the locator:
		my %ids = map { split(/:/o, $_) } split(/;/o, $locator);

		# Set the IDs
		$self->genome_id($ids{genome_id})                   if defined $ids{genome_id};
		$self->database_id($ids{database_id})               if defined $ids{database_id};
		$self->sequence_id($ids{sequence_id})               if defined $ids{sequence_id};
		$self->sequence_accession($ids{sequence_accession}) if defined $ids{sequence_accession};
		$self->sequence_protein($ids{sequence_protein})     if defined $ids{sequence_protein};
	}

	# We need to be able to override the keywords used in the locator
	if(not defined $keywords) {
		$keywords = "genome_id database_id sequence_id sequence_accession
		               sequence_protein";
	}

	# Make and return the locator tag
	return join(';', map { sprintf('%s:%s', $_, $self->$_()) } 
		grep { defined $self->$_() } split(/\s+/o, $keywords));
}

1;
