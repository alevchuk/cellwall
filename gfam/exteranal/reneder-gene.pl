# vim:sw=4 ts=4
# $Id: CGI.pm 2 2004-04-01 23:09:24Z laurichj $

=author
Aleksandr Levchuk alevchuk@gmail.com

=Last Major Modification
2010 Jun 28

= Original Version Written by
Josh Lauricha laurichj@bioinfo.ucr.edu

=cut

use Bio::SeqFeature::Generic;
use Bio::Graphics;
use Error;
use strict;



sub build_SeqView
{
	my($self) = @_;


	# Input: seq, exons, cds, left_utr, right_utr, extended_utr
        my %seq = (
		length => 1388,
		accession_number => 'At4g19720',
		description => 'glycosyl hydrolase family 18 protein',
	);


	my %models = (
		'68417.m02896' => 
		Bio::SeqFeature::Generic->new(-start=>56, -end=>1388),
	);

        my $s = Bio::Location::Split->new;
        $s->add_sub_Location(Bio::Location::Simple->new(-start => 1,
							-end   => 713,
        						-strand => 1));

        $s->add_sub_Location(Bio::Location::Simple->new(-start => 955,
							-end   => 1388,
        						-strand => 1));
	my %exons = ('68417.m02896' => $s);


        $s = Bio::Location::Split->new;
        $s->add_sub_Location(Bio::Location::Simple->new(-start => 56,
							-end   => 713,
        						-strand => 1));

        $s->add_sub_Location(Bio::Location::Simple->new(-start => 955,
							-end   => 1388,
        						-strand => 1));
	my %cds = ('68417.m02896' => $s);


        $s = Bio::Location::Split->new;
        $s->add_sub_Location(Bio::Location::Simple->new(-start => 1,
							-end   => 55,
							-strand => 1
        						));
	my %utrs = (
	  '68417.m02896' => $s,
	);




	# Create a new panel
	my $panel = new Bio::Graphics::Panel(
		-length     => %seq->{'length'},
		-key_style  => 'between',
		-width      => 600,
		-pad_top    => 5,
		-pad_left   => 10,
		-pad_right  => 10,
		-pad_bottom => 5,
		-bgcolor    => 'white',
	);


	# A feature to span the sequence
	my $entire = new Bio::SeqFeature::Generic(
		-start   => 1,
		-end     => %seq->{'length'},
		-seq_id  => %seq->{'accession_number'},
	);

	# Add the ruler
	$panel->add_track(
		$entire,
		-glyph  => 'arrow',
		-bump   => 0,
		-dobule => 1,
		-tick   => 2,
	);

	# Add the sequence track
	$panel->add_track(
		$entire,
		-glypy       => 'generic',
		-bgcolor     => 'blue',
		-font2color  => 'black',
		-label       => %seq->{'accession_number'},
		-description => %seq->{'description'},

		-height      => 12
	);


	# add tracks for each of the models
	foreach my $feature_name (sort(keys(%models))) {
		$panel->add_track(
                        %models->{$feature_name},
			-glyph => 'generic',
			-bgcolor => 'lightblue',
			-fgcolor => 'black',
			-font2color => 'black',
			-key => 'MODEL',
			-label => $feature_name,
			-bump => +1,
			-height => 12
		);

		# Handle the EXONs first
		if(defined(%exons->{$feature_name})) {
			$panel->add_track(
				Bio::SeqFeature::Generic->new(
                                        -location=>%exons->{$feature_name}),
				-glyph => 'generic',
				-bgcolor => 'cyan',
				-fgcolor => 'black',
				-font2color => 'black',
				-key => 'EXON',
				-bump => +1,
				-height => 12
			);
		}

		# Handle the CDS second
		if(defined(%cds->{$feature_name})) {
			$panel->add_track(
				Bio::SeqFeature::Generic->new(
					-location=>%cds->{$feature_name}),
				-glyph => 'transcript2',
				-bgcolor => 'orange',
				-fgcolor => 'black',
				-font2color => 'black',
				-key => 'CDS',
				-bump => +1,
				-height => 12
			);
		}

		# UTRs last
		if(defined(%utrs->{$feature_name})) {

                        # Create a feature for the UTRs
                        my $feat = new Bio::SeqFeature::Generic(
                                -primary  => 'UTRs',
                                -location => %utrs->{$feature_name}
                        );

                        # Add the UTRs to the panel
                        $panel->add_track(
                                $feat,
                                -glyph      => 'generic',
                                -bgcolor    => 'lime',
                                -fgcolor    => 'black',
                                -font2color => 'black',
                                -key        => 'UTRs',
                                -bump       => +1,
                                -height     => 12
                        );

		}
	}

	return $panel;
}

sub render_SeqView
{
	my($self) = @_;

	# Make the panel
	my $panel = build_SeqView();

	# Make the background transparent
	$panel->gd()->transparent($panel->bgcolor());


	# Print the image out
	print $panel->png();

	# Make sure nothing else is printed
	exit(0);
}




render_SeqView();
