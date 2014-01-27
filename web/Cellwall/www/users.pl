#!/usr/bin/perl -w
# This script is the CGI interface to the Index module
use strict;
use Cellwall;
use Cellwall::CGI;
use Cellwall::Web::Users;
use Error;

# Create the CGI object
my $cgi = new Cellwall::Web::Users(
	-author  => [ -link => ['Josh Lauricha', 'mailto:laurichj@bioinfo.ucr.edu']],
	-created => "31 Mar 2004",
	-updated => "31 Mar 2004",
);

# Parse the user input.
$cgi->parse();

# Get the Cellwall object
my $cw = $Cellwall::singleton;

# Figure out what we're doing:
if( $cgi->action() eq 'show_Login' ) {
	# Show the login prompt
	$cgi->show_Login();
} elsif( $cgi->action() eq 'do_Login' ) {
	# Log the user in
	$cgi->do_Login();
} elsif( $cgi->action() eq 'create_User' ) {
	# Create a user
	$cgi->create_User();
}

# Display it
$cgi->display();

