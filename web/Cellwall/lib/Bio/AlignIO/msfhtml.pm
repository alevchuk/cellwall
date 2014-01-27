# BioPerl module for Bio::AlignIO::msfhtml

#	based on the Bio::SeqIO::msf module
#       by Peter Schattner
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=head1 NAME

Bio::AlignIO::msfhtml - msf colored sequence output stream

=head1 SYNOPSIS

Do not use this module directly.  Use it via the L<Bio::AlignIO> class.

=head1 DESCRIPTION

This object can transform L<Bio::Align::AlignI> objects to colored msf flat
files.

=head1 FEEDBACK

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
 the bugs and their resolution.
 Bug reports can be submitted via email or the web:

  bioperl-bugs@bio.perl.org
  http://bugzilla.bioperl.org/

=head1 AUTHORS - Josh Lauricha

Email: laurichj@bioinfo.ucr.edu


=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::AlignIO::msfhtml;
use vars qw(@ISA %valid_type);
use strict;

use Bio::AlignIO;
use Bio::SeqIO::gcg; # for GCG_checksum()
use Bio::SimpleAlign;
use Data::Dumper;

@ISA = qw(Bio::AlignIO);

BEGIN {
    %valid_type = qw( dna N rna N protein P );
}

my $cols = 15;


sub _initialize
{
	my ($self, @args) = @_;
	$self->SUPER::_initialize(@args);

	my %params = @args;

	$self->{stylesheet} = $params{-stylesheet};
	
	$self->_print(join("\n",
			'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"',
			' "http://www.w3.org/TR/html401">',
			'<html><head>',
			'<title>MSF Html Output</title>',
			( defined $self->{stylesheet} ? (
				'<link rel="stylesheet" type="text/css" href="/style.css"/>'
			) : (
				'<style type="text/css">',
				'    body { color: black; background-color: white; font-size: 80%; font-family: FreeMono, monospace; }',
				'    .header, .members, .alignment  { width: 80em; }',
				'    .name      { padding-right: 1em; text-align: left; }',
				'    .header th { text-align: center; }',
				'    .header th.title { text-align: left; }',
				'    .header th.date  { text-align: right; }',
				'    .header .title:before { content: "MSF: "; }',
				'    .header .count:before { content: "Count: "; }',
				'    .header .date:before { content: "Date: "; }',
				'    .members   { margin-bottom: 1em; }',
				'    .members .name:before { content: "Name: "; }',
				'    .members .length:before { content: "Len: "; }',
				'    .members .check:before { content: "Check: "; }',
				'    .members .name   { text-align: left; }',
				'    .members .length { text-align: center; }',
				'    .members .check  { text-align: right; }',
				'    .alignment { white-space: pre; }',
				'    .alignment em { font-style: normal; }',
				'    .alignment tr.segment { text-align: left; vertical-align: bottom; height: 2em; }',
				'    em.ten     { background-color: #5555ff; }',
				'    em.twenty  { background-color: #00ff00; }',
				'    em.thirty  { background-color: #66ff00; }',
				'    em.forty   { background-color: #ccff00; }',
				'    em.fifty   { background-color: #ffff00; }',
				'    em.sixty   { background-color: #ffcc00; }',
				'    em.seventy { background-color: #ff9900; }',
				'    em.eighty  { background-color: #ff6600; }',
				'    em.ninety  { background-color: #ff3300; }',
				'    em.perfect { background-color: #ff0000; }',
				'</style>',
			) ),
			'</head>',
			'<body>',
	));
}

=head2 write_aln

 Title   : write_aln
 Usage   : $stream->write_aln(@aln)
 Function: writes the $aln object into the stream in MSF format
           Sequence type of the alignment is determined by the first sequence.
 Returns : 1 for success and 0 for error
 Args    : L<Bio::Align::AlignI> object


=cut

sub write_aln {
    my ($self,@aln) = @_;

	# MSF likes dates:
	my $date = localtime(time);
	my $linelength = $self->{linelength};


	foreach my $aln (@aln) {
		my $aln_length = $aln->length();
		my @seqs = $aln->each_seq();
		my $numseqs = $aln->no_sequences();

		# We error on errors
		$self->throw(
			'Must provide a Bio::Align::AlignI object when calling write_aln'
		) unless defined $aln and $aln->isa('Bio::Align::AlignI');

		# Print the header
		$self->_print(
			join("\n",
				'<table class="header"><tr>',
				'<th class="title">' . $aln->id() || 'Align' . '</th>',
				'<th class="count">' . $numseqs . '</th>',
				'<th class="date">' . $date . '</th>',
				'</tr></table>'
		));
		
		# Print the members
		$self->_print('<table class="members">' . "\n");
		foreach my $seq (@seqs) {
			$self->_print(join("\n",
					'<tr>',
					"\t" . '<td class="name">'   . $aln->displayname($seq->get_nse()) . '</td>',
					"\t" . '<td class="length">' . $seq->length() . '</td>',
					"\t" . '<td class="check">'  . Bio::SeqIO::gcg->GCG_checksum($seq) . '</td>',
					'</tr>'
			));
		}
		$self->_print("</table>\n");

		# Calculate the classes
		# $count[offset]{base} = count
		my @count;
		foreach my $seq (@seqs) {
			my @chars = split(//, $seq->seq());
			for(my $i = 0; $i <= $#chars; $i++) {
				if(not exists $count[$i]{$chars[$i]}) {
					 $count[$i]{$chars[$i]} = 1;
				 } else {
					$count[$i]{$chars[$i]} =  $count[$i]{$chars[$i]} + 1;
				}
			}
		}

		# Traslate the raw count into percents, rounded down
		foreach my $char (@count) {
			$char = {map { $_ => int($char->{$_}/$numseqs * 10) * 10 } keys %$char };
		}

		# Calculate the classes
		my @classes = ( 0 .. $#count );
		my %percent_lookup = ( 10 => "ten", 20 => "twenty", 30 => "thiry",
		                       40 => "forty",  50 => "fifty",  60 => "sixty", 
		                       70 => "seventy", 80 => "eighty", 90 => "ninety",
		                      100 => "perfect", 0 => "zero" );

		# This will set the percent class
		for(my $i = 0; $i <= $#count; $i++) {
			$classes[$i] = { map {
					$_ => { $percent_lookup{int($count[$i]{$_})} => 1}
			} grep { $_ ne '-' } keys %{$count[$i]} };
		}

		# Chunk the sequences
		my $numlines = 0;
		my %lines = map {
			my(@b) = ($_->seq() =~ /(.{1,100})/go);
			$numlines = $#b if $#b > $numlines;
			$_->get_nse() => \@b;
		} (@seqs);

		# Print the actual sequences
		$self->_print('<table cellspacing="0" cellpadding="0" class="alignment">' . "\n");
		foreach my $index (0 .. $numlines) {
			$self->_print(sprintf('<tr class="segment"><th>%s-%s</th></tr>' . "\n", $index * 100 + 1, ($index + 1) * 100));
			foreach my $seq (@seqs) {
				my $i = $index * 100;
				my(@blocks) = ( $lines{$seq->get_nse()}->[$index] =~ /(.{1,10})/go);
				@blocks = map { join('', map {
							if( $_ eq '-' or $_ eq '.') {
								$_ = '-';
							} else {
								my $classstr = join(' ', keys(%{$classes[$i]{$_}}));
								if( $classstr ne '' ) {
									$_ = "<em class=\"$classstr\">$_</em>";
								}
							}
							$i += 1;
							$_;
				} (split(//, $_)) ) } @blocks;

				$self->_print(join("\n",
						'<tr><td class="name">' . $aln->displayname($seq->get_nse()) . '</td>',
						'<td class="sequence">' . join(" ", @blocks) . "</td></tr>\n",
				));
			}
		}
		$self->_print("</table>\n");
	}

    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

sub DESTROY
{
	my($self) = @_;
	$self->_print("</body></html>\n");
}

1;

