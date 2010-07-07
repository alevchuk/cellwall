#!/usr/bin/perl

# load module
use DBI;

# connect
my $dbh = DBI->connect("DBI:Pg:dbname=cellwall;host=cellwalldb", 
	"cellwallweb", "uXmn]h0r", {'RaiseError' => 1});

# execute SELECT query
my $sth = $dbh->prepare("SELECT * FROM cellwall.species");
$sth->execute();

# iterate through resultset
while(my $ref = $sth->fetchrow_hashref()) {
	    print "$ref->{'genus'} is $ref->{'species'}\n";
}

# clean up
$dbh->disconnect();
