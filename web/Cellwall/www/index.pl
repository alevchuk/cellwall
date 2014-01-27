#!/usr/bin/perl -w
# This script is the CGI interface to the Index module

use lib  qw( /srv/web/Cellwall/lib );

use strict;
use Cellwall;
use Cellwall::CGI;
use Cellwall::Web::Index;
use Error;

# Create the CGI object
my $cgi = new Cellwall::Web::Index(
	-author  => [ -link => ['Josh Lauricha', 'mailto:laurichj@bioinfo.ucr.edu']],
	-created => "31 Mar 2004",
	-updated => "08 Feb 2005",
);

# Parse the user input.
$cgi->parse();

# Get the Cellwall object
my $cw = $Cellwall::singleton;


# Add the introduction paragraph
$cgi->add_Para(
	-title => 'Introduction',
	'Cell Wall Navigator (CWN) is an integrated database and mining tool for ' .
	'protein families involved in plant cell wall metabolism. Detailed ' .
	'information about this resource is available on its  ' .
	'<a href="/Cellwall/Documents/README.html">' .
	'ReadMe</a> page and the associated publication in ' . 
	'<a href="http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&amp;db=pubmed&amp;dopt=Abstract&amp;list_uids=15489283">' .
	'Plant Physiol: 136, 3003-3008</a>.'
);

$cgi->add_Para(
	-title => 'Update',
	'Incorporation of expression data from 1309 Affymetric chips.'
);

$cgi->add_FamilyTable();

# Display it
$cgi->display();
