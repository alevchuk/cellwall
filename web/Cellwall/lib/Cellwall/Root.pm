# vim:sw=4 ts=4
# $Id: Root.pm 89 2004-07-26 15:53:41Z laurichj $

=head1 NAME

Cellwall::Root

=head1 DESCRIPTION

This object is the root of the Cellwall class tree. This provides the default
instantiation function as well as several common functions.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Root;
use Carp;
use Data::Dumper;
use Error qw/:try/;
use Class::Accessor;
use base qw/Class::Accessor/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/verbosity/;
Cellwall::Root->mk_accessors(@ACCESSORS);

sub new
{
	my($class, %args) = @_;
	my $self = bless {}, ref($class) || $class;

	$self->verbosity(5);

	foreach my $key (keys(%args)) {
		if(my ($attr) = ($key =~ /^-(\S+)$/o)) {
			$self->$attr($args{$key});
		} else {
			croak("invalid attribute: $key");
		}
	}

	$self->_init();
	return $self;
}

sub _init
{
}

sub _load_module
{
	my($self, $module) = @_;

	eval "require $module";
	throw Error::Simple("unable to load $module\: $@") if $@;
}

sub _add_Array
{
	my($self, $name, $value) = @_;
	$name = "_array_$name";

	if(defined($self->{$name})) {
		push(@{$self->{$name}}, $value);
	} else {
		$self->{$name} = [ $value ];
	}

	return scalar(@{$self->{$name}}) - 1;
}

sub _get_Array
{
	my($self, $name, $slot) = @_;

	if(!defined($slot)) {
		if(wantarray) {
			return @{$self->{"_array_$name"}} if defined $self->{"_array_$name"};
			return ();
		} else {
			return $self->{"_array_$name"};
		}
	} else {
		return $self->{"_array_$name"}->[$slot];
	}
}

sub _add_Index
{
	my($self, $name, $value, @fields) = @_;

	my $slot = $self->_add_Array($name, $value);

	while( my ($index, $value) = splice(@fields, 0, 2) ) {
		$self->{'_index_' . $name . '_' . $index}->{$value} = $slot;
	}

	return $slot;
}

sub _get_Index
{
	my($self, $name, $field, $value) = @_;

	my $slot = $self->{'_index_' . $name . '_' . $field}->{$value};

	return undef unless defined($slot) and $slot >= 0;

	return $self->_get_Array($name, $slot);
}

sub debug
{
	my($self, $level, $message) = @_;
	return if $level > $self->verbosity();
	print STDERR "[$level] $message\n";
}

sub warn
{
	my($self, $message) = @_;
	carp $message;
}

sub dump
{
	my($self, $level, @dump) = @_;
	return if $level > ( $self->verbosity() || 0 );
	print STDERR "[$level] " . Dumper(@dump) . "\n";
}


1;
