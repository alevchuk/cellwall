# vim:sw=4 ts=4
# $Id: SQL.pm 152 2005-08-10 22:03:28Z laurichj $

=head1 NAME

Cellwall::SQL

=head1 DESCRIPTION

Cellwall::SQL is the interface to the sql database, when updates
are performed the Cellwall::Database sources are considered true
and the MySQL tables are updated.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::SQL;
use Bio::Annotation::Collection;
use Bio::Annotation::Comment;
use Bio::Annotation::DBLink;
use Bio::SeqFeature::Generic;
use Bio::Location::Split;
use Cellwall::Species;
use Error qw/:try/;
use base qw/Cellwall::Root/;
use vars qw/@ACCESSORS $singleton/;
use strict;

@ACCESSORS = qw/host db user password dbh/;
Cellwall::SQL->mk_accessors(@ACCESSORS);

# We only want one Cellwall::SQL to be created
$singleton = undef;

=head2 new

 Title   : new
 Usage   : $sql = new Cellwall::SQL()
 Function: Creates a cellwall object
 Returns : a Cellwall::SQL object
 Args    :

=cut

sub new
{
	my $class = shift @_;

	# Just return the old sql if its there
	return $singleton if defined($singleton);

	# Create a new Cellwall::SQL
	$singleton = $class->SUPER::new(@_);

	# Create the SQL connection
	my $dbh = DBI->connect(
		join(':', 'DBI:mysql', $singleton->db(), $singleton->host()),
		$singleton->user(),
		$singleton->password(),
		{
			RaiseError => 1,
		}
	) || throw Error::Simple("unable to open mysql connection");

	# Save the dbh
	$singleton->dbh($dbh);

	return $singleton;
}

=head2 

 Title   : lookup_Accession
 Usage   : $id = $sql->lookup_Accession($acc)
 Function: find the id for a given accession
 Returns : a scalar id
 Args    : an accession

=cut

sub lookup_Accession
{
	my($self, $accession) = @_;

	# Setup the sequence
	$self->{_mysql_get_IdByAccession} = $self->dbh()->prepare("SELECT sequence.id FROM sequence JOIN idxref ON sequence.id = idxref.sequence WHERE idxref.accession = ?")
		unless defined($self->{_mysql_get_IdByAccession});
	
	# Lookup the accession number
	$self->{_mysql_get_IdByAccession}->execute($accession);
	my($id) = $self->{_mysql_get_IdByAccession}->fetchrow();
	$self->{_mysql_get_IdByAccession}->finish();

	# Return the id
	return $id;
}

=head2 

 Title   : add_Genome
 Usage   : $sql->add_Genome($genome)
 Function: add a genome to the database
 Returns : nothing
 Args    : a Cellwall::Genome object

=cut

sub add_Genome
{
	my($self, $genome) = @_;

	$self->{_mysql_insert_Genome} = $self->dbh()->prepare("INSERT INTO genome VALUES(NULL, ?, NULL)")
		unless defined($self->{_mysql_insert_Genome});
	
	$self->{_mysql_insert_Genome}->execute($genome->name());
	$self->debug(2, "Inserted genome " . $genome->name());

	# Now get the id:
	$self->{_mysql_select_GenomeId} = $self->dbh()->prepare("SELECT id FROM genome WHERE name = ?")
		unless defined($self->{_mysql_select_GenomeId});
	
	$self->{_mysql_select_GenomeId}->execute($genome->name());
	my($id) = $self->{_mysql_select_GenomeId}->fetchrow();
	$self->{_mysql_select_GenomeId}->finish();

	throw Error::Simple('Added a genome, but not found in database')
		unless defined $id;

	$genome->id($id);
	$self->debug(3, "New ID: $id");

	# Add each database
	foreach my $database ($genome->get_all_Databases()) {
		$database->genome_id($id);
		$self->add_Database($database);
	}
}

=head2 

 Title   : add_Database
 Usage   : $sql->add_Database($database)
 Function: add a database to the database
 Returns : nothing
 Args    : a Cellwall::Database object

=cut

sub add_Database
{
	my($self, $database) = @_;

	$self->{_mysql_insert_Database} = $self->dbh()->prepare("INSERT INTO db VALUES(NULL, ?, ?, ?, NULL)")
		unless defined($self->{_mysql_insert_Database});
	
	if(!defined($database->name())) {
		# There is no name, so set the name to the genome's name
		throw Error::Simple('the database has no name and no genome!')
			unless defined($database->genome());

		$database->name( $database->genome()->name() . '.' . $database->type() );
	}
	
	$self->{_mysql_insert_Database}->execute(
		$database->genome_id(),
		$database->name(),
		$database->type(),
	);
	$self->debug(2, "Inserted database " . $database->name());

	# Now get the id:
	$self->{_mysql_select_DatabaseId} = $self->dbh()->prepare("SELECT id FROM db WHERE name = ?")
		unless defined($self->{_mysql_select_DatabaseId});
	
	$self->{_mysql_select_DatabaseId}->execute($database->name());
	my($id) = $self->{_mysql_select_DatabaseId}->fetchrow();
	$self->{_mysql_select_DatabaseId}->finish();

	throw Error::Simple('Added a database, but not found in database')
		unless defined $id;

	$database->id($id);
	$self->debug(3, "New ID: $id");

	# Add the params
	$self->add_Params('database', $database->id(), $database->params());
}

=head2 

 Title   : add_Search
 Usage   : $sql->add_Search($search)
 Function: add a search to the database
 Returns : nothing
 Args    : a Cellwall::Search object

=cut

sub add_Search
{
	my($self, $search) = @_;

	$self->{_mysql_insert_Search} = $self->dbh()->prepare("INSERT INTO search VALUES(NULL, ?, ?, ?, ?, ?, NULL)")
		unless defined($self->{_mysql_insert_Search});
	
	$self->{_mysql_insert_Search}->execute(
		$search->name(),
		$search->type(),
		$search->genome()   ? $search->genome()->id()   : undef,
		$search->database() ? $search->database()->id() : undef,
		$search->query()
	);
	$self->debug(2, "Inserted search " . $search->name());

	# Now get the id:
	$self->{_mysql_select_SearchId} = $self->dbh()->prepare("SELECT id FROM search WHERE name = ?")
		unless defined($self->{_mysql_select_SearchId});
	
	$self->{_mysql_select_SearchId}->execute($search->name());
	my($id) = $self->{_mysql_select_SearchId}->fetchrow();
	$self->{_mysql_select_SearchId}->finish();

	throw Error::Simple('Added a search, but not found in database')
		unless defined $id;

	$search->id($id);
	$self->debug(3, "New ID: $id");

	# Add the params
	$self->add_Params('search', $search->id(), $search->params());
}

=head2 

 Title   : add_Params
 Usage   : $sql->add_Params($section, $id, @params)
 Function: add parameters to the db
 Returns : nothing
 Args    : a a paired array of paramaeters (a hash)

=cut

sub add_Params
{
	my($self, $section, $id, @params) = @_;

	$self->{_mysql_insert_Param} = $self->dbh()->prepare("INSERT INTO parameters VALUES(NULL, ?, ?, ?, ?, ?, NULL)")
		unless defined($self->{_mysql_insert_Param});
	
	while( my($key, $val) = splice(@params, 0, 2) ) {
		# add each key
		next unless $key and $val;
		$self->{_mysql_insert_Param}->execute($section, undef, $id, $key, $val);
	}
}

=head2 

 Title   : add_Group
 Usage   : $sql->add_Group($group)
 Function: add a group to the SQL database
 Returns : nothing
 Args    : a Cellwall::Group object

=cut

sub add_Group
{
	my($self, $group) = @_;

	$self->{_mysql_insert_Group} = $self->dbh()->prepare("INSERT INTO groups VALUES(NULL, ?, ?, ?, NULL)")
		unless defined($self->{_mysql_insert_Group});
	
	$self->{_mysql_insert_Group}->execute($group->parent()->id(), $group->rank(), $group->name()) if  defined $group->parent();
	$self->{_mysql_insert_Group}->execute(undef                 , $group->rank(), $group->name()) if !defined $group->parent();
	$self->debug(2, "Inserted group " . $group->name());

	# Now get the id:
	$self->{_mysql_select_GroupId} = $self->dbh()->prepare("SELECT id FROM groups WHERE name = ?")
		unless defined($self->{_mysql_select_GroupId});
	
	$self->{_mysql_select_GroupId}->execute($group->name());
	my($id) = $self->{_mysql_select_GroupId}->fetchrow();
	$self->{_mysql_select_GroupId}->finish();

	throw Error::Simple('Added a group, but not found in database')
		unless defined $id;

	$group->id($id);
	$self->debug(3, "New ID: $id");

	# Add each child
	foreach my $child ($group->get_all_Children()) {
		if( $child->isa('Cellwall::Family') ) {
			$self->add_Family($child);
		} elsif( $child->isa('Cellwall::Group') ) {
			$self->add_Group($child);
		}
	}
}

=head2 

 Title   : add_Family
 Usage   : $sql->add_Family($family)
 Function: add a family to the SQL database
 Returns : nothing
 Args    : a Cellwall::Family object

=cut

sub add_Family
{
	my($self, $family) = @_;

	$self->{_mysql_insert_Family} = $self->dbh()->prepare("INSERT INTO family VALUES(NULL, ?, ?, ?, ?, NULL)")
		unless defined($self->{_mysql_insert_Family});
	
	$self->{_mysql_insert_Family}->execute(
		$family->group()->id(),
		$family->rank(),
		$family->name(),
		$family->abrev(),
	);
	$self->debug(2, "Inserted family " . $family->name() . " [ " . $family->abrev() . " ] ");

	# Now get the id:
	$self->{_mysql_select_FamilyId} = $self->dbh()->prepare("SELECT id FROM family WHERE name = ?")
		unless defined($self->{_mysql_select_FamilyId});
	
	$self->{_mysql_select_FamilyId}->execute($family->name());
	my($id) = $self->{_mysql_select_FamilyId}->fetchrow();
	$self->{_mysql_select_FamilyId}->finish();

	throw Error::Simple('Added a family, but not found in database')
		unless defined $id;

	$family->id($id);
	$self->debug(3, "New ID: $id");

	$self->{_mysql_insert_SubFamily} = $self->dbh()->prepare("INSERT INTO subfamily VALUES(NULL, ?, ?, ?, NULL)")
		unless defined $self->{_mysql_insert_SubFamily};
	
	my $i = 0;
	foreach my $sub ($family->get_SubFamilies()) {
		$self->{_mysql_insert_SubFamily}->execute(
			$family->id(),
			$i,
			$sub
		);
	}

	# Add all the sequences
	foreach my $seq (sort { $a->accession_number() cmp $b->accession_number() } $family->get_all_Sequences()) {
		$self->add_Sequence($seq);
	}
}

=head2 

 Title   : add_Sequence
 Usage   : $sql->add_Sequence($seq)
 Function: add a sequence to the SQL database
 Returns : nothing
 Args    : a Cellwall::Sequence object

=cut

sub add_Sequence
{
	my($self, $seq) = @_;

	unless( defined($self->{_mysql_insert_Sequence}) ) {
		$self->{_mysql_insert_Sequence} = $self->dbh()->prepare("INSERT INTO sequence VALUES(NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, NULL, NULL, NULL, NULL)");
		$self->{_mysql_replace_IDXRef}  = $self->dbh()->prepare("REPLACE INTO idxref VALUES(?, ?)");
		$self->{_mysql_select_SequenceId} = $self->dbh()->prepare("SELECT id FROM sequence WHERE accession = ?");
	}

	$self->dbh()->begin_work();

	try {
		# Add the species:
		$self->add_Species( $seq->species() );
		
		# Set the database_id if the db is there and the database_id isn't
		$seq->database_id( $seq->db()->id() ) if defined( $seq->db() ) and !defined( $seq->database_id() );
		
		# raise an error if we still don't have the database_id
		throw Error::Simple(
			-text => 'sequence has no database_id or db',
			-object => $seq
		) unless defined $seq->database_id();
		
		# Set the family_id if the family is there and the family_id isn't
		$seq->family_id( $seq->family()->id() ) if defined( $seq->family() ) and !defined( $seq->family_id() );
		
		# raise an error if we still don't have the family_id
		throw Error::Simple(
			-text => 'sequence has no family_id or family',
			-object => $seq
		) unless defined $seq->family_id();
		
		# Set the species_id if the species is there and the species_id isn't
		$seq->species_id( $seq->species()->id() ) if defined( $seq->species() ) and !defined( $seq->species_id() );
		
		# raise an error if we still don't have the species_id
		throw Error::Simple(
			-text => 'sequence has no species_id or species',
			-object => $seq
		) unless defined $seq->species_id();
		
		$self->{_mysql_insert_Sequence}->execute(
			$seq->database_id(),
			$seq->family_id(),
			$seq->species_id(),
			$seq->accession_number(),
			#$seq->display_id(),
			undef,
			$seq->desc(),
			$seq->length(),
			$seq->alphabet(),
			$seq->seq()
		);
		$self->debug(2, "Inserted sequence " . $seq->accession_number());
		
		# Now get the id:
		$self->{_mysql_select_SequenceId}->execute($seq->accession_number());
		my($id) = $self->{_mysql_select_SequenceId}->fetchrow();
		$self->{_mysql_select_SequenceId}->finish();
		
		throw Error::Simple('Added a sequence, but not found in database')
			unless defined $id;
		
		# Set the id
		$seq->primary_id($id);
		$self->debug(3, "New ID: $id");
		
		# Set all of the protein ids and secondary accessions to point back
		my @ids = ( $seq->accession_number(), $seq->display_name(), $seq->get_secondary_accessions());
		my %seen;
		push(@ids, map { $_->accession_number(), $_->display_name() } $seq->get_all_Proteins());
		@ids = grep { defined $_ and !$seen{$_}++ } @ids;
		
		foreach my $accession (@ids) {
			$self->{_mysql_replace_IDXRef}->execute($id, $accession);
		}
		
		# Add each of the sequence features
		my @features = $seq->get_SeqFeatures();
		for(my $i = 0; $i < @features; $i++) {
			$self->add_SeqFeature($seq->primary_id(), $i, $features[$i])
		}
		
		# Add the Annotations (currently, only links)
		foreach my $dblink ($seq->annotation()->get_Annotations('dblink')) {
			# Skip non-munged links
			next unless defined $dblink->{_CW_Section};
		
			# Add the DBLink
			$self->add_DBLink($id, $dblink->{_CW_Section}, $dblink->database(), $dblink->primary_id());
		}

		$self->dbh()->commit();
	}
	catch Error::Simple with {
		my $E = shift;
		$self->debug(1, "Unable to insert sequence: " . $seq->accession_number() .
			": " . $E->text());
		$self->dbh()->rollback();
	};
}

=head2 

 Title   : add_SeqFeature
 Usage   : $sql->add_SeqFeature($seq->primary_id(), $rank, $feature)
 Function: add a sequence feature to the database
 Returns : nothing
 Args    : a database id, a rank and the feature

=cut

sub add_SeqFeature
{
	my($self, $seqid, $rank, $feature) = @_;

	return unless defined $feature->start() and defined $feature->end();

	# Define the queries
	unless( defined($self->{_mysql_insert_SeqFeature}) ) {
		$self->{_mysql_insert_SeqFeature} = $self->dbh()->prepare("INSERT INTO seqfeature VALUES(NULL, ?, ?, ?, NULL)");
		$self->{_mysql_select_SeqFeatureID} = $self->dbh()->prepare("SELECT id FROM seqfeature WHERE sequence = ? AND rank = ?");
		$self->{_mysql_insert_SeqTag} = $self->dbh()->prepare("INSERT INTO seqtags VALUES(NULL, ?, ?, ?, NULL)");
		$self->{_mysql_insert_SeqLocation} = $self->dbh()->prepare("INSERT INTO seqlocation VALUES(NULL, ?, ?, ?, ?, ?, NULL)");
	}

	# Add the feature
	$self->{_mysql_insert_SeqFeature}->execute(
		$seqid,
		$rank,
		$feature->primary_tag()
	);

	# Get the id;
	$self->{_mysql_select_SeqFeatureID}->execute($seqid, $rank);
	my($id) = $self->{_mysql_select_SeqFeatureID}->fetchrow();
	$self->{_mysql_select_SeqFeatureID}->finish();
	$self->debug(3, "New SeqFeature: $id");

	# Add the location[s]:
	$self->add_Location($id, $feature->location());

	# Add all tags
	foreach my $tag (sort $feature->get_all_tags()) {
		# Add all tag values:
		foreach my $value ($feature->get_tag_values($tag)) {
			$self->{_mysql_insert_SeqTag}->execute(
				$id,
				$tag,
				$value
			);
		}
	}
}

=head2 

 Title   : add_Location
 Usage   : $sql->add_Location($feat_id, $location)
 Function: add a location object to the database
 Returns : nothing
 Args    : a seqfeature id and the location

=cut

sub add_Location
{
	my($self, $id, $location) = @_;

	if( defined($location) and $location->isa( 'Bio::Location::Split' ) ) {
		# Add each sub location
		my @sublocs = $location->sub_Location();
		for(my $j = 0; $j < @sublocs; $j++) {
			my $loc = $sublocs[$j];
			$self->{_mysql_insert_SeqLocation}->execute(
				$id,
				$j,
				$loc->start(),
				$loc->end(),
				$loc->strand(),
			);
		}
	} else {
		# Just add a single location
		$self->{_mysql_insert_SeqLocation}->execute(
			$id,
			0,
			$location->start(),
			$location->end(),
			$location->strand(),
		);
	}
}

=head2 

 Title   : add_AnnotationTab
 Usage   : $sql->add_Annotation($acc, $type, @terms)
 Function: add an annotation to the database
 Returns : nothing
 Args    : an accession number, an annotation type and a list
           of terms for the annotation

=cut

sub add_AnnotationTab
{
	my($self, $accession, $type, @terms) = @_;

	# If not a user, get the id number
	my $id;
	if($type !~ /^user$/oi) {
		$id = $self->lookup_Accession($accession);

		# Skip it if there's no such key in the data base
		if( not defined $id ) {
			$self->debug(1, "id $accession not found when adding $type");
			return;
		}
	}

	# Figure out what type it is and do it:
	if( $type =~ /^dblink$/oi ) {
		$self->add_DBLink($id, @terms);
	} elsif( $type =~ /^id$/oi ) {
		$self->set_DisplayID($id, @terms);
	} elsif( $type =~ /^accession$/oi ) {
		$self->add_SecondaryID($id, @terms);
	} elsif( $type =~ /^comment$/oi ) {
		$self->add_Comment($id, 0, @terms);
	} elsif( $type =~ /^user$/oi ) {
		$self->add_User($accession, @terms);
	}
}

=head2 

 Title   : add_User
 Usage   : $sql->add_User($seq->primary_id(), $section, $db, $url)
 Function: add an external link to the database
 Returns : nothing
 Args    : a sequence id, a database name and a URL

=cut

sub add_User
{
	my($self, $userid, $email, $passwd, $first, $last, $institute, $address, $date) = @_;
	print "Adding user to db: $userid => $email\n";

	# Define the queries
	unless( defined($self->{_mysql_insert_User}) ) {
		$self->{_mysql_insert_User} = $self->dbh()->prepare("INSERT INTO users VALUES(?, ?, ?, ?, ?, ?, ?, ?)");
	}

	$institute =~ s/\\t/\t/go;
	$institute =~ s/\\n/\n/go;
	$address   =~ s/\\t/\t/go;
	$address   =~ s/\\n/\n/go;

	try {
		$self->{_mysql_insert_User}->execute( $userid, $email, $passwd, $first, $last, $institute, $address, $date );
	} catch Error::Simple with {
		my $E = shift;
		$self->debug(1, "Unable to add User: " . $E->text());
	};
}

=head2 

 Title   : add_DBLink
 Usage   : $sql->add_DBLink($seq->primary_id(), $section, $db, $url)
 Function: add an external link to the database
 Returns : nothing
 Args    : a sequence id, a database name and a URL

=cut

sub add_DBLink
{
	my($self, $seqid, $section, $db, $url) = @_;
	print "Adding link to db: $seqid => $section::$db::$url\n";

	# Define the queries
	unless( defined($self->{_mysql_insert_DBLink}) ) {
		$self->{_mysql_insert_DBLink} = $self->dbh()->prepare("INSERT INTO dblink VALUES(NULL, ?, ?, ?, ?, NULL)");
	}

	# Add the feature
	try {
		$self->{_mysql_insert_DBLink}->execute(
			$section,
			$seqid,
			$db,
			$url,
		);
	} 
	catch Error::Simple with {
		my $E = shift;
		$self->debug(1, "Unable to add DBLink: " . $E->text());
	};
}

=head2 

 Title   : set_DisplayID
 Usage   : $sql->set_DisplayID($seq->primary_id(), id)
 Function: set the display id for a sequence
 Returns : nothing
 Args    : a sequence id and a display id

=cut

sub set_DisplayID
{
	my($self, $seqid, $display) = @_;

	# Define the queries
	unless( defined($self->{_mysql_set_DisplayID}) ) {
		$self->{_mysql_set_DisplayID} = $self->dbh()->prepare("UPDATE sequence SET display = ? WHERE id = ?");
		$self->{_mysql_replace_IDXRef}  = $self->dbh()->prepare("INSERT INTO idxref VALUES(?, ?)");
	}

	# Update the display id
	$self->{_mysql_set_DisplayID}->execute(
		$display,
		$seqid,
	);

	# Add the id to the idxref table
	$self->{_mysql_replace_IDXRef}->execute($seqid, $display);

	$self->debug(2, "updated sequence's display id");
}

=head2 

 Title   : add_SecondaryID
 Usage   : $sql->add_SecondaryID($seq->primary_id(), id)
 Function: add a secondary id
 Returns : nothing
 Args    : a sequence id and a secondary id

=cut

sub add_SecondaryID
{
	my($self, $seqid, $display) = @_;

	# Define the queries
	unless( defined($self->{_mysql_replace_IDXRef}) ) {
		$self->{_mysql_replace_IDXRef}  = $self->dbh()->prepare("INSERT INTO idxref VALUES(?, ?)");
	}

	# Add the id to the idxref table
	$self->{_mysql_replace_IDXRef}->execute($seqid, $display);

	$self->debug(2, "added a secondary id");
}

=head2 

 Title   : add_Job
 Usage   : $sql->add_Job($search->id(), $target->id(), [ $level, $state ]);
 Function: add a Job 
 Returns : nothing
 Args    : a search id, a target id and a state

=cut

sub add_Job
{
	my($self, $search, $target, $level, $state) = @_;

	# Default to open, family
	$level = 'family' unless $level;
	$state = 'open'   unless $state;
	
	# Define the queries
	unless( defined($self->{_mysql_insert_Job}) ) {
		$self->{_mysql_insert_Job}  = $self->dbh()->prepare("INSERT INTO jobs  VALUES(NULL, ?, ?, ?, ?)");
	}

	# Insert it
	$self->{_mysql_insert_Job}->execute($search, $level, $target, $state);

	$self->debug(2, "added a Job ( $search, $target, $state, $level )");
}

=head2 

 Title   : get_Job
 Usage   : my($search_id, $level, $target) = $sql->get_Job();
 Function: get and reserve a job
 Returns : a search id, a level and a a target id
 Args    : nothing

=cut

sub get_Job
{
	my($self) = @_;

	# We don't cache the queryies because that might cause threading
	# problems.

	# Lock the job table
	$self->dbh()->do( "LOCK TABLES jobs WRITE" );
	
	# Get the next one to be done:
	my $get = $self->dbh()->prepare('SELECT id, search, level, target FROM jobs WHERE state = "open" LIMIT 1');
	$get->execute();
	my($id, $search, $level, $target) = $get->fetchrow();
	$get->finish();

	# If thre's one, set it to running
	if(defined $id) {
		my $running = $self->dbh()->prepare('UPDATE jobs SET state = "running" WHERE id = ?');
		$running->execute($id);
	}

	# Unlock the table
	$self->dbh()->do( 'UNLOCK TABLES' );

	return [$search, $level, $target] if defined $id;
	return undef;
}

=head2 

 Title   : add_Comment
 Usage   : $sql->add_Comment($seq->primary_id(), $user, $comment, [ $reference])
 Function: add a comment
 Returns : nothing
 Args    : a sequence id and a comment

=cut

sub add_Comment
{
	my($self, $seqid, $user, $comment, $reference) = @_;

	# Define the queries
	unless( defined($self->{_mysql_add_Comment}) ) {
		$self->{_mysql_add_Comment} = $self->dbh()->prepare("INSERT INTO comment SELECT NULL, id, ?, ?, ?, NULL FROM users WHERE email = ?");
	}

	printf "INSERT INTO comment SELECT NULL, id, %s, %s, %s, NULL FROM users WHERE email = %s",
		$seqid,
		$comment,
		$reference,
		$user,
	;

	# Update the display id
	$self->{_mysql_add_Comment}->execute(
		$seqid,
		$comment,
		$reference,
		$user,
	);

	$self->debug(2, "added Comment to database");
}

=head2 

 Title   : replace_Comment
 Usage   : $sql->replace_Comment($comment_id, $seq->primary_id(), $uid, $comment, [ $reference])
 Function: replace a comment
 Returns : nothing
 Args    : a sequence id and a comment

=cut

sub replace_Comment
{
	my($self, $id, $seqid, $uid, $comment, $reference) = @_;

	# Define the queries
	unless( defined($self->{_mysql_replace_Comment}) ) {
		$self->{_mysql_replace_Comment} = $self->dbh()->prepare("INSERT INTO comment VALUES(?, ?, ?, ?, ?, NULL)");
	}

	$self->{_mysql_replace_Comment}->execute(
		$id,
		$uid,
		$seqid,
		$comment,
		$reference,
	);

	$self->debug(2, "updated Comment to database");
}

=head2 

 Title   : delete_Comment
 Usage   : $sql->delete_Comment($comment_id, $uid)
 Function: delete a comment
 Returns : nothing
 Args    : a sequence id and a comment

=cut

sub delete_Comment
{
	my($self, $id, $uid) = @_;

	# Define the queries
	unless( defined($self->{_mysql_delete_Comment}) ) {
		$self->{_mysql_delete_Comment} = $self->dbh()->prepare("DELETE FROM comment WHERE id = ? AND user = ?");
	}

	$self->{_mysql_delete_Comment}->execute(
		$id,
		$uid,
	);

	$self->debug(2, "deleted Comment from database");
}

=head2 

 Title   : add_Species
 Usage   : $sql->add_Species($species)
 Function: add a species to the SQL database
 Returns : nothing
 Args    : a Cellwall::Species object

=cut

sub add_Species
{
	my($self, $species) = @_;

	# If the species has an id, it has already been inserted:
	return if defined $species->id();


	$self->{_mysql_insert_Species} = $self->dbh()->prepare("INSERT INTO species VALUES(NULL, ?, ?, ?, ?, NULL)")
		unless defined($self->{_mysql_insert_Species});

	$self->{_mysql_insert_Species}->execute(
		$species->genus(),
		$species->species(),
		$species->sub_species(),
		$species->common_name()
	);
	$self->debug(2, "Inserted species " . $species->common_name());

	# Now get the id:
	$self->{_mysql_select_SpeciesId} = $self->dbh()->prepare("SELECT id FROM species WHERE genus = ? AND species = ?")
		unless defined($self->{_mysql_select_SpeciesId});
	
	$self->{_mysql_select_SpeciesId}->execute($species->genus(), $species->species());
	my($id) = $self->{_mysql_select_SpeciesId}->fetchrow();
	$self->{_mysql_select_SpeciesId}->finish();

	throw Error::Simple('Added a species, but not found in database')
		unless defined $id;

	$species->id($id);
	$self->debug(3, "New ID: $id");
}

=head2

 Title   : get_all_Searches
 Usage   : @searches = $sql->get_all_Searches();
 Function: Get the searches
 Returns : an array of Cellwall::Search objects
 Args    : 

=cut

sub get_all_Searches
{
	my($self) = @_;
	
	# Create the query
	unless( defined($self->{_mysql_get_all_Searches}) ) {
		$self->{_mysql_get_all_Searches} = $self->dbh()->prepare("SELECT id, name, s_type, genome, db, query FROM search");
		$self->{_mysql_get_search_Parameters} = $self->dbh->prepare("SELECT reference, name, value FROM parameters WHERE section = 'search'");
	}

	# Run the queries
	$self->{_mysql_get_all_Searches}->execute();
	my @searches = @{ $self->{_mysql_get_all_Searches}->fetchall_arrayref() };
	$self->{_mysql_get_all_Searches}->finish();

	$self->{_mysql_get_search_Parameters}->execute();
	my @parameters = @{ $self->{_mysql_get_search_Parameters}->fetchall_arrayref() };
	$self->{_mysql_get_search_Parameters}->finish();

	my %parameters;
	foreach my $param (@parameters) {
		push( @{ $parameters{ $param->[0] } }, [ $param->[1], $param->[2] ] );
	}

	foreach my $search (@searches) {
		my( $id, $name, $type, $genome, $db, $query ) = @$search;

		# Create the search object
		$search = new Cellwall::Search(
			-id          => $id,
			-name        => $name,
			-database_id => $db,
			-genome_id   => $genome,
			-query       => $query,
			-type        => $type,
			map { ( "-$_->[0]" => $_->[1] ), } (@{ $parameters{ $id } }),
		);
	}

	return @searches;
}

=head2

 Title   : get_all_Genomes
 Usage   : @genomes = $sql->get_all_Genomes();
 Function: Get the genomes
 Returns : an array of Cellwall::Genome objects
 Args    : 

=cut

sub get_all_Genomes
{
	my($self) = @_;
	
	# Create the query
	unless( defined($self->{_mysql_get_all_Genomes}) ) {
		$self->{_mysql_get_all_Genomes} = $self->dbh()->prepare("SELECT id, name FROM genome");
	}

	# Run the queries
	$self->{_mysql_get_all_Genomes}->execute();
	my @genomes = @{ $self->{_mysql_get_all_Genomes}->fetchall_arrayref() };
	$self->{_mysql_get_all_Genomes}->finish();

	foreach my $genome (@genomes) {
		my( $id, $name ) = @$genome;

		# Create the object
		$genome = new Cellwall::Genome(
			-id        => $id,
			-name      => $name,
		);
	}

	return @genomes;
}

=head2

 Title   : get_all_Databases
 Usage   : @dbs = $sql->get_all_Databases();
 Function: Get the databases
 Returns : an array of Cellwall::Database objects
 Args    : 

=cut

sub get_all_Databases
{
	my($self) = @_;
	
	# Create the query
	unless( defined($self->{_mysql_get_all_Database}) ) {
		$self->{_mysql_get_all_Database} = $self->dbh()->prepare("SELECT id, genome, name, db_type FROM db");
		$self->{_mysql_get_db_Parameters} = $self->dbh->prepare("SELECT reference, name, value FROM parameters WHERE section = 'database'");
	}

	# Run the queries
	$self->{_mysql_get_all_Database}->execute();
	my @databases = @{ $self->{_mysql_get_all_Database}->fetchall_arrayref() };
	$self->{_mysql_get_all_Database}->finish();

	$self->{_mysql_get_db_Parameters}->execute();
	my @parameters = @{ $self->{_mysql_get_db_Parameters}->fetchall_arrayref() };
	$self->{_mysql_get_db_Parameters}->finish();

	my %parameters;
	foreach my $param (@parameters) {
		push( @{ $parameters{ $param->[0] } }, [ $param->[1], $param->[2] ] );
	}

	foreach my $db (@databases) {
		my( $id, $genome, $name, $type ) = @$db;

		# alevchuk 2013-05-11
		if(
		   $name ne 'EST.genbank' and
		   $name ne 'EST.blast' and
                   $name ne 'O. sativa.genbank' and
                   $name ne 'A. thaliana.genbank' #and
		   #$name ne 'UniProt.genbank'
	 	  ) {
			print STDERR "Loading database: $name\n";

			# Create the object
			$db = new Cellwall::Database(
				-id        => $id,
				-name      => $name,
				-genome_id => $genome,
				-type      => $type,
				map { ( "-$_->[0]" => $_->[1] ), } (@{ $parameters{ $id } }),
			);
		} else {
			print STDERR "Skipped database: $name\n";
		}
	}

	return @databases;
}

=head2

 Title   : get_all_Groups
 Usage   : @groups = $sql->get_all_Groups();
 Function: Get all the groups from the database
 Returns : a Cellwall::Group object
 Args    : A group id

=cut

sub get_all_Groups
{
	my( $self ) = @_;
	$self->{_mysql_get_all_Groups} = $self->dbh()->prepare("SELECT id, parent, rank, name FROM groups")
			unless defined($self->{_mysql_get_all_Groups});

	# Run the query
	$self->{_mysql_get_all_Groups}->execute();
	my @groups = @{ $self->{_mysql_get_all_Groups}->fetchall_arrayref() };
	$self->{_mysql_get_all_Groups}->finish();

	foreach my $group (@groups) {
		my( $id, $parent, $rank, $name ) = @$group;

		# Create the object
		$group = new Cellwall::Group(
			-id        => $id,
			-name      => $name,
			-rank      => $rank,
			-parent_id => $parent,
		);
	}

	return @groups;
}

=head2

 Title   : get_Group
 Usage   : $group = $sql->get_Group($id);
 Function: Get information regaurding a group
 Returns : a Cellwall::Group object
 Args    : A group id

=cut

sub get_Group
{
	my($self, $qtype, $qid) = @_;
	my $sth;

	# set id to run if called without the type => key args
	if(!defined($qid)) {
		$qid = $qtype;
		$qtype = 'id';
	}
	
	if($qtype eq 'id') {
		# use the id to get the group
		# this is the default
		$self->{_mysql_get_Group_by_id} = $self->dbh()->prepare("SELECT id, parent, rank, name, updated FROM groups WHERE id = ?")
			unless defined($self->{_mysql_get_Group_by_id});

		$sth = $self->{_mysql_get_Group_by_id};
	} elsif($qtype eq 'name') {
		# Use the name to get the group
		$self->{_mysql_get_Group_by_name} = $self->dbh()->prepare("SELECT id, parent, rank, name, updated FROM groups WHERE name = ?")
			unless defined($self->{_mysql_get_Group_by_name});

		$sth = $self->{_mysql_get_Group_by_name};
	}

	# Execute the query
	$sth->execute($qid);
	my($id, $parent, $rank, $name, $updated) = $sth->fetchrow();
	$sth->finish();

	# return undef if no results
	return undef unless defined($id);

	# Create the group object
	my $group = new Cellwall::Group(
		-id        => $id,
		-name      => $name,
		-rank      => $rank,
		-parent_id => $parent,
		-updated   => $updated,
	);

	return $group;
}

=head2

 Title   : get_all_Families
 Usage   : @families = $sql->get_all_Families();
 Function: Get all the families from the database
 Returns : a Cellwall::Family object
 Args    :

=cut

sub get_all_Families
{
	my( $self ) = @_;
	$self->{_mysql_get_all_Families} = $self->dbh()->prepare("SELECT id, grp, rank, name, abrev FROM family")
		unless defined($self->{_mysql_get_all_Families});
	$self->{_mysql_get_all_SubFamilies} = $self->dbh()->prepare("SELECT family, name FROM subfamily ORDER BY family, rank")
		unless defined($self->{_mysql_get_all_SubFamilies});

	# Run the query
	$self->{_mysql_get_all_Families}->execute();
	my @families = @{ $self->{_mysql_get_all_Families}->fetchall_arrayref() };
	$self->{_mysql_get_all_Families}->finish();

	$self->{_mysql_get_all_SubFamilies}->execute();
	my @subfamilies = @{ $self->{_mysql_get_all_SubFamilies}->fetchall_arrayref() };
	my %subfamilies;
	push(@{$subfamilies{$_->[0]}}, $_->[1]) foreach @subfamilies;
	$self->{_mysql_get_all_Families}->finish();

	foreach my $family (@families) {
		my( $id, $group, $rank, $name, $abrev ) = @$family;

		# Create the object
		$family = new Cellwall::Family(
			-id       => $id,
			-group_id => $group,
			-rank     => $rank,
			-name     => $name,
			-abrev    => $abrev,
		);

		$family->add_SubFamily(@{$subfamilies{$id}}) if defined $subfamilies{$id};
	}

	return @families;
}

=head2 get_Family

 Title   : get_Family
 Usage   : $fam = $sql->get_Family(1);
 Function: Get information regaurding the specified family
 Returns : A Cellwall::Family object
 Args    : An id number to fetch

=cut

sub get_Family
{
	my($self, $qtype, $qid) = @_;
	my $sth;
	
	# set id to run if called without the type => key args
	if(!defined($qid)) {
		$qid = $qtype;
		$qtype = 'id';
	}
	
	if(!defined($qid) or $qtype eq 'id') {
		# use the id to get the family
		# this is the default
		$self->{_mysql_get_Family_by_id} = $self->dbh()->prepare("SELECT id, name, abrev, updated FROM family WHERE id = ?")
			unless defined($self->{_mysql_get_Family_by_id});

		$sth = $self->{_mysql_get_Family_by_id};
	} elsif($qtype eq 'name') {
		# Use the name to get the family
		$self->{_mysql_get_Family_by_name} = $self->dbh()->prepare("SELECT id, grp, name, abrev, updated FROM family WHERE name = ?")
			unless defined($self->{_mysql_get_Family_by_name});

		$sth = $self->{_mysql_get_Family_by_name};
	}

	# Run the query
	$sth->execute($qid);
	my($id, $group, $name, $abrev, $updated) = $sth->fetchrow();
	$sth->finish();

	# return undef if no results
	return undef unless defined($id);

	# Create the family object
	my $family = new Cellwall::Family(
		-id      => $id,
		-group   => $self->get_Group($group),
		-name    => $name,
		-abrev   => $abrev,
		-updated => $updated,
	);

	# Get the sub families
	$self->{_mysql_get_SubFamilies} = $self->dbh()->prepare("SELECT name FROM subfamily WHERE family = ? ORDER BY rank")
		unless defined $self->{_mysql_get_SubFamilies};
	
	# Run the query
	$sth->execute($qid);
	while( my($name) = $sth->fetchrow() ) {
		$self->add_SubFamily($name);
	}
	$sth->finish();
	
	return $family;
}

=head2

 Title   : get_all_Sequences
 Usage   : @Sequences = $sql->get_all_Sequences();
 Function: Get all the families from the database
 Returns : a Cellwall::Sequence object
 Args    :

=cut

sub get_all_Sequences
{
	my( $self ) = @_;

	$self->{_mysql_get_all_Sequences} = $self->dbh()->prepare("SELECT id, db, family, species, accession, display, description, length, alphabet, sequence FROM sequence")
			unless defined($self->{_mysql_get_all_Sequences});

	# Run the query
	$self->{_mysql_get_all_Sequences}->execute();
	my @sequences = @{ $self->{_mysql_get_all_Sequences}->fetchall_arrayref() };
	$self->{_mysql_get_all_Sequences}->finish();

	foreach my $seq (@sequences) {
		my( $id, $db, $family, $species, $accession, $display, $description, $length, $alphabet, $seq_str ) = @$seq;

		# Create the object
		$seq = new Cellwall::Sequence(
			-primary_id       => $id,
			-database_id      => $db,
			-family_id        => $family,
			-species_id       => $species,
			-accession_number => $accession,
			-display_name     => $display,
			-description      => $description,
			-length           => $length,
			-alphabet         => $alphabet,
			-seq              => $seq_str,
		);
	}

	return @sequences;
}

=head2

 Title   : get_family_Sequences
 Usage   : @Sequences = $sql->get_family_Sequences($family->id());
 Function: get all of the sequences in a particular family
 Returns : a Cellwall::Sequence object
 Args    : a family id number

=cut

sub get_family_Sequences
{
	my( $self, $id ) = @_;

	$self->{_mysql_get_family_Sequences} = $self->dbh()->prepare("SELECT id, db, family, species, accession, display, description, length, alphabet, sequence FROM sequence WHERE family = ?")
			unless defined($self->{_mysql_get_family_Sequences});

	# Run the query
	$self->{_mysql_get_family_Sequences}->execute($id);
	my @sequences = @{ $self->{_mysql_get_family_Sequences}->fetchall_arrayref() };
	$self->{_mysql_get_family_Sequences}->finish();

	foreach my $seq (@sequences) {
		my( $id, $db, $family, $species, $accession, $display, $description, $length, $alphabet, $seq_str ) = @$seq;

		# Create the object
		$seq = new Cellwall::Sequence(
			-primary_id       => $id,
			-database_id      => $db,
			-family_id        => $family,
			-species_id       => $species,
			-accession_number => $accession,
			-display_name     => $display,
			-description      => $description,
			-length           => $length,
			-alphabet         => $alphabet,
			-seq              => $seq_str,
		);
	}

	return @sequences;
}

=head2 get_Sequence

 Title   : get_Sequence
 Usage   : $seq = $sql->get_Sequence($id);
 Function: Get information regaurding the specified sequence
 Returns : A Cellwall::Sequence object
 Args    : An id number to fetch

=cut

sub get_Sequence
{
	my($self, $qtype, $qid) = @_;
	my $sth;
	
	# set id to run if called without the type => key args
	if(!defined($qid)) {
		$qid = $qtype;
		$qtype = 'id';
	}
	
	if(!defined($qid) or $qtype eq 'id') {
		# use the id to get the sequence
		# this is the default
		$self->{_mysql_get_Sequence_by_id} = $self->dbh()->prepare("SELECT id, db, family, species, accession, display, gene_name, fullname, alt_fullname, symbols, description, length, alphabet, sequence, updated FROM sequence WHERE id = ?")
			unless defined($self->{_mysql_get_Sequence_by_id});

		$sth = $self->{_mysql_get_Sequence_by_id};
	} elsif($qtype eq 'accession') {
		# Use the accession to get the sequence
		$self->{_mysql_get_Sequence_by_accession} = $self->dbh()->prepare("SELECT sequence.id, sequence.db, sequence.family, sequence.species, sequence.accession, sequence.display, sequence.gene_name, sequence.fullname, sequence.alt_fullname, sequence.symbols, sequence.description, sequence.length, sequence.alphabet, sequence.sequence, sequence.updated FROM sequence JOIN idxref ON idxref.sequence = sequence.id WHERE idxref.accession = ? GROUP BY sequence.id")
			unless defined($self->{_mysql_get_Sequence_by_accession});

		$sth = $self->{_mysql_get_Sequence_by_accession};
	}

	# Run the query
	$sth->execute($qid);
	my($id, $db, $family, $species, $accession, $display, $gene, $fullname, $alt_fullname, $symbols, $description, $length, $alphabet, $sequence, $updated) = $sth->fetchrow();
	$sth->finish();

	# return undef if no results
	return undef unless defined($id);

	# Create the sequence
	my $seq = new Cellwall::Sequence(
		-primary_id       => $id,
		-database_id      => $db,
		-family_id        => $family,
		-species_id       => $species,
		-accession_number => $accession,
		-display_name     => $display,
		-gene_name        => $gene,
		-fullname         => $fullname,
		-alt_fullname     => $alt_fullname,
		-symbols          => $symbols,
		-description      => $description,
		-length           => $length,
		-alphabet         => $alphabet,
		-seq              => $sequence,
	);

	# Get the IDs
	$self->{_mysql_get_IDXRef_by_Id} = $self->dbh()->prepare("SELECT idxref.accession FROM idxref WHERE sequence = ?")
		unless defined($self->{_mysql_get_IDXRef_by_Id});
	
	$self->{_mysql_get_IDXRef_by_Id}->execute($qid);
	my $ids = $self->{_mysql_get_IDXRef_by_Id}->fetchall_arrayref([0]);
	$self->{_mysql_get_IDXRef_by_Id}->finish();

	# Add them
	if( defined $ids ) {
		$seq->add_secondary_accession($_->[0]) foreach @$ids;
	}
	
	return $seq;
}

=head2 get_SeqFeatures

 Title   : get_SeqFeatures
 Usage   : $species = $sql->get_SeqFeatures($id);
 Function: gets the seqfeatures for a sequences
 Returns : Array of Bio::SeqFeature::Generic objects
 Args    : An id number of the sequence

=cut

sub get_SeqFeatures
{
	my($self, $id) = @_;

	unless(defined($self->{_mysql_get_SeqFeature})) {
		# initialize the queries
		$self->{_mysql_get_SeqFeature} = $self->dbh()->prepare("SELECT id, primary_tag            FROM seqfeature  WHERE sequence   = ? ORDER BY rank");
		$self->{_mysql_get_Location}   = $self->dbh()->prepare("SELECT start_pos, end_pos, strand FROM seqlocation WHERE seqfeature = ? ORDER BY rank");
		$self->{_mysql_get_SeqTag}     = $self->dbh()->prepare("SELECT name, value                FROM seqtags     WHERE feature    = ? ORDER BY id");
	}

	# Get all the features
	$self->{_mysql_get_SeqFeature}->execute($id);
	my @features = @{$self->{_mysql_get_SeqFeature}->fetchall_arrayref()};
	$self->{_mysql_get_SeqFeature}->finish();

	# Get their location and tags, and make sequence features
	foreach my $feat (@features) {
		my ($feat_id, $primary_tag) = @$feat;

		# Make a SeqFeature object
		$feat = new Bio::SeqFeature::Generic( -primary_tag => $primary_tag );

		# Get the location[s]:
		$self->{_mysql_get_Location}->execute($feat_id);
		my @locations = @{ $self->{_mysql_get_Location}->fetchall_arrayref() };
		$self->{_mysql_get_Location}->finish();

		# If there's only one make a simple location:
		if( scalar(@locations) == 1 ) {
			$feat->location(
				new Bio::Location::Simple(
					-start  => $locations[0]->[0],
					-end    => $locations[0]->[1],
					-strand => $locations[0]->[2]
				)
			);
		} else {
			# Make a split location and add them
			my $loc = new Bio::Location::Split();
			foreach my $sub (@locations) {
				$loc->add_sub_Location(
					new Bio::Location::Simple(
						-start  => $sub->[0],
						-end    => $sub->[1],
						-strand => $sub->[2]
					)
				);
			}
			$feat->location($loc);
		}

		# Now add each tag
		$self->{_mysql_get_SeqTag}->execute($feat_id);
		my @tags = @{ $self->{_mysql_get_SeqTag}->fetchall_arrayref() };
		$self->{_mysql_get_SeqTag}->finish();
		foreach my $tag (@tags) {
			$feat->add_tag_value( $tag->[0] => $tag->[1] );
		}
	}

	return @features;
}

=head2 get_Annotation

 Title   : get_Annotation
 Usage   : $ac = $sql->get_Annotation($id);
 Function: gets the annotations for a sequences
 Returns : An annotation collection
 Args    : An id number of the sequence

=cut

sub get_Annotation
{
	my($self, $id) = @_;

	unless(defined($self->{_mysql_get_DBLink_by_id})) {
		# initialize the queries
		$self->{_mysql_get_DBLink_by_id} = $self->dbh()->prepare("SELECT section, db, href FROM dblink WHERE sequence = ?");
		$self->{_mysql_get_Comment_by_id} = $self->dbh()->prepare("SELECT comment.id, user.id, user.first, user.last, user.institute, comment.comment, comment.ref FROM comment JOIN users AS user ON user.id = comment.user WHERE sequence = ?");
	}

	# Make the annotation collection
	my $ac = new Bio::Annotation::Collection();

	# Get all of the DBLinks
	$self->{_mysql_get_DBLink_by_id}->execute($id);
	my @dblinks = @{$self->{_mysql_get_DBLink_by_id}->fetchall_arrayref()};
	$self->{_mysql_get_DBLink_by_id}->finish();
	
	foreach my $dblink (@dblinks) {
		# We kinda abuse the DBLink object here and use the
		# primary id as a link
		my($section, $database, $url) = @$dblink;
		$dblink = new Bio::Annotation::DBLink(
			-database   => $database,
			-primary_id => $url
		);

		# Now we really abuse it by altering it's hash
		$dblink->{_CW_Section} = $section;

		$ac->add_Annotation('dblink', $dblink);
	}

	# Get all of the Comments
	$self->{_mysql_get_Comment_by_id}->execute($id);
	my @comments = @{$self->{_mysql_get_Comment_by_id}->fetchall_arrayref()};
	$self->{_mysql_get_Comment_by_id}->finish();
	
	foreach my $comment (@comments) {
		my ($comment_id, $user_id, $first, $last, $institute, $text, $ref) = @$comment;
		$comment = new Bio::Annotation::Comment( -text => $text );

		# Cheat and just add some hash values to the object
		$comment->{_CW_Name} = "$last, $first [ $institute ]";
		$comment->{_CW_Reference} = $ref;
		$comment->{_CW_Uid} = $user_id;
		$comment->{_CW_Id} = $comment_id;
		
		$ac->add_Annotation('comment', $comment);
	}

	return $ac;
}

=head2 get_all_Species

 Title   : get_all_Species
 Usage   : @species = $sql->get_all_Species();
 Function: Get all the Species stored in the db
 Returns : An array of Cellwall::Species objects
 Args    : 

=cut

sub get_all_Species
{
	my($self) = @_;
	
	# create the query
	$self->{_mysql_get_all_Species} = $self->dbh()->prepare("SELECT id, genus, species, sub_species, common_name, updated FROM species")
		unless defined($self->{_mysql_get_all_Species});

	# Run the query
	$self->{_mysql_get_all_Species}->execute();
	my @species = @{ $self->{_mysql_get_all_Species}->fetchall_arrayref() };
	$self->{_mysql_get_all_Species}->finish();

	foreach my $species (@species) {
		my($id, $genus, $species, $sub_species, $common_name, $updated) = @$species;

		# Create the species object
		$species = new Cellwall::Species(
			-id          => $id,
			-genus       => $genus,
			-species     => $species,
			-sub_species => $sub_species,
			-common_name => $common_name,
			-updated     => $updated,
		);
	}
	
	return @species;
}

=head2 get_Species

 Title   : get_Species
 Usage   : $species = $sql->get_Species($id);
 Function: Get information regaurding the specified species
 Returns : A Cellwall::Species object
 Args    : An id number to fetch

=cut

sub get_Species
{
	my $self = shift @_;
	my $query;
	my $sth;

	# Default to the species id
	if(scalar(@_) == 1) {
		$query = 'id';
	} else {
		$query = shift @_;
	}

	if($query eq 'id') {
		# use the id to get the species
		$self->{_mysql_get_Species_by_id} = $self->dbh()->prepare("SELECT id, genus, species, sub_species, common_name, updated FROM species WHERE id = ?")
			unless defined($self->{_mysql_get_Species_by_id});

		$sth = $self->{_mysql_get_Species_by_id};
	} elsif($query eq 'name') {
		# Use the name to get the Species
		$self->{_mysql_get_Species_by_name} = $self->dbh()->prepare("SELECT id, genus, species, sub_species, common_name, updated FROM species WHERE genus = ? AND species = ?")
			unless defined($self->{_mysql_get_Species_by_name});

		$sth = $self->{_mysql_get_Species_by_name};
	} else {
		throw Bio::Root::Exception('get_Species called with invalid parameters');
	}


	# Run the query
	$sth->execute(@_);
	my($id, $genus, $species, $sub_species, $common_name, $updated) = $sth->fetchrow();
	$sth->finish();

	# return undef if no results
	return undef unless defined($id);

	# Create the species object
	my $object = new Cellwall::Species(
		-id          => $id,
		-genus       => $genus,
		-species     => $species,
		-sub_species => $sub_species,
		-common_name => $common_name,
		-updated     => $updated,
	);

	return $object;
}

=head2 set_Group

 Title   : set_Group
 Usage   : $sql->set_Group($group)
 Function: Update the sql entries with the group data
 Returns : 
 Args    : a group object

=cut

sub set_Group
{
	my($self, $group) = @_;
	throw Error::Simple('argument must be a Cellwall::Group')
		unless defined($group) and $group->isa('Cellwall::Group');

	# Get the group
	my $sgrp = $self->get_Group(name => $group->name());

	if($sgrp) {
		# Set the id
		$group->id($sgrp->id());
		
		# update all of the families in this group
		foreach my $family ($group->get_all_Families()) {
			$self->set_Family($family);
		}
	} else {
		# The group isn't there, so add it
		$self->add_Group($group);
	}
}

=head2 set_Family

 Title   : set_Family
 Usage   : $sql->set_Family($family)
 Function: Update the sql entries with the family data
 Returns :  
 Args    : a family object

=cut

sub set_Family
{
	my($self, $family) = @_;
	throw Error::Simple('argument must be a Cellwall::Family')
		unless defined($family) and $family->isa('Cellwall::Family');

	# Get a family object
	my $sfam = $self->get_Family(name => $family->name());

	if(defined($sfam)) {
		# There was one in the database
		$family->id($sfam->id());

		if($self->compare($family->abrev(), $sfam->abrev())) {
			$self->update_Family($sfam->id(), abrev => $family->abrev());
		}

		# Update each sequence
		foreach my $seq ($family->get_Sequences()) {
			$self->set_Sequence($seq);
		}
	} else {
		# This is a new family, so add it
		$self->add_Family($family);
	}
}

=head2 set_Sequence

 Title   : set_Sequence
 Usage   : $sql->set_Sequence($sequence)
 Function: Update the sql entries with the sequence data
 Returns :  
 Args    : a sequence object

=cut

sub set_Sequence
{
	my($self, $sequence) = @_;
	throw Error::Simple('argument must be a Cellwall::Sequence')
		unless defined($sequence) and $sequence->isa('Cellwall::Sequence');

	# Get a sequence object
	my $sseq = $self->get_Sequence(accession => $sequence->accession_number());

	if(defined($sseq)) {
		# There was one in the database
		$sequence->id($sseq->id());

		# now just check to make sure everything is the same
		if($sequence->accession_number() ne $sseq->accession_number()) {
			$self->debug(0, "File: " . ($sequence->accession || "undef"));
			$self->debug(0, "SQL:  " . ($sseq->accession || "undef"));
			throw Error::Simple('accession from MySQL is not equal to files... but thats how we got it');
		}

		$self->set_Species($sequence->species());

		if($self->compare($sequence->length(), $sseq->length())) {
			$self->update_Sequence($sseq->id(), length => $sequence->length());
		}

		if($self->compare($sequence->family()->id(), $sseq->family()->id())) {
			$self->update_Sequence($sseq->id(), family => $sequence->family());
		}

		if($self->compare($sequence->species()->id(), $sseq->species()->id())) {
			$self->update_Sequence($sseq->id(), species => $sequence->species());
		}

		if($self->compare($sequence->description(), $sseq->description())) {
			$self->update_Sequence($sseq->id(), description => $sequence->description());
		}
	} else {
		# This is a new sequence, so add it
		$self->add_Sequence($sequence);
	}
}

=head2 set_Species

 Title   : set_Species
 Usage   : $sql->set_Species($species)
 Function: Update the sql entries with the species data
 Returns :  
 Args    : a species object

=cut

sub set_Species
{
	my($self, $species) = @_;
	throw Error::Simple('argument must be a Cellwall::Species')
		unless defined($species) and $species->isa('Cellwall::Species');

	# Get a Species object
	my $sspecies = $self->get_Species(
		name => $species->genus(), $species->species()
	);

	if(defined($sspecies)) {
		# There was one in the database
		$species->id($sspecies->id());

		# now just check to make sure everything is the same
		if($self->compare($species->sub_species(), $sspecies->sub_species())) {
			$self->update_Species($sspecies->id(), sub_species => $species->sub_species());
		}

		if($self->compare($species->common_name(), $sspecies->common_name())) {
			$self->update_Species($sspecies->id(), common_name => $species->common_name());
		}
	} else {
		# This is a new species, so add it
		$self->add_Species($species);
	}
}

=head2 update_Family

 Title   : update_Family
 Usage   : $sql->update_Family($id, $field, $value)
 Function: Update the sql entries with the family data
 Returns :  
 Args    : an id, field and the new value

=cut

sub update_Family
{
	my($self, $id, $field, $value) = @_;
	
	$self->{"_mysql_update_Family_$field"} = $self->dbh()->prepare("UPDATE family SET $field = ? WHERE id = ?")
		unless defined($self->{"_mysql_update_Family_$field"});

	$self->{"_mysql_update_Family_$field"}->execute($value, $id);
	$self->debug(2, "updated $id sequence $field => $value") if defined $value;
	$self->debug(2, "updated $id sequence $field => NULL")   unless defined $value;
}

=head2 update_Sequence

 Title   : update_Sequence
 Usage   : $sql->update_Sequence($id, $field, $value)
 Function: Update the sql entries with the sequence data
 Returns :  
 Args    : an id, field and the new value

=cut

sub update_Sequence
{
	my($self, $id, $field, $value) = @_;
	
	$self->{"_mysql_update_Sequence_$field"} = $self->dbh()->prepare("UPDATE sequence SET $field = ? WHERE id = ?")
		unless defined($self->{"_mysql_update_Sequence_$field"});

	$self->{"_mysql_update_Sequence_$field"}->execute($value, $id);
	$self->debug(2, "updated $id sequence $field => $value") if defined $value;
	$self->debug(2, "updated $id sequence $field => NULL")   unless defined $value;
}

=head2 update_Species

 Title   : update_Species
 Usage   : $sql->update_Species($id, $field, $value)
 Function: Update the sql entries with the species data
 Returns :  
 Args    : an id, field and the new value

=cut

sub update_Species
{
	my($self, $id, $field, $value) = @_;
	
	$self->{"_mysql_update_Species_$field"} = $self->dbh()->prepare("UPDATE species SET $field = ? WHERE id = ?")
		unless defined($self->{"_mysql_update_Species_$field"});

	$self->{"_mysql_update_Species_$field"}->execute($value, $id);
	$self->debug(2, "updated $id species $field => $value") if defined $value;
	$self->debug(2, "updated $id species $field => NULL")   unless defined $value;
}

sub compare
{
	my($self, $a, $b) = @_;
	return 1 if defined($a) != defined($b);
	return 1 if defined($a) and $a ne $b;
	return 0;
}

sub check_Password
{
	my($self, $email, $pw) = @_;
	my $sth = $self->prepare("SELECT id FROM users WHERE email = ? AND password = password(?)");

	$sth->execute($email, $pw);
	my($id) = $sth->fetchrow();
	$sth->finish();

	return $id;
}

sub create_User
{
	my($self, $email, $pw, $first, $last, $institute, $address) = @_;
	my $sth = $self->prepare( "INSERT INTO users VALUES(NULL, ?, password(?), ?, ?, ?, ?, NULL)");
	$sth->execute( $email, $pw, $first, $last, $institute, $address );
}

=head2 insert_Row

 Title   : insert_Row
 Usage   : $sql->insert_Row($table, $a, $b, $c)
 Function: Inserts a single row into the table
 Returns :  
 Args    : a table id, then a number of values

=cut

sub insert_Row
{
	my($self, $table, @values) = @_;

	$self->{"_mysql_insert_$table"} = $self->dbh()->prepare("INSERT into $table VALUES(" . join(", ", map { "?" } @values) . ")")
		unless defined $self->{"_mysql_insert_$table"};
	
	$self->{"_mysql_insert_$table"}->execute(@values);
}

=head2 prepare

 Title   : prepare
 Usage   : $sql->prepare($query)
 Function: returns a DBI statement handler
 Returns :  
 Args    : an SQL query to prepare

=cut

sub prepare
{
	my($self, $query) = @_;
	return $self->dbh()->prepare_cached($query);
}

1;
