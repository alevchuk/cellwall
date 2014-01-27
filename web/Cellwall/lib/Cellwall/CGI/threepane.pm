# vim:sw=4 ts=4
# $Id: threepane.pm 81 2004-07-12 18:51:00Z laurichj $

=head1 NAME

Cellwall::CGI::threepane

=head1 DESCRIPTION

Cellwall::CGI::threepane is a simple three pane layout with one main
section, a left and a right section divided into sections by an invisible
table.

The default proportions are 15%, 70%, 15% for left, main, right panes.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::CGI::threepane;
use Cellwall::Root;
use Error;
use base qw/Cellwall::CGI/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/width left_size main_size right_size/;
Cellwall::CGI::threepane->mk_accessors(@ACCESSORS);

=head2 new

 Title   : new
 Usage   : not to be called directly
 Function: create and initialize a threepane CGI object
 Returns : 
 Args    : Structured HTML Data

 The is called by Cellwall::CGI, not directly.

=cut

sub new
{
	my $self = Cellwall::Root::new(@_);

	# create the three panes
	$self->{_left}  = [];
	$self->{_main}  = [];
	$self->{_right} = [];

	# Set the defaults
	$self->left_size('15%')  unless defined $self->left_size();
	$self->main_size('80%')  unless defined $self->main_size();
	$self->right_size('5%') unless defined $self->right_size();

	return $self;
}

=head2 add_Left

 Title   : add_Left
 Usage   : $cgi->add_Left( ... );
 Function: adds content to the left pane of the screen 
 Returns : 
 Args    : Structure HTML data.

=cut

sub add_Left
{
	my($self, @args) = @_;
	push(@{$self->{_left}}, @args);
}

=head2 add_Menu

 Title   : add_Menunew
 Usage   : $cgi->add_Menu(...);
 Function: Add a menu to the left pane
 Returns : 
 Args    : Structured HTML Data

 This is a wrapper around add_Left, but any arguments are wrapped into
 a menu tag.

=cut

sub add_Menu
{
	my($self, @args) = @_;
	$self->add_Left(-menu => [@args]);
}

=head2 add_Contents

 Title   : add_Contents
 Usage   : $cgi->add_Contents(...)
 Function: add contents to the main pane
 Returns : 
 Args    : Structure HTML data.

 This typically wont be called directly.

=cut

sub add_Contents
{
	my($self, @args) = @_;
	push(@{$self->{_main}}, @args);
}

=head2 add_Para

 Title   : add_Para
 Usage   : $cgi->add_Para( ... );
 Function: add a paragraph to the main pane
 Returns : 
 Args    : Structured HTML.

 The arguments are wrapped into a para tag

=cut

sub add_Para
{
	my($self, @args) = @_;
	$self->add_Contents(-para => [@args]);
}

=head2 add_Form

 Title   : add_Form
 Usage   : $cgi->add_Form( ... );
 Function: add a form to the main pane
 Returns : 
 Args    : Structured HTML Data

=cut

sub add_Form
{
	my($self, @args) = @_;
	$self->add_Contents(-form => [@args]);
}

=head2 add_Table

 Title   : add_Table
 Usage   : $cgi->add_Table( ... );
 Function: Add a table to the main pane
 Returns : 
 Args    : Structured HTML Data

=cut

sub add_Table
{
	my($self, @args) = @_;
	$self->add_Contents(-table => [@args]);
}

=head2 add_Right

 Title   : add_Right
 Usage   : $cgi->add_Right( ... );
 Function: add data to the right pane
 Returns : 
 Args    : Structured HTML Data

=cut

sub add_Right
{
	my($self, @args) = @_;
	push(@{$self->{_right}}, @args);
}

=head2 get_Left

 Title   : get_Left
 Usage   : @data = $cgi->get_Left( );
 Function: get data from the left pane
 Returns : 
 Args    : Structured HTML Data

=cut

sub get_Left
{
	my($self, @args) = @_;
	return wantarray ? @{$self->{_left}} : $self->{_left};
}

=head2 get_Contents

 Title   : get_Contents
 Usage   : @data = $cgi->get_Contents( );
 Function: get data from the main pane
 Returns : 
 Args    : Structured HTML Data

=cut

sub get_Contents
{
	my($self, @args) = @_;
	return wantarray ? @{$self->{_main}} : $self->{_main};
}

=head2 get_Right

 Title   : get_Right
 Usage   : @data = $cgi->get_Right( );
 Function: get data from the right pane
 Returns : 
 Args    : Structured HTML Data

=cut

sub get_Right
{
	my($self, @args) = @_;
	return wantarray ? @{$self->{_right}} : $self->{_right};
}

1;
