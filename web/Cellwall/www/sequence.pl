#!/usr/bin/perl -w

use lib  qw( /srv/web/Cellwall/lib /srv/web/Cellwall/lib/Cellwall/Web 
	     /usr/local/lib/perl/5.10.1/Bio );

# This script is the CGI interface to the Sequence module
use strict;
use Cellwall;
use Cellwall::CGI;
use Cellwall::Web::Sequence;
use Error;

# Create the CGI object
my $cgi = new Cellwall::Web::Sequence(
	-author  => [ -link => ['Josh Lauricha', 'mailto:laurichj@bioinfo.ucr.edu']],
	-created => "04 Apr 2004",
	-updated => "04 Apr 2004",
);

# Parse the user input.
$cgi->parse();

# Display some sequence information

# Get the sequence
my $seq = $cgi->sequence();

# Figure out what we're doing:
if( $cgi->action() eq 'sequence' ) {
	$cgi->add_Sequence($seq);
} elsif( $cgi->action() eq 'render_seqview' ) {
	$cgi->render_SeqView($seq);
} elsif( $cgi->action() eq 'features' or $cgi->action() eq 'Highlight') {
	$cgi->add_Sequence($seq);
	$cgi->add_FeatureTable($seq);
} elsif( $cgi->action() eq 'download' ) {
	$cgi->download_Sequence($seq);
} elsif( $cgi->action() eq 'results' ) {
	$cgi->add_Sequence($seq);
	$cgi->add_Results($seq);
} elsif( $cgi->action() eq 'render_results' ) {
	$cgi->render_Results($seq);
} elsif( $cgi->action() eq 'edit' ) {
	$cgi->edit_Sequence($seq);
} elsif( $cgi->action() eq 'add_ExternalLink' ) {
	$cgi->add_ExternalLink($seq);
} elsif( $cgi->action() eq 'view_Comment' ) {
	$cgi->view_Comment($seq);
} elsif( $cgi->action() eq 'add_Comment' ) {
	$cgi->add_Comment($seq);
} elsif( $cgi->action() eq 'edit_Comment' ) {
	$cgi->edit_Comment($seq);
} elsif( $cgi->action() eq 'delete_Comment' ) {
	$cgi->delete_Comment($seq);
} else {
	$cgi->add_Para(
		-title => 'ERROR!',
		'This is an invalid query, please press the back button on your browser ',
		'and try again. If this error persists, contact the page administrator.'
	);
}

# Display it
$cgi->display();
