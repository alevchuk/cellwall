# vim:sw=4 ts=4
# $Id: Sequence.pm 103 2005-02-11 05:22:22Z laurichj $

=head1 NAME

Cellwall::Executor::pvm

=head1 DESCRIPTION

Cellwall::Executor::pvm uses PVM to distribute the load over multiple machines

=head1 FEEDBACK

Josh Lauricha laurichj@bioinfo.ucr.edu

=head1 APPENDIX

The rest of the documentaton details each of the object methods.
Internal methods are designated with an initial _

=cut

package Cellwall::Executor::pvm;
use base qw/Cellwall::Executor/;
use Error qw/:try/;
use Cellwall::SQL;
use Cellwall::Root;
use Parallel::Pvm;
use vars qw/@ISA @ACCESSORS/;
use strict;

#@ACCESSORS = qw/type/;
#Cellwall::Executor::pvm->mk_accessors(@ACCESSORS);

=head2 new

 Title   : new
 Usage   : $exec = new Cellwall::Executor::pvm(...)
 Function: Create an pvm executor object
 Returns : a Cellwall::Executor::pvm object
 Args    :

 Don't call directly, use Cellwall::Executor

=cut

sub new
{
	my $self = Cellwall::Root::new(@_);
	return $self;
}

# PVM Constants
my $PVM_MSG_WAITING =   1;
my $PVM_MSG_UNIT    =   2;
my $PVM_MSG_ERROR   = 999;

=head2 slave

 Title   : slave
 Usage   : $cw->slave();
 Function: Act as a PVM Slave
 Returns : 
 Args    : The Parent's TID

=cut

sub slave
{
	my($self, $parent) = @_;

	# Enroll into PVM
	my $mytid = Parallel::Pvm::mytid();

	Parallel::Pvm::catchout();
	Parallel::Pvm::catchout(\*STDERR);

	print STDERR "SLAVE running on " . `uname -n`;

	# Make things wait for sync
	$Cellwall::parallel = 1;

	# Send the job
	Parallel::Pvm::initsend();
	Parallel::Pvm::pack('Hi');
	Parallel::Pvm::send($parent, $PVM_MSG_WAITING);

	print STDERR "SLAVE waiting\n";

	while(1) {
		my $bufid = Parallel::Pvm::recv(-1,-1);
		print STDERR "SLAVE recved msg $bufid\n";

		# Unpack the buffer
		my($info, $bytes, $tag, $tid) = Parallel::Pvm::bufinfo($bufid);
		print STDERR "SLAVE recved msg $bytes $tag from $tid\n";

		# Figure out what we are to do
		my($search, $level, $target) = Parallel::Pvm::unpack();
		print STDERR "SLAVE Running job: $search $level $target\n";

		# figure out the real target:
		if( $level eq 'family' ) {
			$target = $Cellwall::singleton->get_Family( id => $target );
		} elsif( $level eq 'sequence' ) {
			$target = $Cellwall::singleton->get_Sequence( id => $target );
		}

		# Get the search
		$search = $Cellwall::singleton->get_Search( id => $search );

		# Run it
		if( $level eq 'family' ) {
			$search->search_Family( $target );
		} elsif( $level eq 'sequence' ) {
			print STDERR "SLAVE sequence: ", $target->accession_number(), "\n";
			$search->search_Sequence( $target );
		}
		print STDERR "SLAVE finished.\n";
		
		Parallel::Pvm::initsend();
		Parallel::Pvm::pack('Hi');
		Parallel::Pvm::send($parent, $PVM_MSG_WAITING);
	}

	print STDERR "SLAVE Exiting.\n";
}

=head2 execute

 Title   : execute
 Usage   : $cw->execute();
 Function: Run all applicable searches
 Returns : 
 Args    : The number of processors to use

=cut

sub execute
{
	my($self, $np) = @_;
	my $client = "/home/laurichj/work/cellwall/cellwall";

	# Make things wait for sync
	$Cellwall::parallel = 1;

	# Enroll into PVM
	my $mytid = Parallel::Pvm::mytid();

	Parallel::Pvm::catchout();
	Parallel::Pvm::catchout(\*STDERR);

	# Start the slaves
	my( $ntask, @tids ) = Parallel::Pvm::spawn($client, $np,
	                                           Parallel::Pvm::PvmTaskArch,
	                                           "LINUX",
											   [ 
											   '-H', $Cellwall::singleton->host(),
											   '-d', $Cellwall::singleton->db(),
											   '-u', $Cellwall::singleton->user(),
											   '-p', $Cellwall::singleton->password(),
											   '-b', $Cellwall::singleton->base(),
											   "slave", "pvm", $mytid ]);

	print STDERR "MASTER checking tids...";
	# Check the error status
	foreach my $tid (@tids) {
		if( $tid < 0 ) {
			if ( $tid == Parallel::Pvm::PvmNoMem ) {
				warn "no memory!\n";
			} elsif ( $tid == Parallel::Pvm::PvmSysErr ) {
				warn "pvmd not responding!\n";
			}
		}
	}
	print STDERR "done.\n";

	# Strip out any TIDs that failed to start
	@tids = grep { $_ >= 0 } @tids;
	print STDERR "MASTER ", scalar(@tids), " processes running\n";

	# Create the status hash
	%{$self->{__pvm_status}} = map { $_ => 'starting' } @tids;
	
	# Get the families and proteins
	my %seen;
	my @families = $Cellwall::singleton->get_all_Families();
	my @proteins = grep { !$seen{ $_->primary_id() }++ } $Cellwall::singleton->get_all_Proteins();

	# Run all the searches
	foreach my $search ($Cellwall::singleton->get_all_Searches()) {
		print STDERR "MASTER running a search\n";
		if( $search->query() eq 'family' ) {
			foreach my $family (@families) {
				$self->pvm_Run($search->id(), 'family', $family->id());
			}
		} elsif( $search->query() eq 'protein' ) {
			foreach my $seq (@proteins) {
				$self->pvm_Run($search->id(), 'sequence', $seq->primary_id()); 
			}
		}
	}
}

=head2 pvm_Run

 Title   : pvm_Run
 Usage   : $cw->pvm_Run();
 Function: Run a given search
 Returns : 
 Args    : The search id, the level the search operates on and the
           target.

=cut

sub pvm_Run
{
	my($self, $search, $level, $target) = @_;

	# Figure out which TID to use:
	print STDERR "MASTER waiting for a tid\n";
	my $tid = $self->pvm_WaitTid();

	print STDERR "MASTER telling $tid to run it...\n";
	# Send the job
	Parallel::Pvm::initsend();
	Parallel::Pvm::pack($search, $level, $target);
	Parallel::Pvm::send($tid, $PVM_MSG_UNIT);
	print STDERR "MASTER done.\n";

	$self->{__pvm_status}->{$tid} = 'working';
}

=head2 pvm_WaitTid

 Title   : pvm_WaitTid
 Usage   : $cw->pvm_WaitTid();
 Function: Wait for a free slave
 Returns : 
 Args    : 

=cut

sub pvm_WaitTid
{
	my($self) = @_;

	my($tid) = grep {
		$self->{__pvm_status}->{$_} eq 'open'
	} keys( %{ $self->{__pvm_status} } );

	while( not defined $tid ) {
		# Listen for a message
		$self->pvm_Listen();
		
		($tid) = grep {
			$self->{__pvm_status}->{$_} eq 'open'
		} keys( %{ $self->{__pvm_status} } );
	}

	print STDERR "got tid: $tid\n";
	return $tid;
}

=head2 pvm_Listen

 Title   : pvm_Listen
 Usage   : $cw->pvm_Listen();
 Function: Listen for a PVM message and act on it
 Returns : 
 Args    : 

=cut

sub pvm_Listen
{
	my($self) = @_;

	# Get a message
	my $bufid = Parallel::Pvm::recv();
	print STDERR "MASTER got msg $bufid\n";
	#until( $bufid = Parallel::Pvm::probe(-1,-1) ) { sleep .25; }

	# Unpack the buffer
	my($info, $bytes, $tag, $tid) = Parallel::Pvm::bufinfo($bufid);
	print STDERR "MASTER msg $bytes $tag from $tid\n";
	
	if( $tag == $PVM_MSG_WAITING ) {
		# Set the slave to waiting
		print STDERR "MASTER $tid now open\n";
		$self->{__pvm_status}->{$tid} = 'open';
		$self->debug(2, "PVM Slave($tid) waiting");
	} elsif( $tag == $PVM_MSG_ERROR ) {
		# There was an error with the slave
		$self->{__pvm_status}->{$tid} = 'dead';
		my($error) = Parallel::Pvm::unpack();
		$self->debug(2, "PVM Slave($tid) errored: $error");
	} else {
		$self->debug(2, "PVM Slave($tid) send unknown message: $tag, $info, $bytes")
	}
}

