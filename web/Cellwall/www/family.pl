#!/usr/bin/perl -w
use lib  qw( /srv/web/Cellwall/lib );

# This script is the CGI interface to the Family module
use strict;
use Cellwall;
use Cellwall::CGI;
use Cellwall::Web::Family;
use Error;

# Create the CGI object
my $cgi = new Cellwall::Web::Family(
	-author  => [ -link => ['Josh Lauricha', 'mailto:laurichj@bioinfo.ucr.edu']],
	-created => "04 Apr 2004",
	-updated => "04 Apr 2004",
);

# Parse the user input.
$cgi->parse();

# Get the Cellwall object
my $cw = $Cellwall::singleton;

# Get the family
my $family = $cgi->get_Family();

# Tell the world who we are
$cgi->set_SubTitle('Family: ' . $family->name());

# Display some family information
my( $cwd ) = ( $ENV{SCRIPT_FILENAME} =~ /^(.*)\/[^\/]+$/o );
my $file = sprintf('%s/Families/%s.xml', $cwd, $family->abrev());
if( -f $file ) {
	open(FAMILY_FILE, $file);
	my @lines = <FAMILY_FILE>;
	$cgi->add_Para( -title => 'Family Information:', join("\n", @lines));
	close(FAMILY_FILE);
}

# Figure out what we're doing:
if( $cgi->action() eq 'show_Members' ) {
	# Do the default, display the members
	$cgi->show_Members($family);
} elsif( $cgi->action() eq 'show_Alignment' ) {
	# Show the alignment image
	$cgi->show_Alignment($family);
} elsif( $cgi->action() eq 'show_Tree' ) {
	# Show the tree
	$cgi->show_Tree($family);
} elsif( $cgi->action() eq 'Map in Tree' ) {
	# Show the tree
	$cgi->show_Tree($family);
} elsif( $cgi->action() eq 'render_Tree') {
	# Render the tree
	$cgi->render_Tree($family);
} elsif( $cgi->action() eq 'download_Family') {
	# Download the family
	$cgi->download_Family($family);
} elsif( $cgi->action() eq 'download_Alignment') {
	# Download the alignment
	$cgi->download_Alignment($family);
} elsif( $cgi->action() eq 'show_Structure') {
	# Show each sequence's structure
	$cgi->show_all_Structures($family);
}

# Display it
$cgi->display();
