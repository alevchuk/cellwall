#!/usr/bin/perl
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


use DBI;
use strict;


# DB connect
my $dbh = DBI->connect("DBI:Pg:dbname=cellwall;host=cellwalldb",
        "cellwallweb", "uXmn]h0r", {'RaiseError' => 1});
                     

sub build_SeqView
{
	my($self) = @_;

	my $accession = "At4g19720";

	my $sth;
	my $srow;


	# Lookup sequence id, length, description
        my $fromdb_sequence_id;
        my $fromdb_sequence_length;
        my $fromdb_sequence_descrip;

	$sth = $dbh->prepare(
	  "SELECT * FROM cellwall1.sequence WHERE accession = ?"
	);
	$sth->execute($accession);
        if ($srow = $sth->fetchrow_hashref())
	{
		$fromdb_sequence_id      = $srow->{'id'};
		$fromdb_sequence_length  = $srow->{'length'};
		$fromdb_sequence_descrip = $srow->{'description'};
	}
	else
	{
		die "ERROR: Accession ${accession} not found in database";
	};


	# Lookup all feature_id's in seqfeature (a hash of arrays)
	my %fromdb_features;

	$sth = $dbh->prepare(
	  "SELECT * FROM cellwall1.seqfeature WHERE sequence = ?"
	);
	$sth->execute($fromdb_sequence_id);
	my $tag, my $id;
	while(my $ref = $sth->fetchrow_hashref()) {
		$tag = $ref->{'primary_tag'};
		$id =  $ref->{'id'};
		$fromdb_features{$tag} = [ ] unless 
		  exists $fromdb_features{$tag};
		push @{ $fromdb_features{$tag} }, $id;
	}
        if ($sth->rows == 0)
	{
		die "ERROR: Sequence_id ${fromdb_sequence_id} " .
		  "not found in database";
	};
	#print join(", ", sort @{ $fromdb_features{'MODEL'} }), "\n";
	#print @{ $fromdb_features{'MODEL'} }[0], "\n";
	#exit();


	# Lookup all locations (start, end, strand) by feature_id
	# hash of arrays (triplets) with key being the feature_id

	my %fromdb_locations;

	$sth = $dbh->prepare(
	  "SELECT * FROM cellwall1.seqlocation WHERE seqfeature = ?"
	);
	my $start, my $stop, my $strand;
	for my $primary_tag ( keys %fromdb_features ) {
		for my $feature_id ( @{ $fromdb_features{$primary_tag} } ) {
			$sth->execute($feature_id);
			while(my $ref = $sth->fetchrow_hashref()) {
				$start  = $ref->{'start_pos'};
				$stop   = $ref->{'end_pos'};
				$strand = $ref->{'strand'};

				$fromdb_locations{$feature_id} = [ ] unless 
				  exists $fromdb_locations{$feature_id};
				push @{ $fromdb_locations{$feature_id} },
				  [ $start, $stop, $strand ];
				  
			}
        		if ($sth->rows == 0)
			{
				die "ERROR: seqfeature $feature_id " .
				  "not found in database";
			};
		}
	}



	# Create BioPerl data structures
	# Input: seq, features(models, exons, cds, utrs left/right/extended)

        my %seq = (
		accession_number => $accession,
		length           => $fromdb_sequence_length,
		description      => $fromdb_sequence_descrip,
	);

	# MODELs
	my %models; # TODO: Support >1 model
	my $feature_id = @{ $fromdb_features{'MODEL'} }[0]; 

	# TODO: error if size != 1
	my $loc = @{$fromdb_locations{$feature_id}}[0];
	%models = (
		'68417.m02896' => 
		Bio::SeqFeature::Generic->new(
		  -start  => @{$loc}[0],
		  -end    => @{$loc}[1],
		  -strand => @{$loc}[2],
		),
	);


	# EXONs
	my %exons;
        my $s = Bio::Location::Split->new;

	my $feature_id  = @{$fromdb_features{'EXON'}}[0];
	my $locs = $fromdb_locations{$feature_id};
	for $loc (@{$locs}) {
        	$s->add_sub_Location(Bio::Location::Simple->new(
			  -start  => @{$loc}[0],
			  -end    => @{$loc}[1],
			  -strand => @{$loc}[2],
        							)
		);
	}
	%exons = ('68417.m02896' => $s) if @{$locs} > 0;


	# CDS
	my %cds;
	my $s;
        $s = Bio::Location::Split->new;
	my $feature_id  = @{$fromdb_features{'CDS'}}[0];
	
	my $locs = $fromdb_locations{$feature_id};
	for $loc (@{$locs}) {
        	$s->add_sub_Location(Bio::Location::Simple->new(
                          -start  => @{$loc}[0],
                          -end    => @{$loc}[1],
                          -strand => @{$loc}[2],
        							));
	}
	%cds = ('68417.m02896' => $s) if @{$locs} > 0;


	# UTRs
	my %utrs;
	my @utr_features;
	push(@utr_features, @{$fromdb_features{'LEFT_UTR'}}) if
		exists $fromdb_features{'LEFT_UTR'};
	push(@utr_features, @{$fromdb_features{'RIGHT_UTR'}}) if
		exists $fromdb_features{'RIGHT_UTR'};
	push(@utr_features, @{$fromdb_features{'EXTENDED_UTR'}}) if
		exists $fromdb_features{'EXTENDED_UTR'};

        $s = Bio::Location::Split->new;

	my $feature_id  = @utr_features[0];
	my $locs = $fromdb_locations{$feature_id};
	for $loc (@{$locs})
	{	
        	$s->add_sub_Location(Bio::Location::Simple->new(
                          -start  => @{$loc}[0],
                          -end    => @{$loc}[1],
                          -strand => @{$loc}[2],
        							));
	}
	%utrs = ('68417.m02896' => $s) if @{$locs} > 0;



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



# DB clean up
$dbh->disconnect();

