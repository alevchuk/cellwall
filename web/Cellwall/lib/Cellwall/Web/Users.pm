# vim:sw=4 ts=4
# $Id: CGI.pm 2 2004-04-01 23:09:24Z laurichj $

=head1 NAME

Cellwall::Web::Users

=head1 DESCRIPTION

This is the module for the Users information page.

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Web::Users;
use Cellwall;
use Error qw/:try/;
use base qw/Cellwall::Web::Index/;
use strict;

sub new
{
	my $class = shift;

	# Call the inherited new
	my $self = $class->SUPER::new(@_);

	# Set some defaults

	# We need an action
	$self->allow_Request( action => '^(\w+)$' );

	# And all the user information
	$self->allow_Request( email => '^([\w+\.\_]+@[\w+\.\_]+\.\w+)$' );
	$self->allow_Request( password   => '^(\w+)$' );
	$self->allow_Request( confirm    => '^(\w+)$' );
	$self->allow_Request( first_name => '^(\w+)$' );
	$self->allow_Request( last_name  => '^(\w+)$' );
	$self->allow_Request( institute  => '^([\w\s\.;:,]+)$' );
	$self->allow_Request( address    => '^([^<>]+)$' );

	return $self;
}

sub parse
{
	my($self) = @_;

	# Call the inherited parse
	$self->SUPER::parse();

	# Set the action
	$self->action( scalar $self->get_Request('action') );

	# Set the email
	$self->email( scalar $self->get_Request('email') );

	# Set the password
	$self->password( scalar $self->get_Request('password') );

	# Set the confirm
	$self->confirm( scalar $self->get_Request('confirm') );

	# Set the first name
	$self->first_name( scalar $self->get_Request('first_name') );

	# Set the last name
	$self->last_name( scalar $self->get_Request('last_name') );

	# Set the institute
	$self->institute( scalar $self->get_Request('institute') );

	# Set the address
	$self->address( scalar $self->get_Request('address') );
}

sub show_Login
{
	my($self) = @_;

	# Save the referal 
	$self->set_Session( referal => $ENV{HTTP_REFERER})
		if exists $ENV{HTTP_REFERER} and
		not defined $self->get_Session('referal');

	$self->add_Form(
		-action => 'users.pl',
		-method => 'post',
		-name   => 'loginform',
		-input => [
			-type => 'hidden',
			-name => 'action',
			-value => 'do_Login',
		],
		-table => [
			-format => [
				[ -width => '15%' ],
				[ -width => '85%' ],
			],
			-header => [ [ -colspan => 2, 'User Login:' ] ],
			-row => [
				'E-Mail Address:',
				-input => [
					-type  => 'text',
					-name  => 'email',
					-width => 64,
				],
			],
			-row => [
				'Password',
				-input => [
					-type  => 'password',
					-name  => 'password',
					-width => 64,
				],
			],
			-header => [
				'Actions:',
				[
					-colspan => 2,
					-input => [
						-type => 'submit',
						-target => 'loginform',
						-name => 'button',
						-value => 'Login'
					],
				]
			]
		]
	);

	$self->add_Form(
		-action => 'users.pl',
		-method => 'post',
		-name   => 'createform',
		-input => [
			-type => 'hidden',
			-name => 'action',
			-value => 'create_User',
		],
		-table => [
			-format => [
				[ -width => '15%' ],
				[ -width => '85%' ],
			],
			-header => [ [ -colspan => 2, 'Create User:' ] ],
			-row => [
				'E-Mail Address:',
				-input => [
					-type  => 'text',
					-name  => 'email',
					-width => 64,
				],
			],
			-row => [
				'Password',
				-input => [
					-type  => 'password',
					-name  => 'password',
					-width => 64,
				],
			],
			-row => [
				'Confirm',
				-input => [
					-type  => 'password',
					-name  => 'confirm',
					-width => 64,
				],
			],
			-row => [
				'First Name',
				-input => [
					-type  => 'text',
					-name  => 'first_name',
					-width => 64,
				],
			],
			-row => [
				'Last Name',
				-input => [
					-type  => 'text',
					-name  => 'last_name',
					-width => 64,
				],
			],
			-row => [
				'Institute',
				-input => [
					-type  => 'text',
					-name  => 'institute',
					-width => 64,
				],
			],
			-row => [
				'Address',
				-input => [
					-type  => 'textarea',
					-name  => 'address',
					-width => 64,
					-height => 6,
				],
			],
			-header => [
				'Actions:',
				[
					-colspan => 2,
					-input => [
						-type => 'submit',
						-target => 'createform',
						-name => 'button',
						-value => 'Create User'
					],
				]
			]
		]
	);
}

sub do_Login
{
	my($self) = @_;

	# Check password:
	if( my $uid = $Cellwall::singleton->sql()->check_Password($self->email(), $self->password())) {

		# Redirect them back to their referer
		my $url = $self->get_Session('referal');
		if(defined $url) {
			$self->add_Meta(
				'-http-equiv' => 'Refresh',
				'-content'    => sprintf('5;URL=%s', $url)
			);
			$self->delete_Session(qw/referal/);
		}

		# We're logged in
		$self->set_Session( email  => $self->email() );
		$self->set_Session( uid    => $uid );

		if(defined $url) {
			$self->add_Para( -title => sprintf('Welcome %s', $self->email()),
				'Login successful. Welcome to the Cellwall Navigator. ' .
				'You will be redirected back in 5 seconds. If your browser ' .
				'doesn\'t support this, click ',
				-link => [ 'here', $url ], '.'
			);
		} else {
			$self->add_Para( -title => sprintf('Welcome %s', $self->email()),
				'Login successful. Welcome to the Cellwall Navigator. ' .
				'Please press the Back button in your browser.'
			);
		}
	} else {
		$self->add_Para( 'Login Failed: username or password unknown' );
		$self->show_Login();
	}
}

sub create_User
{
	my($self) = @_;
	my $error = 0;

	if( not defined $self->email() ) {
		$self->add_Para( 'You must enter a valid email address' );
		$error++;
	}
	if( not defined $self->password() || not defined $self->confirm()) {
		$self->add_Para( 'You must enter your password twice' );
		$error++;
	} elsif( $self->password() ne $self->confirm() ) {
		$self->add_Para( 'Your passwords do not match' );
		$error++;
	}
	if( not defined $self->first_name() ) {
		$self->add_Para( 'You must enter a valid first name' );
		$error++;
	}
	if( not defined $self->last_name() ) {
		$self->add_Para( 'You must enter a valid last name' );
		$error++;
	}
	if( not defined $self->institute() ) {
		$self->add_Para( 'You must enter a valid institute' );
		$error++;
	}
	if( not defined $self->address() ) {
		$self->add_Para( 'You must enter a valid address' );
		$error++;
	}
	
	# If there are any errors, print the forms
	if( $error > 0 ) {
		$self->show_Login();
		return;
	}

	# Add the user
	eval {
		$Cellwall::singleton->sql()->create_User(
			$self->email(),
			$self->password(),
			$self->first_name(),
			$self->last_name(),
			$self->institute(),
			$self->address(),
		);
	};
	if($@) {
		if( $@ =~ /Duplicate entry '.+?' for key 3/o) {
			$self->add_Para("User already has an acoount");
		} else {
			$self->add_Para("Unable to create user: $@");
		}
		$self->show_Login();
		return;
	}
		
	# Check password:
	if( my $uid = $Cellwall::singleton->sql()->check_Password($self->email(), $self->password())) {

		# Redirect them back to their referer
		my $url = $self->get_Session('referal');
		if(defined $url) {
			$self->add_Meta(
				'-http-equiv' => 'Refresh',
				'-content'    => sprintf('5;URL=%s', $url)
			);
			$self->delete_Session(qw/referal/);
		}

		# We're logged in
		$self->set_Session( email  => $self->email() );
		$self->set_Session( uid    => $uid );

		if(defined $url) {
			$self->add_Para( -title => sprintf('Welcome %s', $self->email()),
				'User creation successful. Welcome to the Cellwall Navigator. ' .
				'You will be redirected back in 5 seconds. If your browser ' .
				'doesn\'t support this, click ',
				-link => [ 'here', $url ]
			);
		} else {
			$self->add_Para( -title => sprintf('Welcome %s', $self->email()),
				'User creation successful. Welcome to the Cellwall Navigator.'
			);
		}
	}
}

sub action
{
	my($self, $val) = @_;
	$self->{_action} = $val if @_ == 2;
	return $self->{_action} || 'show_Login';
}

sub email
{
	my($self, $id) = @_;
	$self->{_email} = $id if @_ == 2;
	return $self->{_email};
}

sub password
{
	my($self, $id) = @_;
	$self->{_password} = $id if @_ == 2;
	return $self->{_password};
}

sub confirm
{
	my($self, $id) = @_;
	$self->{_confirm} = $id if @_ == 2;
	return $self->{_confirm};
}

sub first_name
{
	my($self, $id) = @_;
	$self->{_first_name} = $id if @_ == 2;
	return $self->{_first_name};
}

sub last_name
{
	my($self, $id) = @_;
	$self->{_last_name} = $id if @_ == 2;
	return $self->{_last_name};
}

sub institute
{
	my($self, $id) = @_;
	$self->{_institute} = $id if @_ == 2;
	return $self->{_institute};
}

sub address
{
	my($self, $id) = @_;
	$self->{_address} = $id if @_ == 2;
	return $self->{_address};
}

1;
