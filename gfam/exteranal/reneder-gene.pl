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

	#my $accession = "At4g19720";
	#my $accession = "LOC_Os01g66850";
	#my $accession = $ARGV[0];
	my $accession;
	my $id = $ARGV[0];

	my $sth;
	my $srow;


	# Lookup sequence id, length, description
        my $fromdb_sequence_id;
        my $fromdb_sequence_length;
        my $fromdb_sequence_descrip;

	$sth = $dbh->prepare(
		"SELECT * FROM cellwall1.sequence WHERE id = ?"
	);
	$sth->execute($id);
        if ($srow = $sth->fetchrow_hashref())
	{
		$fromdb_sequence_id      = $srow->{'id'};
		$accession               = $srow->{'accession'};
		$fromdb_sequence_length  = $srow->{'length'};
		$fromdb_sequence_descrip = $srow->{'description'};
	}
	else
	{
		die "ERROR: Sequence id ${id} not found in database";
	}


	# Lookup all feature_ids and names in seqtags (a hash of hashes)
	my %fromdb_tags;
	$sth = $dbh->prepare(
		"SELECT * FROM cellwall1.seqtags t, cellwall1.seqfeature f " .
		"WHERE t.feature = f.id AND f.sequence = ?"
	);

	my $key, my $value, my $feature_id;
	$sth->execute($fromdb_sequence_id);
	while(my $ref = $sth->fetchrow_hashref()) {
		$key   = $ref->{'name'};
		$value = $ref->{'value'};
		$feature_id = $ref->{'feature'};

		$fromdb_tags{$feature_id} = { } unless 
		  exists $fromdb_tags{$feature_id};
		%{ $fromdb_tags{$feature_id} }->{$key} = $value;
		  
	};
	if ($sth->rows == 0)
	{
		die "ERROR: seqfeature $feature_id " .
		  "not found in database";
	};
	# die %{$fromdb_tags{9642}}->{"model"}, "\n";


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
	#print join(", ", sort @{ $fromdb_features{'RIGHT_UTR'} }), "\n";
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




	# Lookup all feature_id's in seqfeature (a hash of hashes)
	# retreavable by "feat_name" tag
	my %fromdb_features_byname;

	$sth = $dbh->prepare(
		"SELECT * FROM cellwall1.seqfeature WHERE sequence = ?"
	);
	$sth->execute($fromdb_sequence_id);
	my $tag, my $id;
	while(my $ref = $sth->fetchrow_hashref()) {
		$tag = $ref->{'primary_tag'};
		$id =  $ref->{'id'};
		#print $id . "  ---> " . $tag . "\n";

		my $feat_name;
		if ($tag eq 'MODEL') {
			$feat_name = %{$fromdb_tags{$id}}->{'feat_name'};
		}
		else {
			$feat_name = %{$fromdb_tags{$id}}->{'model'};
		}


		if (!($feat_name))
		{ # if empty
			# Generate a random feat_name /nottagged[1-9,a-z]*/
			#   if $feat_name empty 
			$feat_name = $feat_name . "_nottagged" .
                        int(rand(1000));
		}

		# Generate a random feat_name suffix
		#   if $feat_name already in $fromdb_features_byname
		if (exists 
		  %{ $fromdb_features_byname{$feat_name}}->{$tag}) {
			$feat_name = $feat_name . "_notunique" .
			int(rand(1000));
		}

		$fromdb_features_byname{$feat_name} = { } unless 
		  exists $fromdb_features_byname{$feat_name};

		%{ $fromdb_features_byname{$feat_name} }->{$tag} = $id;
	
	}
        if ($sth->rows == 0)
	{
		die "ERROR: Sequence_id ${fromdb_sequence_id} " .
		  "not found in database";
	};
	#die join(", ", keys %{ $fromdb_features_byname{'MODEL'} }), "\n";
	#die join(", ", keys %{ $fromdb_features_byname{'RIGHT_UTR'} }), "\n";
	#die %{ $fromdb_features_byname{'RIGHT_UTR'}}->{'11667.m06719'}, "\n";


	
	# -------------------------------------------


	# Create BioPerl data structures
	# Input: seq, features(models, exons, cds, utrs left/right/extended)

        my %seq = (
		accession_number => $accession,
		length           => $fromdb_sequence_length,
		description      => $fromdb_sequence_descrip,
	);

	# MODELs
	my %models;
	my %exons;
	my %cds;
	my %utrs;

	my $loc, my $feature_id;
	for my $feat_name (keys %fromdb_features_byname) {

		#print "$feat_name\n";

		# TODO: error if size != 1
		$feature_id = 
		  %{%fromdb_features_byname->{$feat_name}}->{'MODEL'};

		$loc = @{$fromdb_locations{$feature_id}}[0]; # only 1 loc!
		if ($loc)
		{
		  %models->{$feat_name} =
		  	Bio::SeqFeature::Generic->new(
		  	  -start  => @{$loc}[0],
		  	  -end    => @{$loc}[1],
		  	  -strand => @{$loc}[2],
		  	);
		}

		my $s;

		# EXONs
	        $s = Bio::Location::Split->new;
	
		$feature_id = 
		  %{%fromdb_features_byname->{$feat_name}}->{'EXON'};
		my $locs = $fromdb_locations{$feature_id};
		for $loc (@{$locs}) {
	        	$s->add_sub_Location(Bio::Location::Simple->new(
				  -start  => @{$loc}[0],
				  -end    => @{$loc}[1],
				  -strand => @{$loc}[2],
	        							)
			);
		}
	
		%exons->{%{$fromdb_tags{$feature_id}}->{'model'}} = $s
		  if @{$locs} > 0;


		# CDS
        	$s = Bio::Location::Split->new;
		$feature_id = 
		  %{%fromdb_features_byname->{$feat_name}}->{'CDS'};

		my $locs = $fromdb_locations{$feature_id};
		for $loc (@{$locs}) {
        		$s->add_sub_Location(Bio::Location::Simple->new(
        	                  -start  => @{$loc}[0],
        	                  -end    => @{$loc}[1],
        	                  -strand => @{$loc}[2],
        								));
		}
		%cds->{%{$fromdb_tags{$feature_id}}->{'model'}} = $s
		  if @{$locs} > 0;


		# UTRs
        	$s = Bio::Location::Split->new;

		$feature_id =  # UTR is for future data adjustments
		  %{%fromdb_features_byname->{$feat_name}}->{'UTR'};
		my $locs0 = $fromdb_locations{$feature_id};
		for $loc (@{$locs0}) {
        		$s->add_sub_Location(Bio::Location::Simple->new(
        	                  -start  => @{$loc}[0],
        	                  -end    => @{$loc}[1],
        	                  -strand => @{$loc}[2],
        								));
		}

		$feature_id = 
		  %{%fromdb_features_byname->{$feat_name}}->{'LEFT_UTR'};
		my $locs1 = $fromdb_locations{$feature_id};
		for $loc (@{$locs1}) {
        		$s->add_sub_Location(Bio::Location::Simple->new(
        	                  -start  => @{$loc}[0],
        	                  -end    => @{$loc}[1],
        	                  -strand => @{$loc}[2],
        								));
		}

		$feature_id = 
		  %{%fromdb_features_byname->{$feat_name}}->{'RIGHT_UTR'};
		my $locs2 = $fromdb_locations{$feature_id};
		for $loc (@{$locs2}) {
        		$s->add_sub_Location(Bio::Location::Simple->new(
        	                  -start  => @{$loc}[0],
        	                  -end    => @{$loc}[1],
        	                  -strand => @{$loc}[2],
        								));
		}

		$feature_id = 
		  %{%fromdb_features_byname->{$feat_name}}->{'EXTENDED_UTR'};
		my $locs3 = $fromdb_locations{$feature_id};
		for $loc (@{$locs3}) {
        		$s->add_sub_Location(Bio::Location::Simple->new(
        	                  -start  => @{$loc}[0],
        	                  -end    => @{$loc}[1],
        	                  -strand => @{$loc}[2],
        								));
		}
		#die("$feature_id\n") if @{$locs3} > 0;
		%utrs->{$feat_name} = $s
		  if @{$locs0} + @{$locs1} + @{$locs2} + @{$locs3} > 0;
	}



	# ------------------------------


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
	#foreach my $feature_name (sort(keys(%models))) {
	for my $feature_name (sort keys %fromdb_features_byname) {
		if (exists %models->{$feature_name}) {
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
		}

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

