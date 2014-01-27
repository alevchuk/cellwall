# vim:sw=4 ts=4
# $Id: CGI.pm 2 2004-04-01 23:09:24Z laurichj $

=head1 NAME

Cellwall::Web::Index

=head1 DESCRIPTION

This is the module for the main Cellwall page. 

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Web::Index;
use Cellwall;
use Error;
use base qw/Cellwall::CGI::default/;
use strict;

my $cw;

sub new
{
	my $class = shift;

	# Call the inherited new
	my $self = $class->SUPER::new(@_);

	# create the cellwall object if its not there
	if(!defined( $cw )) {
		# Create the Cellwall object
		$cw = new Cellwall(
			-host     => 'localhost',
			-db       => 'cellwall',
			-base     => '/srv/web/Cellwall/current',
			#-host     => $ENV{CELLWALL_HOST},
			#-db       => $ENV{CELLWALL_DB},
			#-user     => $ENV{CELLWALL_USER},
			#-password => $ENV{CELLWALL_PASSWD},
			#-base     => $ENV{CELLWALL_BASE},
		);

		# Load the root SQL database
		$cw->query_root();
	}

	# Set some defaults

	# Tell the world who we are
	$self->set_Title("Cell Wall Navigator");

	# Get the web base
	my( $cwd ) = ( $ENV{SCRIPT_FILENAME} =~ /^(.*)\/[^\/]+$/o );

	# Add their main menu if there is one
	if( -f "$cwd/menu.xml" ) {
		$self->add_Left(
			-include => "$cwd/menu.xml"
		);
	} else {
		# All pages should have a Main menu
		$self->add_Menu(
			'Main',
			-link => [ 'Index',      'index.pl'  ],
			-link => [ 'Search',     'search.pl' ],
			-link => [ 'Statistics', 'statistics.pl'  ],
		);
	}

	return $self;
}

sub parse
{
	my($self) = @_;
	$self->SUPER::parse();

	# Start or continue the session
	$self->start_Session();
}

sub add_FamilyTable
{
	my($self) = @_;

	# Create the table:
	my @table = (
		-format => [
			# We use blocks to indent things, down to 5%
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width =>  '5%', -align => 'left'  ],
			[ -valign => 'top', -width => '40%', -align => 'right' ],
		],
	);

	$self->{_max} = 12;

	# Add the groups:
	foreach my $group ($cw->get_all_Groups()) {
		push(@table, $self->table_add_group(0, undef, $group)) if not defined $group->parent();
	}

	# Add the table to the page
	$self->add_Table( @table );
}

sub table_add_group
{
	my($self, $depth, $prefix, $group) = @_;

	# Set the prefix
	$prefix = sprintf(defined $prefix ? "$prefix.%d" : "%d", $group->rank());
	
	# Add the group's line
	my @table = (
		-header => [ 
			( '' ) x $depth, # pad over
			[ -colspan => $self->{_max} - $depth + 1, sprintf('%s %s', $prefix, $group->name()) ]
		]
	);

	# Add each child
	foreach my $child ($group->get_all_Children()) {
		if( $child->isa('Cellwall::Group') ) {
			push(@table, $self->table_add_group($depth + 1, $prefix, $child));
		} elsif( $child->isa('Cellwall::Family') ) {
			push(@table, $self->table_add_family($depth + 1, $prefix, $child));
		}
	}

	return @table;
}

sub table_add_family
{
	my($self, $depth, $prefix, $family) = @_;

	# Set the prefix
	$prefix = sprintf(defined $prefix ? "$prefix.%d" : "%d", $family->rank());

	# Add the table's line
	my $i = 1;
	return (
		-row => [
			( '' ) x $depth, # pad over
			[ -class => 'family', -colspan => $self->{_max} - $depth, [ "$prefix ", -link => [ sprintf("%s (%s)", $family->name(), $family->abrev()), 'family.pl?family_id=' . $family->id() ] ] ],
			-list => [
				-link => [ 'Genbank',   sprintf('family.pl?action=download_Family&amp;format=genbank&amp;family_id=%d', $family->id()) ],
				-link => [ 'Fasta',     sprintf('family.pl?action=download_Family&amp;format=fasta&amp;family_id=%d', $family->id()) ],
				-link => [ 'Structure', sprintf('family.pl?action=show_Structure&amp;family_id=%d', $family->id()) ],
			],
		],
		map { -row => [ ( '' ) x ( $depth + 1 ), [ -colspan => $self->{_max} - $depth - 1, -small => [ sprintf('%s.%i %s', $prefix, $i++, $_) ] ] ] } $family->get_SubFamilies()
	);
}

1;
