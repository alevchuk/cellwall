#!/usr/bin/perl -w
# This is a simple XML-Filter to update the Rice ID Numbers.
# Usage:
# 	./rice_version.pl rice.version.converter.txt < cellwall.xml > cellwall.new.xml

use XML::Twig;
use strict;

my %versions;

# Load and parse the version file

my $ver_file = shift;

open(VERFILE, $ver_file) || die "unable to open $ver_file $!";
my $junk = <VERFILE>;

while( my $line =  <VERFILE>) {
	my ($ind, @vers) = split(/\s+/o, $line);

	foreach my $v (@vers) {
		$versions{$v} = $vers[-1];
	}
}

close(VERFILE);


# Parse the file
my $t = new XML::Twig(
	twig_roots => {
		"family/genome" => \&convert_genome
	},
	twig_print_outside_roots => 1,
	keep_spaces => 1,
	#pretty_print => 'indented',
);

$t->parse(\*STDIN);

sub convert_genome
{
	my($t, $genome) = @_;

	# Check for a rice genome
	my $source = $genome->{att}->{name};

	if( $source eq 'O. sativa' ) {
		# Fix the ids
		foreach my $seq ($genome->children()) {
			my $acc = $seq->trimmed_text();
			if( exists $versions{$acc} ) {
				$seq->set_text( $versions{$acc} );
			}
		}
	}

	$genome->print();
}
