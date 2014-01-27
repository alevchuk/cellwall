#!/usr/bin/perl -w

use lib  qw( /srv/web/Cellwall/lib /srv/web/Cellwall/lib/Cellwall );

# This script is the CGI interface to the Search module
use strict;
use Cellwall;
use Cellwall::CGI;
use Cellwall::Web::Search;
use Error;

# Create the CGI object
my $cgi = new Cellwall::Web::Search(
	-author  => [ -link => ['Josh Lauricha', 'mailto:laurichj@bioinfo.ucr.edu']],
	-created => "04 Apr 2004",
	-updated => "04 Apr 2004",
);

# Parse the user input.
$cgi->parse();

# Figure out what to do
if( !defined($cgi->get_Request('step')) ) {
	$cgi->add_SearchForm();
} elsif( $cgi->get_Request('step')  eq 'submit' ) {
	$cgi->submit_Search();
} elsif( $cgi->get_Request('step') eq 'show' ) {
	$cgi->show_Search();
}

# Display it
$cgi->display();
