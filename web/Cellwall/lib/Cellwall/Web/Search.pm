# vim:sw=4 ts=4
# $Id: CGI.pm 2 2004-04-01 23:09:24Z laurichj $

=head1 NAME

Cellwall::Web::Search

=head1 DESCRIPTION

This is the module for the Search information page.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Web::Search;
use Bio::SeqIO;
use Bio::TreeIO;
use Bio::Graphics;
use Bio::Graphics::Image;
use Bio::Graphics::Widget::Tree;
use Cellwall;
use Error;
use base qw/Cellwall::Web::Index/;
use strict;

my %view_formats = (
	html => 'HTML',
	tab  => 'Tab Seperated',
	csv  => 'Comma Seperated',
);

my %view_perpage = (
	1 =>   25,
	2 =>   50,
	3 =>  100,
	4 =>  150,
	5 =>  250,
	6 =>  500,
	7 => 1000,
);

my %view_orders = (
	query    => 'Query',
	subject  => 'Subject',
	e        => 'E-Value',
	score    => 'Score',
	bits     => 'Bits',
	organism => 'Subject Organism',
);

sub new
{
	my $class = shift;

	# Call the inherited new
	my $self = $class->SUPER::new(@_);

	# Set some defaults

	# Allow the hspsearchform through
	$self->allow_Request( step                => '^\s*(\w+)\s*$'                                           );
	$self->allow_Request( form                => '^\s*(\w+)\s*$'                                           );
	$self->allow_Request( page                => '^(\d+)$'                                                 );
	$self->allow_Request( query_accession     => '^\s*([\w\*\.]+)\s*$'                                       );
	$self->allow_Request( query_description   => '(\S+)|(\"[^\"]+)'                                        );
	$self->allow_Request( query_mutant        => '(\S+)|(\"[^\"]+)'                                        );
	$self->allow_Request( query_comment       => '(\S+)|(\"[^\"]+)'                                        );
	$self->allow_Request( subject_accession   => '^\s*([\w\*\.]+)\s*$'                                       );
	$self->allow_Request( subject_description => '(\S+)|(\"[^\"]+)'                                        );
	$self->allow_Request( subject_species     => '(\S+)|(\"[^\"]+)'                                        );
	$self->allow_Request( hsp_e               => '^\s*([<>=]{0,1}\s*[+-]?\s*\d+(?:\.\d+)?(?:e[+-]?\d+)?)$' );
	$self->allow_Request( hsp_score           => '^\s*([<>=]{0,1}\s*[+-]?\s*\d+(?:\.\d+)?(?:e[+-]?\d+)?)$' );
	$self->allow_Request( hsp_length          => '^\s*([<>=]{0,1}\s*[+-]?\s*\d+(?:\.\d+)?(?:e[+-]?\d+)?)$' );
	$self->allow_Request( view_format         => '^\s*(\w+)\s*$'                                           );
	$self->allow_Request( view_perpage        => '^\s*(\d+)\s*$'                                           );
	$self->allow_Request( view_order          => '^\s*(\w+)\s*$'                                           );

	return $self;
}

sub parse
{
	my($self) = @_;

	# Call the inherited parse
	$self->SUPER::parse();

	if( defined($self->get_Request('form')) ) {
		# Do the form we're handling
		$self->set_Session('form', $self->get_Request('form'));
	}
}

sub add_SearchForm
{
	my($self) = @_;

	# Add the query search form:
	$self->add_Form(
		-action => 'search.pl',
		-method => 'get',
		-name   => 'queryform',
		-input  => [
			-type => 'hidden',
			-name => 'step',
			-value => 'submit',
		],
		-input  => [
			-type => 'hidden',
			-name => 'form',
			-value => 'query',
		],
		-table => [
			-format => [
				[ -valign => 'top', -width => '20%', -align => 'left' ],
				[ -valign => 'top', -width => '80%', -align => 'left' ]
			],
			-header => [ [ -colspan => 2, 'Search Family Sequences:' ] ],
			-row => [ [ -colspan => 2,
				'This form allows searches against the family sequences in the ' .
				'CWN database. The search terms are pattern matching keywords in ' .
				'which all words must match.'
			] ],
			-header => [ [ -colspan => 2, 'Sequence' ] ],
			-row => [
				'Accession:',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'query_accession',
				],
			],
			-row => [
				'Mutant',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'query_mutant',
				],
			],
			-row => [
				'Description:',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'query_description',
				],
			],
			-row => [
				'User Comments',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'query_comment',
				],
			],
			-header => [
				'Action:',
				-input => [
					-type   => 'submit',
					-target => 'queryform',
					-value  => 'Submit',
				]
			],
		]
	);

	# Add the Family Protein blast form:
	$self->add_Form(
		-action => 'wwwblast/blast.cgi',
		-method => 'post',
		-enctype => "multipart/form-data",
		-input  => [ -type => 'hidden', -name => 'DATALIB', -value => 'fam_pep' ],
		-table => [
			-format => [
				[ -width => "20%", -valign => 'top' ],
				[ -width => "80%", -valign => 'top' ]
			],
			-header => [
				[ -colspan => 2, 'BLAST Search' ]
			],
			-row => [
				'Program: ',
				-input  => [
					-type => 'dropdown',
					-name => 'PROGRAM',
					-value => { map { $_ => $_ } qw/blastp blastx tblastx/},
					-default => 'blastp'
				],
			],
			-row => [
				'Sequence',
				-input  => [
					-type => 'textarea',
					-name => 'SEQUENCE',
					-width => 64,
					-height => 10,
				],
			],
			-row => [
				'Actions:',
				-input  => [ -type => 'submit', -name => 'action', -value => 'Search' ],
			],
		],
	);

	

	# Add the hsp search form:
	$self->add_Form(
		-action => 'search.pl',
		-method => 'get',
		-name   => 'hspqueryform',
		-input  => [
			-type => 'hidden',
			-name => 'step',
			-value => 'submit',
		],
		-input  => [
			-type => 'hidden',
			-name => 'form',
			-value => 'hsp',
		],
		-table => [
			-format => [
				[ -valign => 'top', -width => '20%', -align => 'left' ],
				[ -valign => 'top', -width => '80%', -align => 'left' ]
			],
			-header => [ [ -colspan => 2, 'Search EST BLAST results:' ] ],
			-row => [ [ -colspan => 2,
				'This form allows searches against the '.
				'EST BLAST results (HSPs) within the database. Any values in the form that '.
				'are left blank are ignored. For numeric values (ie: e-values) decimal or '.
				'scientific notation may be used. Numeric values may also be prefixed with '.
				' >, <, or = to restrict to greater than, less than and equal to, respectivly. '.
				'If no relationship modifier is presented, it will assume you want a "better" '.
				'match. For alphanumeric values the expression is a glob pattern where ? matches '.
				'any zero or one charactor and * matches zero or more. '
			] ],
			-header => [ [ -colspan => 2, 'Query Sequence' ] ],
			-row => [
				'Accession:',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'query_accession',
				],
			],
			-row => [
				'Description:',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'query_description',
				],
			],
			-header => [ [ -colspan => 2, 'Subject Sequence' ] ],
			-row => [
				'Accession:',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'subject_accession',
				],
			],
			-row => [
				'Description:',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'subject_description',
				],
			],
			-row => [
				'Species',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'subject_species',
				],
			],
			-header => [ [ -colspan => 2, 'High Scoring Pair' ] ],
			-row => [
				'E-Value:',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'hsp_e',
				],
			],
			-row => [
				'Score:',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'hsp_score',
				],
			],
			-row => [
				'Length:',
				-input => [
					-type  => 'text',
					-width => '64',
					-name  => 'hsp_length',
				],
			],
			-header => [ [ -colspan => 2, 'Output' ] ],
			-row => [
				'Format:',
				-input => [
					-type    => 'dropdown',
					-name    => 'view_format',
					-value   => \%view_formats,
					-order   => 'key',
					-default => 'html',
				],
			],
			-row => [
				'Results Per Page:',
				-input => [
					-type    => 'dropdown',
					-name    => 'view_perpage',
					-value   => \%view_perpage,
					-order   => 'key',
					-default => 3,
				],
			],
			-row => [
				'Sort Order:',
				-input => [
					-type    => 'dropdown',
					-name    => 'view_order',
					-value   => \%view_orders,
					-default => 'e',
				],
			],
			-header => [
				'Action:',
				-input => [
					-type   => 'submit',
					-target => 'hspqueryform',
					-value  => 'Submit',
				]
			],
		]
	);
}

sub submit_Search
{
	my($self) = @_;

	# Submit the search
	if( $self->get_Session('form') eq 'hsp' ) {
		$self->submit_HSPSearch();
	} elsif( $self->get_Session('form') eq 'query' ) {
		$self->submit_QuerySearch();
	}
}

sub show_Search
{
	my($self) = @_;

	# Show the search
	if( $self->get_Session('form') eq 'hsp' ) {
		$self->show_HSPSearch();
	} elsif( $self->get_Session('form') eq 'query' ) {
		$self->show_QuerySearch();
	}
}

sub build_HSPQuery
{
	my($self) = @_;

	# Save some typing latter on:
	my $query_accession     = $self->get_Request('query_accession');
	my @query_description   = $self->get_Request('query_description');
	my $subject_accession   = $self->get_Request('subject_accession');
	my @subject_description = $self->get_Request('subject_description');
	my @subject_species     = $self->get_Request('subject_species');
	my $hsp_e               = $self->get_Request('hsp_e');
	my $hsp_score           = $self->get_Request('hsp_score');
	my $hsp_length          = $self->get_Request('hsp_length');
	my $view_order          = $self->get_Request('view_order') || 'e';

	# The terms comprising the WHERE statement
	my @where;

	# Check for the query accession
	if( defined( $query_accession ) ) {
		$query_accession =~ tr/*/%/;
		push(@where, sprintf('query.accession LIKE "%%%s%%"', $query_accession));
	}

	# Deal with each description term
	foreach my $term (@query_description) {
		$term =~ tr/*/%/;
		push(@where, sprintf('query.description LIKE "%%%s%%"', $term));
	}

	# Check for the subject accession
	if( defined( $subject_accession ) ) {
		$subject_accession =~ tr/*/%/;
		push(@where, sprintf('subject.accession LIKE "%%%s%%"', $subject_accession));
	}

	# Deal with each description term
	foreach my $term (@subject_description) {
		$term =~ tr/*/%/;
		push(@where, sprintf('subject.description LIKE "%%%s%%"', $term));
	}

	# Deal with each species term
	foreach my $term (@subject_species) {
		$term =~ tr/*/%/;
		push(@where, sprintf('species.common_name LIKE "%%%s%%"', $term));
	}

	# These are used in the following blocks
	my($op, $value);

	# Deal with the e-value
	if(defined($hsp_e)) {
		if( ($op, $value) = ( $hsp_e =~ /^\s*([<>=]{1})\s*([-]?\s*\d+(?:\.\d+)?(?:e[+-]?\d+)?)$/o ) ) {
			# We have an operation
			push(@where, sprintf('hsp.e %s %s', $op, $value));
		} elsif( ($value) = ( $hsp_e =~ /^\s*([-]?\s*\d+(?:\.\d+)?(?:e[+-]?\d+)?)$/o ) ) {
			# No operation, since we're the E-Val we want one lower than or equal
			push(@where, sprintf('hsp.e <= %s', $value));
		} else {
			throw Error::Simple("an e-val parameter couldnt be handled: " . $hsp_e);
		}
	}

	# Deal with the score
	if( defined($hsp_score) ) {
		if( ($op, $value) = ( $hsp_score =~ /^\s*([<>=]{1})\s*([-]?\s*\d+(?:\.\d+)?(?:e[+-]?\d+)?)$/o ) ) {
			# We have an operation
			push(@where, sprintf('hsp.score %s %s', $op, $value));
		} elsif( ($value) = ( $hsp_score =~ /^\s*([-]?\s*\d+(?:\.\d+)?(?:e[+-]?\d+)?)$/o ) ) {
			# No operation, since we're the score we want one greather than or equal
			push(@where, sprintf('hsp.score >= %s', $value));
		} else {
			throw Error::Simple('an eval parameter couldnt be handled');
		}
	}

	# Deal with the length
	if( defined($hsp_length) ) {
		if( ($op, $value) = ( $hsp_length =~ /^\s*([<>=]{1})\s*([-]?\s*\d+(?:\.\d+)?(?:e[+-]?\d+)?)$/o ) ) {
			# We have an operation
			push(@where, sprintf('(hsp.query_length %s %s OR hsp.hit_length %s %s)', $op, $value, $op, $value));
		} elsif( ($value) = ( $hsp_length =~ /^\s*([-]?\s*\d+(?:\.\d+)?(?:e[+-]?\d+)?)$/o ) ) {
			# No operation, since we're the length we want one greather than or equal
			push(@where, sprintf('(hsp.query_length >= %s OR hsp.hit_length >= %s)', $value, $value));
		} else {
			throw Error::Simple('an eval parameter couldnt be handled');
		}
	}

	# Now we make the SQL query.
	my $query = 'SELECT STRAIGHT_JOIN query.id, query.accession, family.id, family.abrev, subject.id, subject.accession, search.genome, search.db, species.common_name, hsp.id, hsp.e, hsp.score, hsp.bits FROM blast_hsp AS hsp JOIN sequence AS query ON query.id = hsp.query JOIN family on family.id = query.family JOIN blast_hit AS subject ON subject.id = hsp.hit JOIN species ON species.id = subject.species JOIN search on search.id = subject.search';

	if(scalar(@where) > 0) {
		# Add there where clause
		$query .= ' WHERE ' . join(' AND ', @where)
	}

	# Add the sort order
	if( $view_order eq 'e' ) {
		$query .= ' ORDER BY hsp.e';
	} elsif( $view_order eq 'query' ) {
		$query .= ' ORDER BY query.accession';
	} elsif( $view_order eq 'subject' ) {
		$query .= ' ORDER BY subject.accession';
	} elsif( $view_order eq 'bits' ) {
		$query .= ' ORDER BY hsp.bits DESC';
	} elsif( $view_order eq 'score' ) {
		$query .= ' ORDER BY hsp.score DESC';
	} elsif( $view_order eq 'organism' ) {
		$query .= ' ORDER BY species.genus, species.species';
	}

	# Limit it to 25,000
	$query = "$query LIMIT 25000";

	return $query;
}

sub submit_HSPSearch
{
	my($self) = @_;

	# Build the query
	my $query = $self->build_HSPQuery();

	# Save the query
	$self->set_Session('query', $query);

	# Save the format and page count
	$self->set_Session('format',  $self->get_Request('view_format')  || 'html' );
	$self->set_Session('perpage', $view_perpage{ $self->get_Request('view_perpage') } || $view_perpage{3});

	# Clear the request, if its there
	$self->set_Session('results', undef);

	# Redirect them to the results
	$self->add_Meta(
		'-http-equiv' => 'Refresh',
		'-content'    => sprintf('0;URL=http://%s%s?step=show&amp;page=0', $ENV{SERVER_NAME} || $ENV{SERVER_ADDR}, $ENV{SCRIPT_NAME})
	);

	# Tell the user to chill for a second
	$self->add_Para(
		-title => 'Searching Database',
		'Your query is being processed, please be patient as this may take a while. There is a twenty-five thousand high scoring pair limit on search results.',
	);
}

sub run_Query
{
	my($self) = @_;

	# Get the query
	my $query = $self->get_Session('query');

	# Raise an exception if we don't have the query
	throw Error::Simple('running without query') unless defined $query;

	# get the query object
	my $sth = $Cellwall::singleton->sql()->prepare($query);

	# Execute the query
	$sth->execute();

	# Get the results
	my $results = $sth->fetchall_arrayref();

	# Store the results
	$self->set_Session('results', $results);
}

sub show_HSPSearch
{
	my($self) = @_;

	# Check to see if we have results to show:
	my $results = $self->get_Session('results');

	if(!defined($results)) {
		# No results, lets run the query
		$self->run_Query();
		$results = $self->get_Session('results');
	}

	# Get the format
	my $format = $self->get_Session('format');

	# Check the format
	if( 'html' eq $format ) {
		$self->show_HSPResultsHTML($results);
	} elsif( 'tab' eq $format ) {
		$self->show_HSPResultsTab($results);
	} elsif( 'csv' eq $format ) {
		$self->show_HSPResultsCSV($results);
	}
}

sub show_HSPResultsHTML
{
	my($self, $results) = @_;

	# Get the count per page
	my $perpage = $self->get_Session('perpage');

	# Get the page
	my $page = $self->get_Request('page') || 0;

	# Check to see if we have that page:
	if( !defined($results->[$page * $perpage]) ) {
		# Whoops... no page
		$self->error("The page $page is not within the rage of results");
	}

	# The rows are in the form:
	# query.id, query.accession, family.id, family.abrev, subject.id,
	# subject.accession, subject.genome, sub.db, subject.spec, hsp.id,
	# hsp.e, hsp.score, hsp.bits

	# Add the page to the page...
	$self->add_Table(
		-format => [
			[ -valign => 'top', -width => '20%', -align => 'left' ],
			[ -valign => 'top', -width =>  '5%', -align => 'left' ],
			[ -valign => 'top', -width => '15%', -align => 'left' ],
			[ -valign => 'top', -width => '30%', -align => 'left' ],
			[ -valign => 'top', -width => '10%', -align => 'right' ],
			[ -valign => 'top', -width => '10%', -align => 'right' ],
			[ -valign => 'top', -width => '10%', -align => 'right' ],
		],
		-header => [ 'Query:', 'Family:', 'Subject:', 'Subject Species:', 'E-Value:', 'Score:', 'Bits:' ],
		(map {
				-row => [
					[ -link => [ $_->[1], sprintf('sequence.pl?sequence_id=%d', $_->[0]) ] ],
					[ -link => [ $_->[3], sprintf('family.pl?family_id=%d', $_->[2]) ] ],
					defined($_->[6]) ? (
						[ -link => [ $_->[5], sprintf('sequence.pl?sequence_accession=%s&amp;genome_id=%d', $_->[5], $_->[6]) ]],
					) : (
						[ -link => [ $_->[5], sprintf('sequence.pl?sequence_accession=%s&amp;database_id=%d', $_->[5], $_->[7]) ]],
					),
					@$_[8, 10, 11, 12]
				]
		} ( grep { defined $_ } ( @$results[ $page * $perpage .. ( $page*$perpage + $perpage < scalar(@$results) ? $page*$perpage + $perpage : scalar(@$results)) ] ) ) ),
		-header => [
			[ -align => 'left',
				$page > 0 ?
				(
					-list => [ -link => [ 'Previous', 	sprintf('search.pl?step=show&amp;page=%d', $page - 1), ], ]
				) : (
					'[ Previous ]'
				)
			],
			[ -colspan => 5, -align => 'center', sprintf('Showing %d to %d of %d', $page*$perpage, $page*$perpage + $perpage < scalar(@$results) ? $page*$perpage + $perpage : scalar(@$results), scalar(@$results)) ],
			[ -align => 'right',
				defined($results->[ $page*$perpage + $perpage ]) ?
				(
					-list => [ -link => [ 'Next', sprintf('search.pl?step=show&amp;page=%d', $page + 1), ], ]
				) : (
					'[ Next ]'
				)
			],
		],
	);
}

sub show_HSPResultsTab
{
	my($self, $results) = @_;

	# Change the MIME type
	$self->mime('text/plain');
	print $self->headers();

	# Print the header
#	print join("\t", 'QueryID', 'Query Accession', 'SubjectID',
#	                 'Subject Accession', 'Subject Search', 'Subject Species',
#	                 'HSP ID', 'E-Value', 'Score', 'Bits'
#	), "\n";

	# Print the results
	print join("\t", @$_), "\n" foreach @$results;

	# Make sure nothing else is printed
	exit(0);
}

sub show_HSPResultsCSV
{
	my($self, $results) = @_;

	# Change the MIME type
	$self->mime('text/plain');
	print $self->headers();

	# Print the header
#	print join(", ", map { sprintf('"%s"', $_) } (
#	                 'QueryID', 'Query Accession', 'SubjectID',
#	                 'Subject Accession', 'Subject Search', 'Subject Species',
#	                 'HSP ID', 'E-Value', 'Score', 'Bits'
#	)), "\n";

	# Print the results
	foreach my $row ( @$results ) {
		print join(', ', map { sprintf('"%s"', $_) } @$row), "\n";
	}

	# Make sure nothing else is printed
	exit(0);
}

sub build_QQuery
{
	my($self) = @_;

	# Save some typing latter on:
	my $query_accession     = $self->get_Request('query_accession');
	my @query_mutant        = $self->get_Request('query_mutant');
	my @query_description   = $self->get_Request('query_description');
	my @query_comment       = $self->get_Request('query_comment');

	# The terms comprising the WHERE statement
	my @where;

	# Check for the query accession
	if( defined( $query_accession ) ) {
		$query_accession =~ tr/*/%/;
		push(@where, sprintf('idxref.accession LIKE "%%%s%%"', $query_accession));
	}

	# Do the mutant stuff
	foreach my $term (@query_mutant) {
		$term =~ tr/*/%/;
		my @or;
		push(@or, sprintf('query.gene_name LIKE "%%%s%%"', $term));
		push(@or, sprintf('query.fullname LIKE "%%%s%%"', $term));
		push(@or, sprintf('query.alt_fullname LIKE "%%%s%%"', $term));
		push(@or, sprintf('query.symbols LIKE "%%%s%%"', $term));
		push(@where, sprintf('( %s )', join(' OR ', @or)));
	}

	# Deal with each description term
	foreach my $term (@query_description) {
		$term =~ tr/*/%/;
		push(@where, sprintf('query.description LIKE "%%%s%%"', $term));
	}

	# Deal with each comment term
	foreach my $term (@query_comment) {
		$term =~ tr/*/%/;
		push(@where, sprintf('comment.comment LIKE "%%%s%%"', $term));
	}

	# Now we make the SQL query.
	my $query = 'SELECT query.id, query.accession, family.abrev, query.description FROM sequence AS query JOIN family ON family.id = query.family';

	# Join the idxref if there is an ID search
	if(defined $query_accession) {
		$query = "$query JOIN idxref ON idxref.sequence = query.id ";
	}
	
	if(scalar(@query_comment) > 0) {
		# If there is a comment term, join on the comment table
		$query = "$query JOIN comment ON comment.sequence = query.id";
	}

	if(scalar(@where) > 0) {
		# Add there where clause
		$query .= ' WHERE ' . join(' AND ', @where)
	}

	# Add the grouping and sort order
	$query .= ' GROUP BY query.id ORDER BY query.id';

	return $query;
}

sub submit_QuerySearch
{
	my($self) = @_;

	# Build the query
	my $query = $self->build_QQuery();

	# Save the query
	$self->set_Session('query', $query);

	# Clear the request, if its there
	$self->set_Session('results', undef);

	# Redirect them to the results
	$self->add_Meta(
		'-http-equiv' => 'Refresh',
		'-content'    => sprintf('0;URL=http://%s%s?step=show', $ENV{SERVER_NAME} || $ENV{SERVER_ADDR}, $ENV{SCRIPT_NAME})
	);

	# Tell the user to chill for a second
	$self->add_Para(
		-title => 'Searching Database',
		'Your query is being processed, please be patient as this may take a while.',
	);
}

sub show_QuerySearch
{
	my($self) = @_;

	# Check to see if we have results to show:
	my $results = $self->get_Session('results');

	if(!defined($results)) {
		# No results, lets run the query
		$self->run_Query();
		$results = $self->get_Session('results');
	}

	# Add the table
	$self->add_Table(
		-format => [
			[ -valign => 'top', -width => '15%', -align => 'left' ],
			[ -valign => 'top', -width => '10%', -align => 'left' ],
			[ -valign => 'top', -width => '75%', -align => 'left' ],
		],
		-header => [ 'Accession:', 'Family:', 'Description:' ],
		map {
				-row => [
					[ -link => [ $_->[1], sprintf('sequence.pl?sequence_id=%d', $_->[0]) ] ],
					$_->[2],
					$_->[3],
				]
		} @$results
	);
}

1;

