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
	-updated => "31 Mar 2004",
);

# Parse the user input.
$cgi->parse();
$cgi->set_SubTitle('Downloads');

# Get the Cellwall object
my $cw = $Cellwall::singleton;

$cgi->add_Table(
	-format => [
		[ -valign => 'top', -width => '20%', -align => 'left'  ],
		[ -valign => 'top', -width => '80%', -align => 'left'  ],
	],
	-header => [ 'Name:' , 'Description' ],
	-row    => [
		-link => [ 'Family Proteins', 'Downloads/fam_pep.txt' ],
		'All family proteins in Cell Wall Navigator, fasta format.'
	],
	-row    => [
		-link => [ 'Family Sequences', 'Downloads/fam_seq.txt' ],
		'All family sequences in Cell Wall Navigator, GenBank format.'
	],
);

# Display it
$cgi->display();
