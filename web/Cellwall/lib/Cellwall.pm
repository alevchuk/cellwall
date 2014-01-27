# vim:sw=4 ts=4
# $Id: Cellwall.pm 152 2005-08-10 22:03:28Z laurichj $

=head1 NAME

Cellwall - access to the cellwall system

=head1 SYNOPSIS

	use Cellwall;

	my $cw = new Cellwall();
	
	...

=head1 DESCRIPTION

Access to the Cellwall MySQL database, flat files and cached objects
through a simple object system.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall;
use Carp;
use Cellwall::Database;
use Cellwall::Executor;
use Cellwall::Family;
use Cellwall::Genome;
use Cellwall::Group;
use Cellwall::Search;
use Cellwall::Sequence;
use Cellwall::Species;
use Cellwall::SQL;
use DBI;
use XML::Twig;

use base qw/Cellwall::Root/; 
use vars qw/@ACCESSORS $singleton $parallel %colors/;
use strict;

@ACCESSORS = qw/host db user password base/;
Cellwall->mk_accessors(@ACCESSORS);

# We only want one Cellwall to be created
$singleton = undef;

BEGIN {
	# Setup the colors
	%colors = (
		blue      => [ '00', '00', 'FF' ],
		lightblue => [ 'AD', 'D8', 'E6' ],
		cyan      => [ '00', 'FF', 'FF' ],
		orange    => [ 'FF', 'A5', '00' ],
		lime      => [ '00', 'FF', '00' ],
		darkblue  => [ '00', '00', '8B' ],
		darkred   => [ '8B', '00', '00' ],
		orangered => [ 'FF', '45', '00' ],
		darkgreen => [ '00', '64', '00' ],
	);
}

=head2 new

 Title   : new
 Usage   : $cw = new Cellwall()
 Function: Creates a cellwall object
 Returns : a Cellwall object
 Args    :

=cut

sub new
{
	my $class = shift @_;

	# Just return the old cellwall if its there
	return $singleton if defined($singleton);

	# Create a new Cellwall
	$singleton = $class->SUPER::new(@_);

	return $singleton;
}

=head2 add_Genome

 Title   : add_Genome
 Usage   : $cw->add_Genome($genome);
 Function: Add a genome object to the Cellwall object
 Returns :
 Args    : A Cellwall::Genome object

=cut

sub add_Genome
{
	my($self, $genome) = @_;
	throw Error::Simple('argument must be a Cellwall::Genome')
		unless defined($genome) and $genome->isa('Cellwall::Genome');
	
	$self->_add_Index('genomes', $genome,
		name => lc $genome->name(),
		id   =>    $genome->id(),
	);
}

=head2 add_Database

 Title   : add_Database
 Usage   : $cw->add_Database($db);
 Function: Add a database object to the Cellwall object
 Returns :
 Args    : A Cellwall::Database object

=cut

sub add_Database
{
	my($self, $db) = @_;
	throw Error::Simple('argument must be a Cellwall::Database')
		unless defined($db) and $db->isa('Cellwall::Database');
	
	$self->_add_Index('databases', $db,
		name => lc $db->name(),
		id   =>    $db->id()
	);
}

=head2 add_Group

 Title   : add_Group
 Usage   : $cw->add_Group($db);
 Function: Add a group object to the Cellwall object
 Returns :
 Args    : A Cellwall::Group object

=cut

sub add_Group
{
	my($self, $group) = @_;
	throw Error::Simple('argument must be a Cellwall::Group')
		unless defined($group) and $group->isa('Cellwall::Group');
	
	$self->_add_Index('groups', $group,
		name => lc $group->name(),
		id   =>    $group->id(),
	);
}

=head2 add_Family

 Title   : add_Family
 Usage   : $cw->add_Family($db);
 Function: Add a family object to the Cellwall object
 Returns :
 Args    : A Cellwall::Family object

=cut

sub add_Family
{
	my($self, $family) = @_;
	
	$self->_add_Index('families', $family,
		name  => lc $family->name(),
		abrev => lc $family->abrev(),
		id    =>    $family->id(),
	);
}

=head2 add_Sequence

 Title   : add_Sequence
 Usage   : $cw->add_Sequence($db);
 Function: Add a sequence object to the Cellwall object
 Returns :
 Args    : A Cellwall::Sequence object

=cut

sub add_Sequence
{
	my($self, $seq) = @_;

	$self->_add_Index('sequences', $seq,
		id => $seq->primary_id(),
		map { ( 'accession_number',  $_->accession_number() ) } ($seq->get_all_Proteins())
	);
}

=head2 add_Search

 Title   : add_Search
 Usage   : $cw->add_Search($search);
 Function: Add a database object to the Cellwall object
 Returns :
 Args    : A Cellwall::Search object

=cut

sub add_Search
{
	my($self, $search) = @_;
	throw Error::Simple('argument must be a Cellwall::Search')
		unless defined($search) and $search->isa('Cellwall::Search');

	$self->_add_Index('searches', $search,
		name => lc $search->name,
		id   =>    $search->id(),
	);
}

=head2 get_Genome

 Title   : get_Genome
 Usage   : $genome = $cw->get_Genome( name => 'ESTs');
 Function: get a genome
 Returns : a Cellwall::Genome object
 Args    : the name of the genome

=cut

sub get_Genome
{
	my($self, $index, $value) = @_;
	($index, $value) = ( name => $index ) unless defined $value;

	return $self->_get_Index('genomes',
		$index => lc $value
	);
}

=head2 get_all_Genomes

 Title   : get_all_Genomes
 Usage   : @genomes = $cw->get_all_Genomes();
 Function: get an array of Genomes
 Returns : 
 Args    : And array of Cellwall::Genome objects

=cut

sub get_all_Genomes
{
	my($self) = @_;
	return $self->_get_Array('genomes');
}


=head2 get_Database

 Title   : get_Database
 Usage   : $db = $cw->get_Database('ESTs');
 Function: get a database
 Returns : a Cellwall::Database object
 Args    : the name of the database

=cut

sub get_Database
{
	my($self, $index, $value) = @_;
	($index, $value) = ( 'name' , $index ) unless defined $value;

	return $self->_get_Index('databases',
		$index => lc $value
	);
}

=head2 get_all_Databases

 Title   : get_all_Databases
 Usage   : @dbs = $cw->get_all_Databases();
 Function: get all database
 Returns : an array of databases
 Args    : 

=cut

sub get_all_Databases
{
	my($self) = @_;
	return $self->_get_Array('databases');
}

=head2 get_Search

 Title   : get_Search
 Usage   : $search $cw->get_Search('ESTs');
 Function: get a search
 Returns : a Cellwall::Search object
 Args    : the name of the search

=cut

sub get_Search
{
	my($self, $index, $value) = @_;
	($index, $value) = ( name => $index ) unless defined $value;

	return $self->_get_Index('searches',
		$index => lc $value
	);
}

=head2 get_all_Searches

 Title   : get_all_Searches
 Usage   : @searches $cw->get_all_Searches();
 Function: get all the search objects
 Returns : an array of Cellwall::Search objects
 Args    :

=cut

sub get_all_Searches
{
	my($self) = @_;
	return $self->_get_Array('searches');
}

=head2 get_Group

 Title   : get_Group
 Usage   : $group = $cw->get_Group('ESTs');
 Function: get a group
 Returns : a Cellwall::Group object
 Args    : the name of the group

=cut

sub get_Group
{
	my($self, $index, $value) = @_;
	($index, $value) = ( name => $index ) unless defined $value;

	return $self->_get_Index('groups',
		$index => lc $value
	);
}

=head2 get_all_Groups

 Title   : get_all_Groups
 Usage   : @groups = $cw->get_all_Groups();
 Function: get all groups
 Returns : an array of Cellwall::Group objects
 Args    :

=cut

sub get_all_Groups
{
	my($self) = @_;
	return $self->_get_Array('groups');
}

=head2 get_Family

 Title   : get_Family
 Usage   : $family = $cw->get_Family($name);
 Function: get a family
 Returns : a Cellwall::Family object
 Args    : the name of the family

=cut

sub get_Family
{
	my($self, $index, $value) = @_;
	($index, $value) = ( name => $index ) unless defined $value;

	# Get the family from the cache
	my $family = $self->_get_Index('families', $index => lc $value);

	if(not defined $family) {
		# The family hasn't been fetched from the database
		$family = $self->sql()->get_Family( $index => $value );
	}

	if(	not defined $family->get_all_Sequences() ) {
		# There are no sequences, so fetch them
		my @seqs = $self->sql()->get_family_Sequences($family->id());
		
		foreach my $seq (@seqs) {
			# Add the sequence to the cellwall
			$self->add_Sequence($seq);
			
			# Add it to the family
			$family->add_Sequence($seq);
		}
	}

	return $family;
}

=head2 get_all_Families

 Title   : get_all_Families
 Usage   : @families = $cw->get_all_Families();
 Function: get all families
 Returns : an array of Cellwall::Family objects
 Args    :

=cut

sub get_all_Families
{
	my($self) = @_;
	return $self->_get_Array('families');
}

=head2 get_Sequence

 Title   : get_Sequence
 Usage   : $seq = $cw->get_Sequence($name);
 Function: get a sequence
 Returns : a Cellwall::Sequence object
 Args    : the name of the sequence

=cut

sub get_Sequence
{
	my($self, $index, $value) = @_;
	($index, $value) = ( name => $index ) unless defined $value;

	my $seq = $self->_get_Index('sequences', $index => $value );

	if( not defined $seq ) {
		# Get it from the SQL database
		$seq = $self->sql()->get_Sequence($index => $value);
		$self->add_Sequence($seq);
	}

	return $seq;
}

=head2 get_all_Proteins

 Title   : get_all_Proteins
 Usage   : @seqs = $cw->get_all_Proteins();
 Function: Get the proteins in the cellwall
 Returns : an array of sequnce objects
 Args    : 

=cut

sub get_all_Proteins
{
	my($self) = @_;
	my @proteins;

	foreach my $family ($self->get_all_Families()) {
		push(@proteins, $family->get_all_Proteins());
	}

	return wantarray ? @proteins : \@proteins;
}

=head2 load

 Title   : load
 Usage   : $cw->load('input.xml');
 Function: To load the database, search, group and family infromation
           into the cellwall object.
 Returns : 
 Args    : A filename to load

=cut

# Load can use XML::Twig since Cellwall is a singleton object, so instead
# of passing $self, we use $singleton, some day I might want to switch to
# XML::SAX and get some slightly cleaner code

sub load
{
	my($self, $file) = @_;
	throw Error::Simple("need a filename to load") unless defined $file;

	my $twig = new XML::Twig(
		twig_handlers => {
			'cellwall/genome'   => \&_load_genome,
			'cellwall/database' => \&_load_database,
			'cellwall/search'   => \&_load_search,
			'cellwall/group'    => \&_load_group,
		},
	);

	$twig->parsefile($file);
	$twig->purge();

	# Now we need to set the root group ids
	my $rank = 1;
	foreach my $group ($self->get_all_Groups()) {
		$group->rank($rank++) if not defined $group->parent();
	}
}

# add a genome
sub _load_genome
{
	my($twig, $genome) = @_;
	my $name = $genome->first_child('name')->trimmed_text();

	my $obj = new Cellwall::Genome(
		-name => $name
	);

	foreach my $database ($genome->children('database')) {
		my $type = lc($database->att('type'));

		my $db = new Cellwall::Database(
			-type => $type,
			map {
				'-' . $_->gi() => $_->trimmed_text(),
			} $database->children()
		);
		$db->genome($obj);
		$obj->add_Database($db);
	}

	$singleton->add_Genome($obj);
}

# This function adds a database object to the Cellwall object,
sub _load_database
{
	my($twig, $database) = @_;

	my $type = lc($database->att('type'));

	my $db = new Cellwall::Database(
		-type => $type,
		map {
			'-' . $_->gi() => $_->trimmed_text(),
		} $database->children()
	);

	$singleton->add_Database($db);
}

# This function adds a search object to the Cellwall object
sub _load_search
{
	my($twig, $search) = @_;

	my $type = lc($search->att('type'));

	my $so = new Cellwall::Search(
		-type => $type,
		map {
			'-' . $_->gi() => $_->trimmed_text(),
		} $search->children()
	);

	$singleton->add_Search($so);
}

# This function loads a group from the xml file and
# queries the information from the sql database
sub _load_group
{
	my($twig, $group) = @_;

	my $name     = $group->first_child('name')->trimmed_text();

	my $go = new Cellwall::Group(
		-name  => $name,
	);

	# For the rank
	my $rank = 1;

	foreach my $child ($group->children()) {
		if( $child->gi() eq 'group' ) {
			my $cg = _load_group($twig, $child);
			$cg->rank( $rank++ );
			$go->add_Child( $cg );
		} elsif( $child->gi() eq 'family' ) {
			my $family = _load_family($twig, $child);
			$family->rank( $rank++ );
			$go->add_Child($family);
		} elsif($child->gi() eq 'name') {
		} elsif($child->gi() eq 'include') {
			my $family = _include_family($child->trimmed_text());
			$family->rank( $rank++ );
			$go->add_Child($family);
		} else {
			$singleton->debug(0, "Skipping tag: " . $child->gi());
		}
	}

	$singleton->add_Group($go);
	return $go;
}

sub _include_family
{
	my($file) = @_;
	throw Error::Simple("need a filename to load") unless defined $file;

	my $twig = new XML::Twig();

	$twig->parsefile($file);
	my $family = _load_family($twig, $twig->root());
	$twig->purge();
	return $family;
}

# Loads a family from the xml data
sub _load_family
{
	my($twig, $fam) = @_;

	my $name  = $fam->first_child('name')->trimmed_text();
	my $abrev = $fam->first_child('abrev')->trimmed_text();

	my $family = new Cellwall::Family(
		-name => $name,
		-abrev => $abrev,
	);

	$family->add_SubFamily(
		map { $_->trimmed_text() } $fam->children('subfamily')
	);

	foreach my $genome ($fam->children('genome')) {
		my $go = $singleton->get_Genome($genome->att('name'));
		my $db = $go->get_Database( type => 'genbank' );

		foreach my $sequence ($genome->children('sequence')) {
			my $seq = $db->get_Sequence($sequence->trimmed_text());
			if( defined ($seq) ) {
				# Add the links to the sequence
				$seq->generate_Links();
				$family->add_Sequence($seq);
			} else {
				print STDERR "Unable to locate sequence: ", $sequence->trimmed_text(), "\n";
			}
		}
	}
	
	return $family;
}

# load a sequnce. This really just creates and empty sequence
# object to be filled latter.
sub _load_sequence
{
	my($self, $seq) = @_;

	my $sequence = new Cellwall::Sequence(
		-accession_number => $seq->trimmed_text()
	);

	return $sequence;
}

=head2 insert

 Title   : insert
 Usage   : $cw->insert();
 Function: Insert the data into the SQL database
 Returns : 
 Args    :

=cut

sub insert
{
	my($self) = @_;

	my $sql = $self->sql();

	# Insert the genomes
	foreach my $genome ($self->_get_Array('genomes')) {
		$sql->add_Genome($genome);
	}

	# Add the databases
	foreach my $database ($self->_get_Array('databases')) {
		$sql->add_Database($database);
	}

	# Add the searches
	foreach my $search ($self->_get_Array('searches')) {
		$sql->add_Search($search);
	}
	
	# Add the groups
	foreach my $group ($self->_get_Array('groups')) {
		# Skip non-root groups
		next if defined $group->parent();
		$sql->add_Group($group);
	}
}

=head2 query_all

 Title   : query_all
 Usage   : $cw->query_all();
 Function: Query all data from the SQL database
 Returns : 
 Args    :

=cut

sub query_all
{
	my($self) = @_;

	# So i dont have to keep typing $self->sql()
	my $sql = $self->sql();

	# The hashes to store each level of the tree into
	# %families contains the families and is indexed on
	# the group id number. et cetera.
	my %sequences;
	my %children;
	my %groups;

	# Get all the sequences
	foreach my $seq ($sql->get_all_Sequences()) {
		# Add the sequence to it's family
		push( @{ $sequences{$seq->family_id()} }, $seq );

		# Add the sequence to the cellwall
		$self->add_Sequence($seq);
	}

	# Get all the families
	foreach my $family ($sql->get_all_Families()) {
		# Add the sequences to it
		$family->add_all_Sequences(@{ $sequences{$family->id()} });
		#foreach my $seq (@{ $sequences{$family->id()} }) {
		#	$family->add_Sequence($seq);
		#}

		# Add the family to its' group
		push( @{ $children{$family->group_id()} }, $family );

		# Now add the family to the Cellwall
		$self->add_Family($family);
	}

	# First, add all of the groups to their parent's child list
	my @groups = $sql->get_all_Groups();
	foreach my $group (@groups) {
		# if there is a parent_id, add it to that group
		if( defined $group->parent_id() ) {
			push(@{$children{ $group->parent_id() }}, $group);
		}
	}

	# Get all of the groups
	foreach my $group (@groups) {
		if( defined $children{$group->id()} ) {
			# Add of of the children to it
			my @children = @{$children{$group->id()}};

			@children = sort { $a->rank() <=> $b->rank() } @children;

			foreach my $child (@children) {
				$group->add_Child($child);
			}
		}

		# Set it in the groups hash
		$groups{ $group->id() } = $group;
		
		# Add the group to the Cellwall
		$self->add_Group($group);
	}

	# These are the hashes for the genome tree,
	# indexed on the genome_id()
	my %databases;

	# Now get the databases:
	foreach my $db ($sql->get_all_Databases()) {
		# If it has a genome
		if(defined $db->genome_id()) {
			# Add it to the genome
			push( @{ $databases{$db->genome_id()} }, $db );
		}

		# add it to the cellwall
		$self->add_Database($db);
	}

	# Now get the genomes
	foreach my $genome ($sql->get_all_Genomes()) {
		# Add each of the databases that belong to it
		foreach my $db (@{ $databases{$genome->id()} }) {
			$genome->add_Database( $db );
		}
		
		# Add it to the cellwall
		$self->add_Genome($genome);
	}

	# Finally the searches
	foreach my $search ($sql->get_all_Searches()) {
		$self->add_Search($search);
	}
}

=head2 query_root

 Title   : query_root
 Usage   : $cw->query_root();
 Function: Query the root data from the SQL database
 Returns : 
 Args    :

=cut

sub query_root
{
	my($self) = @_;

	# So i dont have to keep typing $self->sql()
	my $sql = $self->sql();

	# The hashes to store each level of the tree into
	# %families contains the families and is indexed on
	# the group id number. et cetera.
	my %children;
	my %groups;

	# Get all the families
	foreach my $family ($sql->get_all_Families()) {
		# Add the family to its' group
		push( @{ $children{$family->group_id()} }, $family );

		# Now add the family to the Cellwall
		$self->add_Family($family);
	}

	# First, add all of the groups to their parent's child list
	my @groups = $sql->get_all_Groups();
	foreach my $group (@groups) {
		# if there is a parent_id, add it to that group
		if( defined $group->parent_id() ) {
			push(@{$children{ $group->parent_id() }}, $group);
		}
	}

	# Get all of the groups
	foreach my $group (@groups) {
		if( defined $children{$group->id()} ) {
			# Add of of the children to it
			my @children = @{$children{$group->id()}};

			@children = sort { $a->rank() <=> $b->rank() } @children;

			foreach my $child (@children) {
				$group->add_Child($child);
			}
		}

		# Set it in the groups hash
		$groups{ $group->id() } = $group;
		
		# Add the group to the Cellwall
		$self->add_Group($group);
	}

	# These are the hashes for the genome tree,
	# indexed on the genome_id()
	my %databases;

	# alevchuk 2013-05-11
	print STDERR 'Hi $sql->get_all_Databases(): ' .
		$sql->get_all_Databases() . "\n";

	# Now get the databases:
	foreach my $db ($sql->get_all_Databases()) {
		# If it has a genome
		if(defined $db->genome_id()) {
			# Add it to the genome
			push( @{ $databases{$db->genome_id()} }, $db );
		}

		# add it to the cellwall
		$self->add_Database($db);
	}

	# alevchuk 2013-05-11
	print STDERR "Got all \"databases\"\n";

	# Now get the genomes
	foreach my $genome ($sql->get_all_Genomes()) {
		# Add each of the databases that belong to it
		foreach my $db (@{ $databases{$genome->id()} }) {
			$genome->add_Database( $db );
		}
		
		# Add it to the cellwall
		$self->add_Genome($genome);
	}

	# Finally the searches
	foreach my $search ($sql->get_all_Searches()) {
		$self->add_Search($search);
	}
}

=head2 execute

 Title   : execute
 Usage   : $cw->execute();
 Function: Execute all of the searches
 Returns : 
 Args    :

=cut

sub execute
{
	my($self, $type, $np) = @_;

	# Default to pvm
	$type = 'pvm' unless defined $type;

	# Create the executor
	my $exec = new Cellwall::Executor( -type => $type );

	# Execute
	$exec->execute($np);
}

=head2 slave

 Title   : slave
 Usage   : $cw->slave();
 Function: Run a slave
 Returns : 
 Args    :

=cut

sub slave
{
	my($self, $type, @ARGS) = @_;

	# Default to pvm
	$type = 'pvm' unless defined $type;

	# Create the executor
	my $exec = new Cellwall::Executor( -type => $type );

	# Execute
	$exec->slave(@ARGS);
}

=head2 split_jobs

 Title   : split_jobs
 Usage   : $cw->split_jobs();
 Function: Split all of the jobs into smaller, executable parts
 Returns : 
 Args    :

=cut

sub split_jobs
{
	my($self) = @_;

	my %seen;
	my @families = $self->get_all_Families();
	my @proteins = grep { !$seen{ $_->primary_id() }++ } $self->get_all_Proteins();
	foreach my $search ($self->get_all_Searches()) {
		if( $search->query() eq 'family' ) {
			foreach my $family (@families) {
				$self->sql()->add_Job($search->id(), $family->id(), 'family');
			}
		} elsif( $search->query() eq 'protein' ) {
			foreach my $seq (@proteins) {
				$self->sql()->add_Job($search->id(), $seq->primary_id(), 'sequence');
			}
		}
	}
}

=head2 robot

 Title   : robot
 Usage   : $cw->robot();
 Function: This will start running jobs from the sql database
 Returns : 
 Args    :

=cut

sub robot
{
	my($self) = @_;

	while(my $ref = $self->sql()->get_Job()) {
		my($search, $level, $target) = @$ref;
		print STDERR "Running job: $search $level $target\n";

		# figure out the real target:
		if( $level eq 'family' ) {
			$target = $self->get_Family( id => $target );
		} elsif( $level eq 'sequence' ) {
			$target = $self->get_Sequence( id => $target );
		}

		# Get the search
		$search = $self->get_Search( id => $search );
		print STDERR "runnng $target on $search\n";

		# Run it
		if( $level eq 'family' ) {
			$search->search_Family( $target );
		} elsif( $level eq 'sequence' ) {
			$search->search_Sequence( $target );
		}
	}
}

# This gets the filename for the searches.

sub search_File
{
	my($self, $section, $seq) = @_;
	return join("/", $self->base(), $section, $seq);
}

sub sql
{
	my($self, $sql) = @_;
	# See if we are setting the SQL
	return $self->{_sql} = $sql if scalar @_ == 2;

	# Check for existing one and return it
	return $self->{_sql} if defined $self->{_sql};
	
	# initialize the sql connection
	$self->{_sql} = new Cellwall::SQL(
		-host     =>$singleton->host(), 
		-db       =>$singleton->db(), 
		-user     =>$singleton->user(), 
		-password =>$singleton->password(), 
	);

	return $self->{_sql};
}

=head2 dump_All

 Title   : dump_All
 Usage   : $cw->dump_All($filename);
 Function: Dump the annotations from the database to a flat file
 Returns : 
 Args    : The optional filename to save to

=cut

sub dump_All
{
	my($self, $file) = @_;

	if( defined $file ) {
		open(FILE, ">$file");
	} else {
		*FILE = *STDOUT;
	}

	# Dump all users in the database
	$self->dump_Users();

	# Dump all comments in the database
	$self->dump_Comments();

	# Dump all DBLinks in the database
	$self->dump_DBLinks();

	# Dump Display Names
	$self->dump_Names();

	# Close the file
	close(FILE) if defined $file;
}

=head2 dump_Users

 Title   : dump_Users
 Usage   : $cw->dump_Users();
 Function: Dump all Users from the database
 Returns : 
 Args    : 

=cut

sub dump_Users
{
	my($self) = @_;

	my $sth = $self->sql()->prepare("SELECT * FROM users");
	$sth->execute();
	my $results = $sth->fetchall_arrayref();

	foreach my $row (@$results) {
		s/\t/\\t/go foreach @$row;
		s/\n/\\n/go foreach @$row;
		print FILE join("\t", "User", @$row), "\n";
	}

	$sth->finish();
}
	
=head2 dump_DBLinks

 Title   : dump_DBLinks
 Usage   : $cw->dump_DBLinks();
 Function: Dump all DBLinks from the database
 Returns : 
 Args    : 

=cut

sub dump_DBLinks
{
	my($self) = @_;

	my $sth = $self->sql()->prepare("SELECT sequence.accession, dblink.section, dblink.db, dblink.href FROM dblink JOIN sequence ON dblink.sequence = sequence.id");
	$sth->execute();
	my $results = $sth->fetchall_arrayref();

	foreach my $row (@$results) {
		s/\t/\\t/go foreach @$row;
		s/\n/\\n/go foreach @$row;
		print FILE join("\t", "DBLink", @$row), "\n";
	}

	$sth->finish();
}

=head2 dump_Names

 Title   : dump_Names
 Usage   : $cw->dump_Names();
 Function: Dump all Names from the database
 Returns : 
 Args    : 

=cut

sub dump_Names
{
	my($self) = @_;

	my $sth = $self->sql()->prepare("SELECT sequence.accession, sequence.display FROM sequence WHERE sequence.display IS NOT NULL");
	$sth->execute();
	my $results = $sth->fetchall_arrayref();

	foreach my $row (@$results) {
		s/\t/\\t/go foreach @$row;
		s/\n/\\n/go foreach @$row;
		print FILE join("\t", "ID", @$row), "\n";
	}

	$sth->finish();
}

=head2 dump_Comments

 Title   : dump_Comments
 Usage   : $cw->dump_Comments();
 Function: Dump all the comments from the database
 Returns : 
 Args    : 

=cut

sub dump_Comments
{
	my($self) = @_;

	my $sth = $self->sql()->prepare("SELECT sequence.accession, users.email, comment.comment, comment.ref, comment.updated FROM comment JOIN users ON users.id = comment.user JOIN sequence ON sequence.id = comment.sequence");
	$sth->execute();
	my $results = $sth->fetchall_arrayref();
	foreach my $row (@$results) {
		@$row = grep { defined $_ } @$row;
		s/\t/\\t/go foreach @$row;
		s/\n/\\n/go foreach @$row;
		print FILE join("\t", "Comment", @$row), "\n";
	}

	$sth->finish();
}


1;
