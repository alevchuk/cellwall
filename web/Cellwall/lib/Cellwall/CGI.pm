# vim:sw=4 ts=4
# $Id: CGI.pm 120 2005-05-31 16:50:39Z laurichj $

=head1 NAME

Cellwall::CGI

=head1 DESCRIPTION

Cellwall::CGI is a relativly simple frontend for generating webpages. It
abstracts all of the HTML out of the code, into one of several object based
themes. It also provides utilities for parsing and validating GETs, POSTs, and
cookies and provides a stable interface for server-side sessions.

=head1 VALIDATION

This module provides a simple mechanism for validating incoming GET, POST, and
cookie data, along with request data which is GET or POST with POST having
higher precidence. For simplicity, setting rules for each of these and
retrieving them.

For data to appear in the CGI object it must match one of the rules. The rules
follow a few basic forms: a simple regular expression, an array of rules, or a
function. Each is briefly explained.

=head2 RegExp

A regular expression is simply matched against the value and any captured data
is stored. For instance, to match a telephone number the following world work
in the US:

    $cgi->allow_Get( phone => '^((?:\d-)?\d{3}-\d{3}-\d{4})' );

This would match any number in the form: [#-]###-###-####, adding a single
entry, retrievable with $cgi->get_Get('phone'). This:

    $cgi->allow_Get( phone => '^(\d-)?(\d{3})-(\d{3})-(\d{4})' );

would behave slightly differently, matching the same values but adding a single
entry of the form: [ '#', '###', '###', '####' ], where the first value is
optional.

=head2 Function

Since RegExp can't always cover everything, subroutines are allowed. These can
be either anonymous or named. The first argument is the CGI object, the second
is the key, and the third the value. The value added is the value[s] returned
by the function.  If undef is returned, nothing is added.

One thing to note, is if a reference to an array is returned one item is added,
but if an array is return the array is appened to the current items.

=head2 Arrays

An array of rules works by iterating through each rule until one matches.  It
adds the value[s] matched by the rule.

=head2 Setting Rules

There are two ways to set rules. The first is in the constructor, simply supply
an argument pointing to the rules: A scalar representing the RegExp, an
reference to code or a reference to an array. Ex:

	my $cgi = new Cellwall::CGI(
		...
		cookie => {
			... => ...
		},
		request => {
			... => ...
		},
		...
	);

	# Now, apply all the rules and get the input
	$cgi->parse();
			

The second way is what has been shown, use:

	$cgi->allow_Get(     val => ... );
	$cgi->allow_Post(    val => ... );
	$cgi->allow_Request( val => ... );
	$cgi->allow_Cookie(  val => ... );

Where ... is replaces with the previously described scalar or reference.  The
rules allowed to Request are also allowed to Get and Post, however the rules
supplied to Get and Post are tried first.

=head2 Retrieving Data

To retrieve data that has passed the validation stage use get_Get, get_Post,
get_Cookie or get_Request. Each takes the name of the value to get. The return
value is an array if an array is wanted. Otherwise, if there is more than one
value it is returned; if there is more than one a reference to an array is
returned.

$x = $cgi->get_Request('x') is equivilent to:
    $x = $cgi->get_Post('x') || $cgi->get_Get('x');

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::CGI;
use Apache::Session::File;
use HTML::Entities;
use Error qw/:try/;
use base qw/Cellwall::Root/;
use vars qw/@ACCESSORS/;
use strict;

@ACCESSORS = qw/style title created updated author/;
Cellwall::CGI->mk_accessors(@ACCESSORS);

=head2 new

 Title   : new
 Usage   : $cgi = new Cellwall::CGI()
 Function: Creates a new CGI object
 Returns : a Cellwall::CGI object
 Args    :

=cut

sub new
{
	my ($class, %args) = @_;
	# Figureout what module to load
	my $module = "Cellwall::CGI::" . ( $args{-style} || "default" );

	# Load the module
	$class->_load_module($module);

	# Create a new one:
	my $self = $module->new(%args);

	# Initialize base class stuff
	
	# Put an empty hash in the session
	$self->{_session} = {};
	
	return $self;
}

sub parse
{
	my($self) = @_;

	# This stuff is here because CGI->new is not always called.

	# Allow the session cookie to go through
	$self->allow_Cookie( _session_id => '^([\d\w]+)$' );

	# Allow a session to go through a GET
	# TODO: actually implement this... this needs to hide a parameter
	#       in each link.... probably just do it in apply_link, and
	#       a way to determine if the browser supports cookies.
	$self->allow_Get( _session_id => '^([\d\w]+)$' );


	# Figure out how we were called and what to parse
	$self->_parse_argv()   if @ARGV > 0;
	$self->_parse_get()    if defined($ENV{'QUERY_STRING'});
	$self->_parse_post()   if defined($ENV{'REQUEST_METHOD'}) and $ENV{'REQUEST_METHOD'} eq 'POST';
	$self->_parse_cookie() if defined($ENV{'HTTP_COOKIE'});
}

=head1 CGI Functions

=head2 encode

 Title   : encode
 Usage   : $text = $cgi->encode( $text )
 Function: Encodes text into escaped HTML
 Returns : Escaped HTML
 Args    : A value to encode

=cut

sub encode
{
	my($self, $val) = @_;
	return HTML::Entities::encode($val);
}

=head2 decode

 Title   : decode
 Usage   : $text = $cgi->decode( $text )
 Function: Decodes escaped HTML into  text
 Returns : Plain ASCII
 Args    : A value to decode

=cut

sub decode
{
	my($self, $val) = @_;
	return HTML::Entities::decode($val);
}

=head2 _rules_constructor

 Title   : _rules_constructor
 Usage   : internal function
 Function: Parse the constructor arguments and create
           a validation hash
 Returns :
 Args    :

=cut

sub _rules_constructor
{
	my($self) = shift;
	my %rules;

	# This can be either a hash reference, an array reference
	# or an array.
	
	while( my $arg = shift @_ ) {

		if( ref($arg) eq 'HASH' ) {
			# Its a hashref, add all the rules
			foreach my $name (keys(%$arg)) {
				$rules{$name} = $arg->{$name};
			}
		} elsif( ref($arg) eq 'ARRAY' ) {
			# Coerce the array into a hash
			my %subrules = @$arg;

			# Add all the subrules
			foreach my $name (keys(%subrules)) {
				$rules{$name} = $subrules{$name};
			}
		} elsif( !ref($arg) and ref(\$arg) eq 'SCALAR' ) {
			# Its a name, so add it
			$rules{$arg} = shift @_;
		}
	}

	return \%rules;
}

=head2 cookie

 Title   : cookie
 Usage   : $cgi->cookie( ... )
 Function: Set the cookie validation hash
 Returns :
 Args    :

 See the introduction for more information

=cut

sub cookie
{
	my $self = shift @_;

	# Since they are all handled the same way, we just use the
	# other function:

	# Since this is ment to be used in the constructor, put the rules
	# into the hash, but override anything else.
	$self->{_cookie_rules} = $self->_rules_constructor(@_);
}

=head2 get

 Title   : get
 Usage   : $cgi->get( ... )
 Function: Set the get validation hash
 Returns :
 Args    :

 See the introduction for more information

=cut

sub get
{
	my $self = shift @_;

	# Since they are all handled the same way, we just use the
	# other function:

	# Since this is ment to be used in the constructor, put the rules
	# into the hash, but override anything else.
	$self->{_get_rules} = $self->_rules_constructor(@_);
}

=head2 post

 Title   : post
 Usage   : $cgi->post( ... )
 Function: Set the post validation hash
 Returns :
 Args    :

 See the introduction for more information

=cut

sub post
{
	my $self = shift @_;

	# Since they are all handled the same way, we just use the
	# other function:

	# Since this is ment to be used in the constructor, put the rules
	# into the hash, but override anything else.
	$self->{_post_rules} = $self->_rules_constructor(@_);
}

=head2 request

 Title   : request
 Usage   : $cgi->request( ... )
 Function: Set the request validation hash
 Returns :
 Args    :

 See the introduction for more information

=cut

sub request
{
	my $self = shift @_;

	# Since they are all handled the same way, we just use the
	# other function:

	# Since this is ment to be used in the constructor, put the rules
	# into the hash, but override anything else.
	$self->{_request_rules} = $self->_rules_constructor(@_);
}

=head2 allow_Cookie

 Title   : allow_Cookie
 Usage   : $cgi->allow_Cookie( ... )
 Function: add to the cookie validation hash
 Returns :
 Args    :

 See the introduction for more information

=cut

sub allow_Cookie
{
	my($self, $key, $rule) = @_;
	$self->{_cookie_rules}->{$key} = $rule;
}

=head2 allow_Get

 Title   : allow_Get
 Usage   : $cgi->allow_Get( ... )
 Function: add to the get validation hash
 Returns :
 Args    :

 See the introduction for more information

=cut

sub allow_Get
{
	my($self, $key, $rule) = @_;
	$self->{_get_rules}->{$key} = $rule;
}

=head2 allow_Post

 Title   : allow_Post
 Usage   : $cgi->allow_Post( ... )
 Function: add to the post validation hash
 Returns :
 Args    :

 See the introduction for more information

=cut

sub allow_Post
{
	my($self, $key, $rule) = @_;
	$self->{_post_rules}->{$key} = $rule;
}

=head2 allow_Request

 Title   : allow_Request
 Usage   : $cgi->allow_Request( ... )
 Function: add to the request validation hash
 Returns :
 Args    :

 See the introduction for more information

=cut

sub allow_Request
{
	my($self, $key, $rule) = @_;
	$self->{_request_rules}->{$key} = $rule;
}

=head2 error

 Title   : error
 Usage   : $cgi->error( $message )
 Function: Die with a message to the user
 Returns :
 Args    : The message to display

 This is ment to be used to display a fatal error to the user, which
 is not a coding problem but an input error or system error.

 No error message is loged ( unless other code generates it ).

=cut

sub error
{
	my($self, @message) = @_;
	$self->set_SubTitle('ERROR');
	@{$self->{content}} = ();

	$self->add_Para(
		-title => 'An Error Has Occured',
		@message
	);

	$self->display();
	exit();
}

=head2 headers

 Title   : headers
 Usage   : $cgi->headers( )
 Function: Get the headers string
 Returns : The typical HTTP headers string
 Args    : 

 This is ment to be used both internally and when the script is being
 used to generate non-HTML content, in which case the script should
 do:

 	print $cgi->headers();
	print $Content;

=cut

sub headers
{
	my ($self) = @_;

	# The content type defaults to plain text
	my $type = $self->mime() || 'text/plain';
	my $ret = '';

	# Generate the cookies
	foreach my $cookie (@{$self->{cookies}}) {
		$ret .= 'Set-Cookie: ';
		$ret .=  $cookie->{name} . '=' . $cookie->{value};
		foreach my $field (qw/expires domain path/) {
			next unless defined($cookie->{$field});
			$ret .= '; ' . $field . '=' . $cookie->{$field};
		}
		$ret .=  '; secure' if defined($cookie->{secure});
		$ret .=  "\n";
	}
	
	$ret .=  "Content-type: $type\n\n";
	return $ret;
}

=head2 add_Error

 Title   : add_Error
 Usage   : $cgi->add_Error( $message )
 Function: add an error
 Returns : 
 Args    : The error message

 The module allows for errors to be stored on it so that more than
 one error message may be displayed at a time to the user. This
 is useful for validating forms.

 The script needs to check for errors and handle them.

=cut

sub add_Error
{
	my($self, @args) = @_;
	push(@{$self->{errors}}, @args);
}

=head2 get_Errors

 Title   : get_Errors
 Usage   : my @errors = $cgi->get_Errors(  )
 Function: 
 Returns : an array of error messages
 Args    : 

=cut

sub get_Errors
{
	my($self) = @_;
	if(defined($self->{errors})) {
		my @array = @{$self->{errors}};
		return wantarray ? @array : \@array;
	} else {
		return wantarray ? () : undef;
	}
}

=head2 add_Cookie

 Title   : add_Cookie
 Usage   : $cgi->add_Cookie( $name, $value, ... );
 Function: add a cookie to be sent
 Returns : 
 Args    : The name and value of the cookie plus
           any parameters such as -expires, -domain,
           -path and -secure. Each parameter needs a
           value. The cookie is treated as secure if
           -secure has a true value.

=cut

sub add_Cookie
{
	my($self, $name, $value, %hash) = @_;
	my $h;

	$h->{name} = $name;
	$h->{value} = $value;

	foreach (keys(%hash)) {
		$h->{$1} = $hash{$_} if /^-(\w+)$/so;
	}

	push(@{$self->{cookies}}, $h);
}

=head2 get_Cookie

 Title   : get_Cookie
 Usage   : my $cookie = $cgi->get_Cookie( $name )
 Function: 
 Returns : a cookie
 Args    : the name of the cookie to return

 If $name is undef, then this returns the names of
 all cookies.

=cut

sub get_Cookie
{
	my($self, $key) = @_;

	# Return the keys if no key specified
	return keys(%{$self->{_cookie_values}}) unless $key;
	
	# Return the array if wantarray
	return @{$self->{_cookie_values}->{$key}} if wantarray;

	# return undef if nothing there
	return undef unless defined $self->{_cookie_values}->{$key};

	# We want a scalar
	if( scalar(@{$self->{_cookie_values}->{$key}}) > 1 ) {
		# Return an arrayref
		return $self->{_cookie_values}->{$key};
	}

	# Return the single value
	return $self->{_cookie_values}->{$key}->[0];
}

=head2 get_Get

 Title   : get_Get
 Usage   : my $get = $cgi->get_Get( $name )
 Function: 
 Returns : a get argument
 Args    : the name of the argument to return

 If $name is undef, then this returns the names of
 all get arguments.

=cut

sub get_Get
{
	my($self, $key) = @_;

	# Return the keys if no key specified
	return keys(%{$self->{_get_values}}) unless $key;
	
	# Return the array if wantarray
	return @{$self->{_get_values}->{$key}} if wantarray and ref($self->{_get_values}->{$key}) eq 'ARRAY';

	# return undef if nothing there
	return undef unless defined $self->{_get_values}->{$key};

	# We want a scalar
	if( scalar(@{$self->{_get_values}->{$key}}) > 1 ) {
		# Return an arrayref
		return $self->{_get_values}->{$key};
	}

	# Return the single value
	return $self->{_get_values}->{$key}->[0];
}

=head2 get_Post

 Title   : get_Post
 Usage   : my $post = $cgi->get_Post( $name )
 Function: 
 Returns : a post argument
 Args    : the name of the post argument to return

 If $name is undef, then this returns the names of
 all post arguments.

=cut

sub get_Post
{
	my($self, $key) = @_;

	# Return the keys if no key specified
	return keys(%{$self->{_post_values}}) unless $key;
	
	# Return the array if wantarray
	return @{$self->{_post_values}->{$key}} if wantarray and ref $self->{_post_values}->{$key} eq 'ARRAY';

	# return undef if nothing there
	return undef unless defined $self->{_post_values}->{$key};

	# We want a scalar
	if( scalar(@{$self->{_post_values}->{$key}}) > 1 ) {
		# Return an arrayref
		return $self->{_post_values}->{$key};
	}

	# Return the single value
	return $self->{_post_values}->{$key}->[0];
}

=head2 get_Request

 Title   : get_Request
 Usage   : my $request = $cgi->get_Request( $name )
 Function: 
 Returns : a request argument
 Args    : the name of the request argument to return

 If $name is undef, then this returns the names of
 all request arguments, removing duplicated names.

=cut

sub get_Request
{
	my($self, $key) = @_;

	my %seen;

	# If there is no key, join both get and post keys,
	# removing duplicates.
	return grep { defined($_) && !$seen{$_}++ } ( $self->get_Post(), $self->get_Get() ) unless $key;

	# Return values from both, if there defined, and join them
	return grep { defined($_) } (($self->get_Get($key)), ($self->get_Post($key))) if wantarray;

	# Return Posts or Gets
	return $self->get_Post($key) || $self->get_Get($key);
}

=head2 _parse_argv

 Title   : _parse_argv
 Usage   : Internal Function
 Function: Parse command-line options, pretending their GETs
 Returns : 
 Args    : 

 This parses command line options in the standard long form and
 adds them as if they were passed by GET.

=cut

sub _parse_argv()
{
	my ($self) = @_;
	while(@ARGV && (my ($arg, $val) = ($ARGV[0] =~ /^-{1,2}(\w+)(?:=(\w*)|$)/o))) {
		shift @ARGV;
		$val = shift @ARGV unless $val;
		next unless defined($arg) and defined($val) and defined($self->{get}->{$arg});
		$self->_parse_value('get', $arg, $val);
	}	
}

=head2 _parse_cookie

 Title   : _parse_cookie
 Usage   : Internal Function
 Function: Parse cookies
 Returns : 
 Args    : 

=cut

sub _parse_cookie
{
	my ($self) = @_;
	# Map the "; " into "&" so we can just use _parse_string
	$ENV{HTTP_COOKIE} =~ s/; /&/go;
	$self->_parse_string('cookie', $ENV{HTTP_COOKIE});
}

=head2 _parse_get

 Title   : _parse_get
 Usage   : Internal Function
 Function: Parse GET
 Returns : 
 Args    : 

=cut

sub _parse_get
{
	my($self) = @_;
	# Change the + to spaces
	$ENV{QUERY_STRING} =~ tr/+/ /;
	$self->_parse_string('get', $ENV{QUERY_STRING});
}

=head2 _parse_post

 Title   : _parse_post
 Usage   : Internal Function
 Function: Parse POST
 Returns : 
 Args    : 

=cut

sub _parse_post
{
	my($self) = @_;
	my $string;
	read(STDIN, $string, $ENV{'CONTENT_LENGTH'});
	$self->_parse_string('post', $string);
}

=head2 _parse_string

 Title   : _parse_string
 Usage   : Internal Function
 Function: Parse cookie, GET, and POST strings.
 Returns : 
 Args    : 

 Since they are all in the same format, we just use this function
 to parse all options.

=cut

sub _parse_string
{
	my ($self, $method, $string) = @_;

	# Split into pair values
	my @array = split(/&/, $string);

	foreach (@array) {
		# Accespt a word on oneside, and anything on the other
		my($arg, $val) = (/(\w+)=(.*)/o);

		# Decode
		s/\+/ /g foreach ($arg, $val);
		s/%(..)/pack("c",hex($1))/ge foreach ($arg, $val);

		# Make sure we have a name and a value
		next unless defined($arg) and defined($val);

		# Validate it
		$self->_validate_value(lc($method), $arg, $val);
	}
}

=head2 _validate_value

 Title   : _validate_value
 Usage   : Internal Function
 Function: Try to match the value against the rules
 Returns : 
 Args    : 

=cut

sub _validate_value
{
	my($self, $type, $arg, $val) = @_;
	my @ret;

	# Try the method passed first
	@ret = $self->_validate_match($self->{"_$type\_rules"}->{ $arg }, $arg, $val)
		if exists $self->{"_$type\_rules"}->{ $arg };

	# If there are no matches and the type is get or post, try the
	# request:
	@ret = $self->_validate_match($self->{'_request_rules'}->{ $arg }, $arg, $val)
		if exists $self->{'_request_rules'}->{ $arg } &&
		   scalar(@ret) == 0 && ( $type eq "get" || $type eq "post" );

	if(scalar(@ret) <= 0) {
		# Nothing matched, so add an error.
		$self->add_Error("Invalid value: $arg");
	} else {
		# Now add it to the values
		push(@{$self->{"_$type\_values"}->{ $arg }}, @ret);
	}
}

=head2 _validate_match

 Title   : _validate_match
 Usage   : Internal Function
 Function: Try to match the value against the rules
 Returns : 
 Args    : 

=cut

sub _validate_match
{
	my($self, $ref, $arg, $val) = @_;

	# Figure out what kind of rule it is.
	if( ref($ref) eq 'CODE' ) {
		# Its code, run it and return the results
		return $ref->($arg, $val);
	} elsif( ref($ref) eq 'ARRAY' ) {
		# Recures on each value
		foreach my $rule (@$ref) {
			my @rv = $self->_validate_value($rule, $arg, $val);
			return @rv if scalar(@rv) > 0;
		}
	} elsif(ref($ref) eq 'SCALAR') {
		# Somehow we got a reference to a scalar... strange.
		my (@rv) = ( $val =~ /$$ref/g );
		return @rv;
	} elsif(ref(\$ref) eq 'SCALAR') {
		my (@rv) = ( $val =~ /$ref/g );
		return @rv;
	}

	return ();
}

=head2 start_Session

 Title   : start_Session
 Usage   : $cgi->start_Session()
 Function: Initialize a session or open an existing one
 Returns : 
 Args    : 

=cut

sub start_Session
{
	my($self) = @_;
	my $id;

	# the id is usually saved as a cookie
	$id = $self->get_Cookie('_session_id');

	# If we couldn't get that, we use the get
	# Not post, since that requires a form its basically
	# useless
	$id = $self->get_Get('_session_id') unless $id;
	
	try {
		# Try to open up the possibly existing one
		tie %{$self->{_session}}, 'Apache::Session::File', $id, {
			Directory  => '/srv/web/Cellwall/session',
			LockDirectory => '/srv/web/Cellwall/lock',
		};
	} otherwise {
		# Catch all errors, and try to create a new one.
		tie %{$self->{_session}}, 'Apache::Session::File', undef, {
			Directory  => '/srv/web/Cellwall/session',
			LockDirectory => '/srv/web/Cellwall/lock',
		};
	};

	# Add the session cookie.
	$self->add_Cookie('_session_id', $self->get_Session('_session_id'));
}

=head2 get_Session

 Title   : get_Session
 Usage   : $ref = $cgi->get_Session($key)
 Function: Retrieve a value from the session store
 Returns : 
 Args    : The key to retrieve

 If $key is undef, this returns the non-internal keys.

=cut

sub get_Session
{
	my($self, $key) = @_;
	return grep { ! /^_/o } (keys(%{$self->{_session}})) unless defined $key;
	return $self->{_session}->{$key};
}

=head2 set_Session

 Title   : set_Session
 Usage   : $cgi->set_Session($key, $scalar)
 Function: Save a value to the session store
 Returns : 
 Args    : The key to save and a scalar to save.

=cut

sub set_Session
{
	my($self, $key, $value) = @_;
	$self->{_session}->{$key} = $value;
	return $self->{_session}->{$key};
}

=head2 deleter_Session

 Title   : deleter_Session
 Usage   : $cgi->deleter_Session(qw/these worlds are the keys/)
 Function: Delete a key from the session
 Returns : 
 Args    : 

 This deletes a list of keys from the session. Keys begining with and
 underscore are silently ignored.

=cut

sub delete_Session
{
	my($self) = @_;
	delete($self->{_session}->{$_}) foreach grep { $_ !~ /^_/o } @_;
}


=head2 clear_Session

 Title   : clear_Session
 Usage   : $cgi->clear_Session()
 Function: Clear the session data
 Returns : 
 Args    : 

 This deletes everything in the session minus those keys that start
 with an underscore.

=cut

sub clear_Session
{
	my($self) = @_;
	delete($self->{_session}->{$_}) foreach grep { $_ !~ /^_/o } keys %{$self->{_session}};
}

=head1 HTML Functions

=head2 title

 Title   : title
 Usage   : $title = $cgi->title( [$new] )
 Function: Get/Set the title of the page
 Returns : The [new] title
 Args    : an optional new value

=cut

=head2 set_Title

 Title   : set_Title
 Usage   : $cgi->set_Title( $title )
 Function: Set the title of the page
 Returns : 
 Args    : the new title

 If $title is undef (or not present) the title will be
 set to undef.

=cut

sub get_Title
{
	my($self) = @_;
	return $self->{__title};
}

sub set_Title
{
	my($self, $arg) = @_;
	$self->{__title} = $arg if @_ == 2;
	return $self->{__title};
}

=head2 sub_title

 Title   : sub_title
 Usage   : $sub_title = $cgi->sub_title( [$new] )
 Function: Get/Set the sub_title of the page
 Returns : The [new] sub_title
 Args    : an optional new value

=cut

sub sub_title
{
	my($self, $sub_title) = @_;
	$self->{_sub_title} = $sub_title if @_ == 2;
	return $self->{_sub_title};
}


=head2 set_SubTitle

 Title   : set_SubTitle
 Usage   : $cgi->set_SubTitle( $sub )
 Function: Set the sub title of the page
 Returns : 
 Args    : the new title

 If $sub is undef (or not present) the sub title will be
 set to undef.

=cut

sub set_SubTitle
{
	sub_title(@_);
}

=head2 add_Meta

 Title   : add_Meta
 Usage   : $cgi->add_Meta( ... )
 Function: add a meta tag to the page
 Returns : 
 Args    : the new meta tag

 The argument is a hash of attributed for the tag. Since the
 hash is never actually put into a hash, multiple attributes are
 allowed. The Http-Equiv attribute can be renamed into equiv for
 convinience.

=cut

sub add_Meta
{
	my $self = shift @_;
	my %meta;

	# Process each attribute
	while(my $attr = shift @_) {
		next unless ($attr) = ($attr =~ /^-(\S+)$/o);

		# Allow equiv => ... rather than 'Http-Equiv' => ...
		if($attr eq 'equiv') {
			$meta{'Http-Equiv'} = shift @_;
		} else {
			$meta{ $attr } = shift @_;
		}
	}

	# Add the meta hash to the list
	push( @{$self->{_meta}}, \%meta );
}

=head2 get_Meta

 Title   : get_Meta
 Usage   : @meta = $cgi->get_Meta();
 Function: get the Meta definitions
 Returns : An array of hashref's
 Args    :

=cut

sub get_Meta
{
	my($self) = @_;
	return wantarray ? @{$self->{_meta}} : $self->{_meta} if defined $self->{_meta} and ref($self->{_meta}) eq 'ARRAY';
	return wantarray ? () : [];
}

=head2 add_CSS

 Title   : add_CSS
 Usage   : $cgi->add_CSS( ... )
 Function: add an entrie to the CSS section of the page
 Returns : 
 Args    : the CSS line to add

 Properties for the CSS section are the names of allowed
 CSS properties preceeded with a hyphen, with internal
 hyphens replaced with underscores. The ones currently
 in use are:

 -name:  The tag name to apply to, in CSS notation such that
         -name => 'a.new' would apply to <a class="new" ...>

 -font_color: The font color of the tag.
 -font_size:  The font size
 -background_color: The background color of the tag.

=cut

sub add_CSS
{
	my($self, %args) = @_;

	# Make sure it has a name
	throw Error::Simple('CSS definition needs a name') unless defined $args{-name};

	# Translate the tag names
	my %css;
	foreach my $key (keys(%args)) {
		my $newkey = $key;
		$newkey =~ tr/_-/-/d;
		$css{$newkey} = $args{$key};
	}

	# Append it to the array
	push( @{ $self->{_css} }, \%css );
}

=head2 get_CSS

 Title   : get_CSS
 Usage   : @css = $cgi->get_CSS();
 Function: get the CSS definitions
 Returns : An array of hashref's
 Args    :

=cut

sub get_CSS
{
	my($self) = @_;
	return wantarray ? @{$self->{_css}} : $self->{_css};
}

=head2 mime

 Title   : mime
 Usage   : $mime = $cgi->mime([$newmime]);
 Function: Get or Set the MIME-Type value
 Returns : A scalar
 Args    : an optional value for the mime type

=cut

sub mime
{
	my($self, $mime) = @_;
	$self->{_mime} = $mime if @_ == 2;
	return $self->{_mime};
}

1;
