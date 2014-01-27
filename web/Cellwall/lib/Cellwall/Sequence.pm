# vim:sw=4 ts=4
# $Id: Sequence.pm 152 2005-08-10 22:03:28Z laurichj $

=head1 NAME

Cellwall::Sequence

=head1 DESCRIPTION

A Cellwall::Sequence represents one sequence of a family.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Sequence;
use Bio::Annotation::Collection;
use Bio::Seq;
use Bio::Seq::RichSeq;
use Error qw/:try/;
use Cellwall::SQL;
use Cellwall::Root;
use vars qw/@ISA @ACCESSORS/;
use strict;

@ISA = qw/Bio::Seq::RichSeq Cellwall::Root/;
@ACCESSORS = qw/ database_id family_id species_id gene_name fullname alt_fullname symbols/;
Cellwall::Sequence->mk_accessors(@ACCESSORS);

=head2 new

 Title   : new
 Usage   : my $seq = new Cellwall::Sequence()
 Function: create a sequence object
 Returns : a Cellwall::Sequence object
 Args    : 

=cut

sub new
{
	my ($class, %args) = @_;
	my $self = Bio::Seq::RichSeq::new($class);

	$self->verbosity(5);

	foreach my $key (keys(%args)) {
		if(my ($attr) = ($key =~ /^-(\S+)$/o)) {
			$self->$attr($args{$key});
		}
	}

	return $self;
}

=head2 seq

 Title   : seq
 Usage   : my $str = $seq->seq();
 Function: get the sequence string
 Returns : a scalar
 Args    : none

=cut

# Inherited

=head2 subseq

 Title   : subseq
 Usage   : my $str = $seq->subseq();
 Function: get a chunk of the sequence string
 Returns : a scalar
 Args    : none

=cut

# Inherited

=head2 display_id

 Title   : primary_id
 Usage   : my $id = $seq->primary_id();
 Function: Get/Set the primary id
 Returns : a scalar
 Args    : [$newid]

 This is the numerical id stored in the MySQL database

=cut

=head2 primary_id

 Title   : primary_id
 Usage   : my $id = $seq->primary_id();
 Function: Get/Set the primary id
 Returns : a scalar
 Args    : [$newid]

 This is the numerical id stored in the MySQL database

=cut

# inherited

=head2 get_SeqFeatures

 Title   : get_SeqFeatures
 Usage   : 
 Function: returns the sequence features
 Returns : an array of Bio::SeqFeatureI objects
 Args    : 

 This may query the sql database.

=cut

sub get_SeqFeatures
{
	my($self) = @_;
	
	# Test for any sequence features:
	my @features = $self->SUPER::get_SeqFeatures();
	if(scalar(@features) > 0) {
		return @features;
	}

	if( not defined $self->{__has_seqfeatures} and defined $Cellwall::SQL::singleton ) {
		# fetch them and store them on the object
		@features = $Cellwall::SQL::singleton->get_SeqFeatures($self->primary_id());
		$self->add_SeqFeature(@features);
	}
	$self->{__has_seqfeatures} = 1;
	return @features;
}

=head2 annotation

 Title   : annotation
 Usage   : 
 Function: returns the annotation object
 Returns : 
 Args    : 

 This may query the sql database.

=cut

sub annotation
{
	my($self) = @_;

	# If they passed an arg just call the parent
	return $self->SUPER::annotation($_[1]) if scalar(@_) > 1;
	
	# Test for an existing annotation holder
	my $annotation = $self->SUPER::annotation();

	if(!defined($self->{__got_annotations})) {
		if( defined $Cellwall::SQL::singleton) {
			# fetch them and store them on the object
			$annotation = $Cellwall::SQL::singleton->get_Annotation($self->primary_id());
			$annotation->add_Annotation( $_ ) foreach grep { $_->tagname() eq 'secondary_accession' } $self->SUPER::annotation()->get_Annotations();
		} elsif( not defined $annotation ) {
			# Make sure we have a valid annotation object
			$annotation = new Bio::Annotation::Collection();
		}

		$self->SUPER::annotation($annotation);
		$self->{__got_annotations} = 1;
	}

	return $annotation;
}

=head2 species

 Title   : species
 Usage   : 
 Function: returns the species object
 Returns : 
 Args    : 

 This may query the sql database.

=cut

sub species
{
	my($self) = @_;

	# If they passed an arg just call the parent
	return $self->SUPER::species($_[1]) if scalar(@_) > 1;
	
	# Test for an existing species
	my $species = $self->SUPER::species();

	# Now, lets see if we have a species id without a species
	if(!defined($species) and defined( $self->species_id() ) ) {
		# fetch them and store them on the object
		$species = $Cellwall::SQL::singleton->get_Species($self->species_id());
		$self->SUPER::species($species);
	}

	# Return the species
	return $species;
}

=head2 family

 Title   : family
 Usage   : $sequence->family($new)
 Function: get the family for a sequence object
 Returns : the family
 Args    : an optional new family

=cut

sub family
{
	my ($self, $new) = @_;
	if( $new and $new->isa('Cellwall::Family')) {
		# Set the family reference
		$self->{_family} = $new;
	} elsif( $new ) {
		# Try to get it from Cellwall if its not an object
		$new = $Cellwall::singleton->get_Family( name => $new );

		# Throw an error if we don't have one
		throw Error::Simple("unable to find family object: $_[1]")
			unless defined $new;

		# Set the family reference
		$self->family( $new );
	} elsif( scalar(@_) == 2 ) {
		# Setting the family to undef
		$self->{_family} = $new;
	}
	
	# Now, lets see if we have a family id without a family
	if( !defined($self->{_family}) and defined( $self->family_id() ) ) {
		# Try to grab the family
		$self->{_family} = $Cellwall::singleton->get_Family( id => $self->family_id() );
	}

	# Return the family
	return $self->{_family};
}

=head2 db

 Title   : db
 Usage   : $seqence->db($new)
 Function: get the database for a search object
 Returns : the database
 Args    : an optional new database

 This is an alias for $sequence->database().

=cut

sub db {
	return Cellwall::Sequence::database(@_);
}

=head2 database

 Title   : database
 Usage   : $sequence->database($new)
 Function: get the database for a search object
 Returns : the database
 Args    : an optional new database

=cut

sub database
{
	my ($self, $new) = @_;
	if( $new and $new->isa('Cellwall::Database')) {
		# Set the database reference
		$self->{_database} = $new;
	} elsif( $new ) {
		# Try to get it from Cellwall if its not an object
		$new = $Cellwall::singleton->get_Database( name => $new );

		# Throw an error if we don't have one
		throw Error::Simple("unable to find database object: $_[1]")
			unless defined $new;

		# Set the database reference
		$self->database( $new );
	} elsif( scalar(@_) == 2 ) {
		# Setting the database to undef
		$self->{_database} = $new;
	}

	# Now, lets see if we have a database id without a database
	if( !defined($self->{_database}) and defined( $self->database_id() ) ) {
		# Try to grab the database
		$self->{_database} = $Cellwall::singleton->get_Database( id => $self->database_id() );
	}
	
	# Return the database
	return $self->{_database};
}

=head2 get_all_Proteins

 Title   : get_all_Proteins
 Usage   : $sequence->get_all_Proteins()
 Function: get the proteins from a sequence object
 Returns : an array of protein objects or a reference to one
 Args    : 

 This will find each protein in a sequence, collect the appopriate features
 and annotations for it and return an array for each of these.

=cut

sub get_all_Proteins
{
	my($self) = @_;
	my @proteins;

	# check to see if the sequence is a protein:
	if($self->alphabet() eq 'protein') {
		push(@proteins, $self);
	}

	# The locus comes from the MODEL tag
	my %locus;

	# Look for any translation tags under CDS features
	foreach my $feature ($self->get_all_SeqFeatures()) {
		# Check for a MODEL
		if($feature->primary_tag() eq 'MODEL') {
			# If we have no feat_name, we can't do anything
			next unless $feature->has_tag('feat_name');

			# Figure out the feat_name of the model
			my( $feat_name ) = $feature->get_tag_values('feat_name');
			
			# try to get the locus in order of "importance"
			($locus{$feat_name}) = $feature->get_tagset_values(qw/pub_locus alt_locus feat_name/);
		} elsif( $feature->primary_tag() eq 'CDS' ) {
			# If we have no feat_name, we can't do anything
			next unless $feature->has_tag('model');

			# Figure out the feat_name of the model
			my( $feat_name ) = $feature->get_tag_values('model');
			
			# Skip if we have no protein
			next unless $feature->has_tag('translation');
	
			# Get the protein sequece
			my ($translation) = $feature->get_tag_values('translation');
	
			# build a seq object
			my $prot = new Cellwall::Sequence(
				-primary_id       => $self->primary_id(),
				-display_id       => $locus{ $feat_name },
				-database_id      => $self->database_id(),
				-family_id        => $self->family_id(),
				-accession_number => $locus{ $feat_name },
				-description      => $self->description(),
				-species          => $self->species(),
				-db               => $self->db(),
				-seq              => $translation,
			);

			# add the protein's sequence fetures
			$prot->add_SeqFeature( $feature->get_SeqFeatures() );
			$prot->{__has_seqfeatures} = 1;

			# Add any of the 'special' tags
			foreach my $value ($feature->get_tagset_values('PFAM')) {
				my($start, $end, $family, $evalue, $desc) = ($value =~ /^(\d+)\.\.(\d+)\s+(\S+)\s+(\S+)\s+(.*)$/o);
				$prot->add_SeqFeature(
					new Bio::SeqFeature::Generic(
						-start => $start,
						-end   => $end,
						-strand => 1,
						-source_tag => 'hmmer',
						-primary_tag => 'PFAM',
						-tag => {
							evalue => $evalue,
							family => $family,
							description => $desc,
						}
					)
				);
			}

			# push the protein
			push(@proteins, $prot);
		}
	}

	return wantarray ? @proteins : \@proteins;
}

=head2 generate_Links

 Title   : generate_Links
 Usage   : $sequence->generate_Links()
 Function: make all of the links we know about on this object
 Returns : 
 Args    : 

 This will add Bio::Annotation::DBLink objects for everything we
 can think of to the sequence object.

=cut

sub generate_Links
{
	my($self) = @_;
	my @links;

	# Shortcuts so we don't keep calling functions
	my $acc = $self->accession_number();

	# Check for GO terms
	my($source) = grep { $_->primary_tag() eq 'source' } $self->get_SeqFeatures();
	if( defined $source ) {
		my @ids = map { /^ID: (\d+);/ } ($source->get_tagset_values('GO'));
		if( scalar @ids > 0 ) {
			# This is a loooong URL.
			my $link = sprintf("%s?%s&%s",
				"http://www.godatabase.org/cgi-bin/amigo/go.cgi",
				"depth=0&advanced_query=&search_constraint=terms&action=replace_tree",
				join("&", map { "query=GO:$_" } @ids )
			);
		 	push(@links, [ 'Functional',   'GO', $link ] );
		}
	}

	# Try to find any PFAM domains in the sequence
	my %pfam;
	foreach my $feature ($self->get_SeqFeatures()) {
		if( $feature->primary_tag() eq 'PFAM' and $feature->has_tag('family')) {
			my($family) = $feature->get_tagset_values('family');
			next unless defined $family;
			$pfam{$family} = 1;
		} elsif( $feature->has_tag('PFAM') ) {
			foreach my $value ($feature->get_tag_values('PFAM')) {
				# Add a PFAM link
				my ($family) = ( $value =~ /(PF\d+)/go );
				next unless defined $family;
				$pfam{$family} = 1;
			}
		}
	}

	# Add the PFam domains
	foreach my $family (keys(%pfam)) {
		push(@links, [ 'Functional', "PFAM:$family", "http://www.sanger.ac.uk/cgi-bin/Pfam/getacc?$family" ] );
	}

	# Add any Species specific links
	if( $self->species()->binomial() eq "Arabidopsis thaliana" ) {
		# Arabidopsis has lots
		push(@links, [ 'Annotation', 'TIGR',               "http://www.tigr.org/tigr-scripts/euk_manatee/shared/ORF_infopage.cgi?db=ath1&orf=$acc" ] );
		push(@links, [ 'Annotation', 'TAIR',               "http://www.arabidopsis.org/servlets/TairObject?type=locus&name=$acc" ] );
		push(@links, [ 'Annotation', 'MIPS',               "http://mips.gsf.de/cgi-bin/proj/thal/search_gene?code=$acc" ] );
		push(@links, [ 'Annotation', 'Aramemnon',          "http://aramemnon.botanik.uni-koeln.de/seq_view.ep?search=$acc" ] );
		push(@links, [ 'Functional', 'KEGG',               "http://www.genome.ad.jp/dbget-bin/www_bget?ath:$acc" ] );
		push(@links, [ 'Functional', 'AraCyc',             "http://www.arabidopsis.org:1555/ARA/NEW-IMAGE?type=GENE&object=$acc" ] );
		push(@links, [ 'Expression', 'AFGC',               "http://www.arabidopsis.org/servlets/Search?action=new_search&type=expression" ] );
		push(@links, [ 'Expression', 'NASC',               "http://ssbdjc2.nottingham.ac.uk/narrays/geneswinger.pl?searchfor=AGI&id=$acc" ] );
		push(@links, [ 'Expression', 'MPSS',               "http://mpss.udel.edu/at/GeneAnalysis.php?featureName=$acc" ] );
		push(@links, [ 'Knockout',   'SIGnAL',             "http://signal.salk.edu/cgi-bin/tdnaexpress?GENE=$acc&FUNCTION=&JOB=HITT&TDNA=&INTERVAL=1" ] );
		push(@links, [ 'Knockout',   'GABI',               "http://www.mpiz-koeln.mpg.de/GABI-Kat/db/picture.php?genecode=$acc" ] );
		push(@links, [ 'Knockout',   'Cell Wall Genomics', "http://oligogo.botany.wisc.edu/cgi-bin/CW2.cgi?Entry=$acc" ] );
	} elsif( $self->species()->binomial() eq "Oryza sativa" ) {
		# Not to many for rice
		push(@links, [ 'Annotation', 'TIGR',       "http://www.tigr.org/tigr-scripts/euk_manatee/shared/ORF_infopage.cgi?db=osa1&orf=$acc" ] );
	}
	
	# Add any source specific links, not all sequeunces have
	# a genome, so make sure one exists first
	if( $self->database() and $self->database()->genome() ) {
		# Lowercase them to avoid ambiguities
		$source = lc($self->database()->genome()->name());
	}

	if( $source eq "uniprot" ) {
		# Add the link to UniProt
		push(@links, ['Annotation', 'UniProt', "http://www.pir.uniprot.org/cgi-bin/upEntry?id=$acc" ] );
	}

	# Get each reference and try for a PubMed or Medline id
	my %pubmed;
	foreach my $ref ($self->annotation()->get_Annotations('reference')) {
		if( defined $ref->pubmed() ) {
			$pubmed{$ref->pubmed()} = 1;
		} elsif( defined $ref->medline() ) {
			$pubmed{$ref->medline()} = 1;
		}
	}

	my @pubmed = keys(%pubmed);
	if( scalar(@pubmed) > 0 ) {
		push(@links, ['Literature', 'PubMed',
			"http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?" .
			"cmd=Retrieve&db=pubmed&list_uids=" .
			join(",", @pubmed)
		]);
	}

	
	#push( @links, ['Literature', 'PubMed'
	# Add each link to the sequence
	foreach my $link (@links) {
		my($section, $db, $url) = @$link;
		$self->add_Link($section, $db, $url);
	}
}

=head2 add_Link

 Title   : add_Link
 Usage   : $sequence->add_Link($section, $db, $url)
 Function: add a link to the sequence
 Returns : 
 Args    : a Section, a Database and a URL

 This adds a link to the sequence. However, this will NOT insert
 it into the database. As soon as this object is out of memory,
 the new link is lost.
 
=cut

sub add_Link
{
	my($self, $section, $db, $url) = @_;

	# We kinda abuse the DBLink object here and use the
	# primary id as a link
	my $dblink = new Bio::Annotation::DBLink(
		-database   => $db,
		-primary_id => $url
	);

	# Now we really abuse it by altering it's hash
	$dblink->{_CW_Section} = $section;

	$self->annotation()->add_Annotation('dblink', $dblink);
}

sub id
{
	my($self) = @_;
	return $self->accession_number();
}

1;
