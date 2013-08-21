#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Bio::EnsEMBL::Registry;
use Getopt::Long;
use Readonly;

use Smart::Comments;

Readonly my %CONSTANTS => (    
    '10k_350_flank' => {
        max_protein         => 0.65,
        min_flanking_intron => 350,
        max_construct_len   => 10000,
    },
    '3500bp_450_flank' => {
        max_protein         => 0.5,
        min_flanking_intron => 450,
        max_construct_len   => 3500,        
    }
);

GetOptions(
    'flank=s' => \my $flank
) and @ARGV == 1 or die "Usage: $0 --flank=FLANK ENSEMBL_GENE_ID\n";

die "Must specify --flank: " . join( "|", sort keys %CONSTANTS ) . "\n"
    unless defined $flank and $CONSTANTS{$flank};

my ( $MAX_PROTEIN, $MIN_FLANKING_INTRON, $MAX_CONSTRUCT_LEN ) =
    @{ $CONSTANTS{ $flank } }{ qw( max_protein min_flanking_intron max_construct_len ) };

my $ams = shift @ARGV;

### $ams

my $registry = 'Bio::EnsEMBL::Registry';
$registry->load_registry_from_db(
    -host=>'ensembldb.ensembl.org',
    -user=>'anonymous',
    -port=>5306
);

my $gene_adaptor = $registry->get_adaptor('Mouse', 'Core', 'Gene') or die "Failed to get gene adaptor\n";
my $dbh = $registry->get_DBAdaptor('Mouse', 'Core') or die "Failed to get the DBAdaptor!\n";
my $sa = $dbh->get_SliceAdaptor('Mouse', 'Core', 'Gene') or die "Failed to get the slice adaptor\n";

my $gene = $gene_adaptor->fetch_by_stable_id($ams);
if ( ! defined $gene ) {
    die "$ams Removed from DB\n"; #removed from database
}

### Got gene: $gene->stable_id

#transfer to slice.
$gene = $gene->transfer( $gene->feature_Slice() );
my @transcripts = @{$gene->get_all_Transcripts() };

#sort transcripts by length;

my $template_transcript;
my $current_length = 0;
for my $t (@transcripts) {
    my $length = length $t->translateable_seq();
    #print "LEN: $length->", $t->stable_id(), "\n";
    if ( $length > $current_length ) { $current_length = $length; $template_transcript = $t;}
}

if ( ! defined $template_transcript ) { 
    die "$ams failed to define a template\n";
}

### Got template transcript: $template_transcript->stable_id


#Find first coding exon

my @template_coding_exons = @{$template_transcript->get_all_translateable_Exons()};
my @template_all_exons    = @{$template_transcript->get_all_Exons()};
my $template_seq          = $template_transcript->translateable_seq();
my $template_seq_length   = ( length $template_seq ) / 3;

#I am expecting to do a look-up later and think the best way is to hash the data!
my %coding_exons = map { $_->stable_id() => $_ } @{ $template_transcript->get_all_translateable_Exons() };
my %all_exons    = map { $_->stable_id() => $_ } @{ $template_transcript->get_all_Exons() }; 

#Filter out those transcripts with two or less FULLY coding exons
my $numb_fully_coding_exons = 0;

for my $e ( @template_coding_exons ) {
    if ( exists $all_exons{$e->stable_id()}  ) { 
	$e = $all_exons{ $e->stable_id() } ;
	my $code_len = ( abs($e->cdna_coding_start($template_transcript) - $e->cdna_coding_end($template_transcript) ) + 1 );
	my $full_len = abs($e->start() - $e->end()) + 1;
	if ( $full_len == $code_len ) { $numb_fully_coding_exons++; }
    }
}

### $numb_fully_coding_exons

if ( $numb_fully_coding_exons <=2 ) {
    die "$ams - not enough coding material!\n";
} 

#Determine point after 35 amino acids have been coded for
my $first_ko_exon;
my $first_ko_exon_obj;
my $first_ko_id;

my $first_coding_exon = $template_coding_exons[0];

#This does not do what you think it does!
#my $aas_coded = (abs( $first_coding_exon->cdna_coding_start($template_transcript) - $first_coding_exon->cdna_coding_end($template_transcript) ) + 1);
my $aas_coded  = (abs( $first_coding_exon->cdna_coding_end($template_transcript) - $first_coding_exon->cdna_coding_start($template_transcript) ) ) / 3;

#print $first_coding_exon->start(), "\n";
#print $first_coding_exon->end(), "\n";
#print $first_coding_exon->cdna_coding_start($template_transcript), "\n";
#print $first_coding_exon->cdna_coding_end($template_transcript), "\n";

for ( my $i = 0 ; $i < @template_all_exons; $i++ ) {
    if ( $aas_coded <= 35 and $template_all_exons[$i]->stable_id eq $first_coding_exon->stable_id() ) {
	$first_ko_exon = $i + 2;
	$first_ko_exon_obj = $template_all_exons[$i+2];
	$first_ko_id = $template_all_exons[$i+2]->stable_id();
    } elsif ( $aas_coded > 35 and $template_all_exons[$i]->stable_id eq $first_coding_exon->stable_id() ) {
	$first_ko_exon = $i + 1;
	$first_ko_exon_obj = $template_all_exons[$i+1];
	$first_ko_id = $template_all_exons[$i+1]->stable_id();
    } else {
	#oh no!
    }
}

### $first_ko_exon


my @errors = ();
my %scores = ();

#See if we can hack out the first exon :)
my $first_exon = $template_coding_exons[0];
my $number_of_acids = ( ( $first_exon->cdna_coding_end($template_transcript) - $first_exon->cdna_coding_start($template_transcript) ) + 1 ) / 3;
if ( $number_of_acids <= 35 ) {
    my $score = 0;
    my $two_up = $template_coding_exons[2];
    my $first_exon_seq = $first_exon->seq()->seq();
    my $two_up_seq     = $two_up    ->seq()->seq();

    my $f =  (length $first_exon_seq ) / 3;
    #print "LEN: $f\n";
    #print "$first_exon_seq\n";

    #This is a huge pile of arse - the ensembl api is totally inconsistent in the way it treats coding exons.
    #asking for the coding exons and coordinates gives only the coding start and end ... if you ask for the sequence
    #you get the untranslated part too.  WHAT A PILE OF SHITE!

    if ( ( ( length $first_exon_seq ) / 3 ) =~ /^-?\d+$/ ) {
	my $str = substr $first_exon_seq, -2;
	$str .= substr $two_up_seq, 0, 1;
	
	if ( $str =~ /TAA|TAG|TGA/ig ) {
	    my $left_flank  = ( $template_coding_exons[1]->start() - $template_coding_exons[0]->end() ) - 1;
	    my $right_flank = ( $template_coding_exons[2]->start() - $template_coding_exons[1]->end() ) - 1;

	    #print "LF: $left_flank  RF: $right_flank\n";

	    score_flanking_introns( \$left_flank, \$right_flank, \$score );

	    $score += 60; #Because I KNOW we are in the first 20% of the protein.

	    score_region_length( $template_coding_exons[1], $template_coding_exons[1] , $template_transcript, \$score );	    

	    $score += 1000000000000;
	    #$scores{$template_coding_exons[1]->stable_id() } = "$score $left_flank $right_flank " . $template_coding_exons[1]->transform('chromosome')->start() . " " . $template_coding_exons[1]->transform('chromosome')->end();   
	} else {

	}
	
    } else {

    }
}

#Tested and appear to work on ENSMUSG00000029465->Ensmust00000102525 - DO NOT DELETE THIS LINE PLEASE.

my $power_sets = power_sets(\@template_all_exons);

### Got power sets

#Loop over the combinations - isn't this fun?
for my $set ( @$power_sets ) {
    ### Considering: $set

    my $score = 0;
    my @set_array = split /\s+/, $set;
    
    my $first_exon_id = $template_all_exons[ $set_array[0] ]->stable_id();
    my $last_exon_id  = $template_all_exons[ $set_array[$#set_array] ]->stable_id();
    
    #Remove if less than 35 amino acids have been coded for
    #print "FKO = $first_ko_exon\n";
    if ( $set_array[0] < $first_ko_exon ) {
    #Need to pass this off to another routine to check the new termination site - we have compensated for this above :)
        #push @errors, "$set - less than 35 residues have been coded for by previous exons!\n";
	#print "CODED FOR ... $set\n";
        ### Skipping - first exon in power set is before first KO exon
        next;
    }
    
    # exists $coding_exons{ $template_all_exons[$set_array[0]] }->stable_id();
    if ( ! exists $coding_exons{$template_all_exons[ $set_array[0] ] ->stable_id()} ) {
	#print "NICE ... $set\n";
        ### Skipping - first exon is power set is non-coding
	next;
    }

    #Can't remove the last coding exon
    if ( $set_array[ $#set_array ] + 1 == scalar @template_all_exons) {
	#print "LCE ... $set\n";
        #push @errors, "$set Can't ko last coding exon\n";
        ### Skipping - last coding exon
        next;
    }

    #Establish the amount of protein coded by previous exons
    #Remove if > 50% of protein
    my $exon_start_point = 0;
    for ( my $i = 0; $i < $set_array[0]; $i++ ) {
	#This avoids the problem of the non-coding exons - why didn't I just loop over the coding ones? - I was tired on Friday ...
	if ( exists $coding_exons{$template_all_exons[$i]->stable_id()} ) { 
	    $exon_start_point += ( $template_all_exons[ $i ]->cdna_coding_end($template_transcript) - $template_all_exons[ $i ]->cdna_coding_start($template_transcript) ) + 1;
	} else {
	    next;
	}
    }
    $exon_start_point = $exon_start_point / 3;
    if ( $exon_start_point > $MAX_PROTEIN * $template_seq_length ) {
        #push @errors, "$set - going towards C-terminal of protein\n";
	#print "CTERM ... $set\n";
        ### Skipping - going towards C-terminal of protein
        next;
    }
  
    #Get and check for phase matches
    my $left_exon_phase  = $template_all_exons[ $set_array[ 0 ] -1 ]->end_phase();
    my $right_exon_phase = $template_all_exons[ $set_array[ $#set_array ] +1 ]->phase();
    
    #Remove matching phase
    if ( $left_exon_phase == $right_exon_phase ) {
	#print "SYM ... $set\n";
        #push @errors, "$set symmetical exons\n";
        ### Skipping - symmetrical exons
	next;
    }
    
#print $set, " " ,  $template_all_exons[ $set_array[0]  ]->stable_id() , ":" , $template_all_exons[ $set_array [ $#set_array ] ]->stable_id() , " $left_exon_phase :: $right_exon_phase\n"; 

#Skip those where either flanking intron is less than 450 base pairs - this would look nicer if the patterns referenced exons directly.
    #This is partial fall out from stopping me from using $$ - you may think the comments here are odd, the ones in HTGT are worse!
    #print "$set\n";
 
    my $left_intron_length  = ( $template_all_exons[ $set_array[ 0 ] ]->start() - $template_all_exons[ $set_array[ 0 ] -1 ]->end() ) - 1;
    my $right_intron_length = ( $template_all_exons[ $set_array[ $#set_array ] +1 ]->start() - $template_all_exons[ $set_array[ $#set_array ] ]->end() ) - 1;

    #debug
    #print "$set " , $left_intron_length, " ", $right_intron_length, "\n";

    if ( $left_intron_length <= $MIN_FLANKING_INTRON or $right_intron_length <= $MIN_FLANKING_INTRON ) {
	#push @errors, "$set short flanking introns\n";
	#print "intron length ... $set\n";
        ### Skipping - short flanking introns
	next;
    }

    #Score the intron lengths
    score_flanking_introns( \$left_intron_length, \$right_intron_length, \$score );

    #This is probably over-complicated but I don't care ... actually I do ... but I can't be arsed to think about it.
    #Errors are occuring here!
    score_distance_from_nterm( $set_array[0], \@template_all_exons, \%coding_exons, $template_transcript, $template_seq_length, \$score);

    #Score the length of the construct
    my ($len) = score_region_length( $template_all_exons[ $set_array[0] ], $template_all_exons[ $set_array[ $#set_array ] ] , $template_transcript, \$score );

    #print "The length of the construct is: $len\n";
    if ( $len > $MAX_CONSTRUCT_LEN ) {
	#print "length skip ... $set ($len)\n";
        ### Skipping - exceeded max construct length
	next;
    }

    #Check for things on the opposite strand1
    my $overlap = overlapping_loci(  $template_all_exons[ $set_array[0] ], $template_all_exons[ $set_array[ $#set_array ] ], $sa );

    #print "$set OVERLAP: $overlap\n";
    #print $template_all_exons[$set_array[0]]->stable_id, " --> ", $template_all_exons[ $set_array[ $#set_array ] ]->stable_id, "\n";

    if ( $overlap ) {
	#print "OVL ... $set\n";
	#push @errors, "$set overlapping loci\n";
        ### Skipping - overlapping loci
	next;
    } else {
	my $key = '';
	for ( my $i = 0; $i < @set_array; $i++ ) {
	    my $e = $template_all_exons[ $set_array[$i] ];
	    $key .= $e->stable_id() . " ";
	}
   
	$scores{$key} = $score;
	#Should create new exon objects on the chromosome
	my $chr_exon_r = $template_all_exons[ $set_array[$#set_array] ];

        ### Adding score: $score
        
	if ( $template_all_exons[$set_array[0]]->transform('chromosome')->strand() == 1 ) {
	    $scores{$key} = "$score $left_intron_length $right_intron_length " 
		. $template_all_exons[$set_array[0]]->transform('chromosome')->start() 
		. " " 
		. $template_all_exons[$set_array[$#set_array] ]->transform('chromosome')->end();
	} else {
	    $scores{$key} = "$score $left_intron_length $right_intron_length " 
		. $template_all_exons[$set_array[$#set_array] ]->transform('chromosome')->start()
		. " " 
		.   $template_all_exons[$set_array[0]]->transform('chromosome')->end();

	    #warn  $template_all_exons[$set_array[0]]->transform('chromosome')->end (), "*\n";		
	    #warn  $template_all_exons[$set_array[0]]->transform('chromosome')->strand(), "\n";
	    #warn  $template_all_exons[$set_array[0]]->transform('chromosome')->start() . " --> ";
	    #warn  $template_all_exons[$set_array[$#set_array] ]->transform('chromosome')->end(), "-->";
	    #warn  $template_all_exons[$set_array[$#set_array] ]->transform('chromosome')->start(), "\n";
	}	
    }
}

### %scores

if ( keys %scores > 0 ) {
    my $found_common;
    for ( keys %scores ) {
        my @values = split /\s+/, $scores{$_};
    
	my @tmp = split /\s+/, $_; #tmp is the list of exons covered by the critical regions.
	my $are_common = common_to_sets(\@tmp, \@transcripts, $template_transcript);
	
	#print "COMMON STATUS: $are_common!\n";
	if ( $are_common ) {
            $found_common = 1;
	    my ( $l_param, $r_param, $chr_s, $chr_e ) = prepare_for_automagic($scores{$_});
            my $chr_name = $gene->feature_Slice->seq_region_name;            
	    print "$ams $tmp[0] $tmp[$#tmp] $chr_name $chr_s $chr_e @{$l_param} @{$r_param} ($values[0])\n";
	}
    }
    die "$ams - no exons common to template transcript\n" unless $found_common;
}
else {
    die "$ams - no suitable floxed exons\n";
}

#                                                                          #
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<< SNIP >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#
#                                                                          #

sub prepare_for_automagic {
    my ( $string ) = @_;
    my ($score, $lil, $ril, $chr_s, $chr_e) = split /\s+/, $string;
    
    my @defaults_l = ( 120, 60, 300);
    my @defaults_r = ( 120, 60, 100);
    
    if ( $lil < 700 ) {
        _readjust($lil, \@defaults_l);
    }
    if ( $ril < 700 ) {
        _readjust($ril, \@defaults_r);
    }    
	return(\@defaults_l, \@defaults_r, $chr_s, $chr_e);
}


sub _readjust {
    my ($l, $array) = @_;
    for ( @$array ) {
	$_ = int((( $l / 700 ) * $_) + 0.5);
    }
}

sub common_to_sets {
    my ( $exons, $transcripts, $tt ) = @_; #$tt is the template transcript
    ### common_to_sets: $exons
    my $f_exon = $exons->[0];
    my $l_exon = $exons->[scalar @{$exons} -1 ];

    my %transcripts = map { $_->stable_id() => $_ } @$transcripts;

    return (1) if keys %transcripts == 1;

    delete $transcripts {$tt->stable_id() }; #remove the template transcript as the exons belong to this chap   

    ### transcripts: keys %transcripts    

    # XXX (rm7) This is a bug: if the first transcript checked
    # contains the exons, no subsequent transcripts will be checked
    for my $t ( keys %transcripts ) {
        ### checking transcript: $t
	my %coding_exons = map { $_->stable_id() => $_  } @{ $transcripts{$t}->get_all_translateable_Exons() };
	if ( exists $coding_exons{$f_exon} and exists $coding_exons{$l_exon} ) {
	    return (1);
	} else {
	    return (0);
	}
    }
}

sub overlapping_loci {
    my ( $left_exon, $right_exon, $slice_adaptor ) = @_;
    my $left_slice  = $slice_adaptor->fetch_by_exon_stable_id( $left_exon -> stable_id(), 1500 );
    my $right_slice = $slice_adaptor->fetch_by_exon_stable_id( $right_exon-> stable_id(), 1500 );

    my @left_exonS =  @{$left_slice->get_all_Exons()};
    my @right_exonS = @{$right_slice->get_all_Exons()};

    my %left_exons  = map { $_->stable_id() => $_ } @{ $left_slice->get_all_Exons() } ;
    my %right_exons = map { $_->stable_id() => $_ } @{ $left_slice->get_all_Exons() } ;

    my $strand = $left_exons{$left_exon->stable_id()}->strand;

    _delete_same_strand( \%left_exons , $strand );
    _delete_same_strand( \%right_exons, $strand );

    #for (keys %left_exons  ) { 
    #print $left_exons{$_}->stable_id(), "\n";
    #}

    if ( keys %left_exons > 1 or keys %right_exons > 1 ) {
	return(1);
    }
    else {
	return(0);
    }
}

sub _delete_same_strand {
    my ( $hash, $strand ) = @_;
    for ( keys %$hash ) { 
	#print "STR: $strand :: ", $hash->{$_}->strand(), "\n";
	if ( $hash->{$_}->strand == $strand) {
	    #print "!!!!\n";
	    delete $hash->{$_};
	} 
    }
}

sub score_region_length{ 
    my ($left_exon, $right_exon, $transcript, $score ) = @_;
    my $size = ( $right_exon->end() - $left_exon->start() ) + 1;
    if    ( $size  <=  500 ) { $$score += 200; }
    elsif ( $size >  500 and $size <= 1000 ) { $$score += 190; }
    elsif ( $size > 1000 and $size <= 1500 ) { $$score += 180; }
    elsif ( $size > 1500 and $size <= 2000 ) { $$score += 150; }
    elsif ( $size > 2000 and $size <= 2500 ) { $$score += 100; }
    elsif ( $size > 2500 and $size <= 3500 ) { $$score += 25; }
    else { } #do nothing - welcome to the world of C.

    return ($size);

}

sub score_distance_from_nterm {
    my ( $first_set_exon, $all_exons, $coding_exons, $transcript, $seq_length, $score ) = @_;

    my $e = $all_exons->[$first_set_exon];

    my $code_start_pos = 0;
    for ( my $i = 0; $i < @$all_exons; $i++ ) {
	my $ce = $all_exons->[$i]; #you people and your silly fear of $$all_exons[$i]
	if ( exists $coding_exons->{$ce->stable_id()} ) {
	    #print $ce->stable_id(), "    <----\n";
	    $code_start_pos = $ce->cdna_coding_start($transcript);
	    last; #aka a goto
	} else {
	    next; #skip the ones that don't code for nothing - yes that is a double negative which would imply that the exon DID code for something!
	}
    }

    #print $e->cdna_coding_start($transcript), "\n";
    #print $e->stable_id(),"\n";
    my $dist_from_start = ($e->cdna_coding_start($transcript) - $code_start_pos)/3;
    #my $dist_from_start = 12;
    if    ( $dist_from_start < 0.2 * $seq_length ) { $$score += 80; }
    elsif ( $dist_from_start < 0.2 * $seq_length ) { $$score += 70; }
    elsif ( $dist_from_start < 0.2 * $seq_length ){  $$score += 40; }
    elsif ( $dist_from_start < 0.2 * $seq_length ){  $$score += 20; }
    else { $$score += 0; } #Almost pointless ... actually, like most comments in this *script*, totally pointless

    
}

#This routine scores the flanking intron lengths.  It is recycled from the old algorithm D.A.N
sub score_flanking_introns{
    my ($l, $r, $score_) = @_;
    if ( $$l >= 700 and $$r >= 700 ) {
	$$score_ += 200;
    }
    
    elsif ( $$l >= 700 ) {
	if ( $$r >= 500 and $$r < 700 ) { $$score_ += 80; }
	elsif ( $$r >=  400 and $$r < 500 ) { $$score_ += 20; }
	elsif ( $$r < 400 and $$r > 350 ) { $$score_ -= 60; }
	elsif ( $$r < 350 ) { $$score_ -= 80; }
	else {
	    warn "URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 1 ($$l <-> $$r)\n";  die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n"; 
	}
    }
    
    elsif ( $$r >= 700 ) {
	if ( $$l >= 500 and $$l < 700 ) { $$score_ += 80; }
	elsif ( $$l >= 400 and $$l < 500 ) { $$score_ += 20; }
	elsif ( $$l < 400 and $$l > 350 ) { $$score_ -= 60; }
	elsif ( $$l < 350 ) { $$score_ -= 80; }
	else {
	    warn "URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 2 ($$l <-> $$r)\n";  die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n"; 
	}
    }
    
    elsif ( $$l < 700 and $$l >= 500 ) {
	if ( $$r < 700 and $$r >= 500 ) { $$score_ += 50; }
	elsif ( $$r < 500 and $$r >= 400 ) { $$score_ += 10; }
	elsif ( $$r < 400 ) { $$score_ -= 80; } 
	else {
	    warn "URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 3 ($$l <-> $$r)\n";  die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n"; 
	}
    }
    
    elsif ( $$r < 700 and $$r >= 500 ) {
	if ( $$l < 700 and $$l >= 500 ) { $$score_ += 50; }
	elsif ( $$l < 500 and $$l >= 450 ) { $$score_ -= 20; }
	elsif ( $$l < 450 ) { $$score_ -= 80; } 
	else {
	    warn "URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 4 ($$l <-> $$r)\n";  die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n"; 
	}
    }
    
    elsif ( $$l < 500 and $$l >= 400 ) {
	if ( $$r < 500 and $$r >= 400 ) { $$score_ += 5; }
	elsif ( $$r < 400 ) { $$score_ -= 45; }
	else {
	    warn "URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 5 ($$l <-> $$r)\n";  die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n"; 
	}
    }
    
    elsif ( $$r < 500 and $$r >= 400 ) {
	if ( $$l < 500 and $$l >= 400 ) { $$score_ += 5;}
	elsif ( $$l < 400 ) { $$score_ -= 45; }
	else {
	    warn "URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 6 ($$l <-> $$r)\n";  die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n"; 
	}
    }
    
    elsif ( $$l < 400 and $$r < 400 ) {
	if (    $$l >= 350 and $$r <  400 ) { $$score_ -= 100; }
	elsif ( $$l  < 400 and $$r >= 350 ) { $$score_ -= 15; }
	elsif ( $$l  < 350 and $$r <  350 ) { $$score_ -= 250; }
	else {
	    warn "URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 7 ($$l <-> $$r)\n";  die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n"; 
	}
    }
    
    else {
	warn "URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 8 ($$l <-> $$r)\n"; die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n"; 
    }        
}




sub power_sets {
    my ($array) = @_;
    my @t = @$array;
    my @sets = ();
    my @list = 0 .. $#t;
    foreach my $start ( 0..$#list) {
        foreach my $end ( $start..$#list) {
            my @sublist = @list[$start..$end];
            push @sets, join (' ', @sublist);
        }
    }
    return(\@sets);    
}











