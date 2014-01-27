#!/usr/bin/perl -w
use strict;
use lib split(':', $ENV{CELLWALL_LIB});
use Bio::SearchIO;
use Cellwall;
use Getopt::Std;

my %opts;
getopts('H:d:u:p:b:', \%opts);

my $cw = new Cellwall(
	-host     => $opts{H} || $ENV{CELLWALL_HOST},
	-db       => $opts{d} || $ENV{CELLWALL_DB},
	-user     => $opts{u} || $ENV{CELLWALL_USER},
	-password => $opts{p} || $ENV{CELLWALL_PASSWD},
	-base     => $opts{b} || $ENV{CELLWALL_BASE},
);


my $search = new Bio::SearchIO(
	-format => 'hmmer',
	-fh => \*ARGV
);

my $selcds = $cw->sql()->prepare(
	"SELECT cds.id " .
	"FROM seqtags AS a JOIN seqtags AS b ON b.feature = a.feature " .
	"JOIN seqtags AS c ON c.value = b.value JOIN seqfeature AS cds " .
	"ON cds.id = c.feature WHERE a.value = ? AND " .
	"b.name = 'feat_name' AND c.name = 'model' AND " . 
	"cds.primary_tag = 'CDS'"
);
my $addtag = $cw->sql()->prepare(
	"INSERT INTO seqtags VALUES(NULL, ?, ?, ?, NULL)"
);
my $getrank = $cw->sql()->prepare(
	'SELECT max(rank) + 1 FROM seqfeature WHERE sequence = ? GROUP BY sequence'
);
my $addfeat = $cw->sql()->prepare(
	'INSERT INTO seqfeature VALUES(NULL, ?, ?, ?, NULL)'
);
my $addloc = $cw->sql()->prepare(
	'INSERT INTO seqlocation VALUES(NULL, ?, ?, ?, ?, ?, NULL)'
);
my $getfeat = $cw->sql()->prepare(
	"SELECT id, rank FROM seqfeature WHERE sequence = ? AND " .
	"primary_tag = ? ORDER BY rank DESC LIMIT 1"
);
my $addlink = $cw->sql()->prepare(
	'INSERT INTO dblinks VALUES(NULL, "functional", ?, ?, ?, NULL)'
);

while(my $result = $search->next_result()) {
	my $id = $result->query_name();
	# Get the CDS id:
	$selcds->execute($id);
	my($cds_id) = $selcds->fetchrow_array();
	$selcds->finish();

	while(my $hit = $result->next_hit()) {
		$addlink->($id, 'PFAM:' . $hit->name(), 'http://www.sanger.ac.uk/cgi-bin/Pfam/getacc?' . $hit->name());
		if( defined $cds_id ) {
			my $value = sprintf('%d..%d %s %s %s',
				$hit->start('query'),
				$hit->end('query'),
				$hit->name(),
				$hit->significance(),
				$hit->description()
			);

			# Add the tag
			$addtag->execute($cds_id, 'PFAM', $value);
			print "Adding tag value\n";
		} else {
			my $seq = $cw->sql()->get_Sequence(accession => $id);

			# Add a feature
			$getrank->execute($seq->primary_id());
			my($rank) = $getrank->fetchrow_array();
			$rank = 0 unless defined $rank;
			$addfeat->execute( $seq->primary_id(), $rank, 'PFAM' );
			$getfeat->execute($seq->primary_id(), 'PFAM');
			my($feat_id) = $getfeat->fetchrow_array();
			die "unable to get feature!! $id" unless defined $feat_id;
			print "Added $feat_id to $id\n";
			$addtag->execute($feat_id, 'family', $hit->name());
			$addtag->execute($feat_id, 'evalue', $hit->significance());
			$addtag->execute($feat_id, 'description', $hit->description());
			$addloc->execute($feat_id, 0, $hit->start('query'), $hit->end('query'), 1);
		}
	}
}
