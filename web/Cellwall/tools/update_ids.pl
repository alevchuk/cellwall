#!/usr/bin/perl -w
use strict;
use Bio::SearchIO;

my $search = new Bio::SearchIO(
	-format => 'blast',
	-fh => \*STDIN,
);

while(my $result = $search->next_result()) {
	print "Query: ", $result->query_name();
	my $low = 100;
	my $low_ident = 0;
	my $low_acc = 'foo';

	while(my $hit = $result->next_hit()) {
		while(my $hsp = $hit->next_hsp()) {
			if($low > $hsp->evalue()) {
				$low = $hsp->evalue();
				$low_acc = (split(/\|/, $hit->name()))[0];
				$low_ident = $hsp->frac_identical('total');
			}
		}
	}
	print " might be $low_acc ($low/$low_ident)\n";
}
