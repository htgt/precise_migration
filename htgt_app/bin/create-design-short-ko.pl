#!/usr/bin/env perl

#-------------------------------------------------------------------#
# Key:                                                              #
# $var   = scalar                                                   #
# $var_  = ref to array                                             #
# $var__ = ref to hash                                              #
# _some_sub = A subroutine called by another subroutine             #
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
#                                                                   #
#            40 instead of 50 % cutoff for protein KO.              #
#                                                                   #
#-------------------------------------------------------------------#

use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use Tie::IxHash;
use Bio::EnsEMBL::Registry;
use Getopt::Long;
use Readonly;

use Smart::Comments;

Readonly my %CONSTANTS => (
    '10k_350_flank' => {
        max_set_len => 10000
    },
    '3500bp_450_flank' => {
        max_set_len => 3500
    }
);

GetOptions(
    'flank=s' => \my $flank
) and @ARGV == 1 or die "Usage: $0 --flank=FLANK ENSEMBL_GENE_ID\n";

die "Must specify --flank: " . join( "|", sort keys %CONSTANTS ) . "\n"
    unless defined $flank and $CONSTANTS{$flank};

my $MAX_SET_LEN = $CONSTANTS{$flank}{max_set_len};

my $ensembl_id = shift @ARGV;

my $registry      = open_ensembl_connection();
my $gene_adaptor  = $registry->get_adaptor('Mouse', 'Core', 'Gene') or die "Failed to get gene adaptor\n";
my $dbh = $registry->get_DBAdaptor('Mouse', 'Core') or die "Failed to get the DBAdaptor!\n";

my $gene = get_gene_object( $gene_adaptor, $ensembl_id );
die "For some reason I didn't get a gene" if ! defined $gene; # Perl Critic says this is naughty - *&@% Damian Conway.

### gene: $gene->stable_id

my $template_transcript = get_longest_transcript( $gene );
die "For some reason I didn't get a template" if ! defined $template_transcript;

### transcript: $template_transcript->stable_id

my $template_protein = $template_transcript->translation(); die "Failed to translate!\n" if ! defined $template_protein;

my ( $all_exons__, $coding_exons__ ) = get_coding_and_all_exons( $template_transcript );

### all exons: keys %{ $all_exons__ }

### coding exons: keys %{ $coding_exons__ }

my $number_of_exons = keys %$coding_exons__;

die "There are too many exons -> $ensembl_id\n" if $number_of_exons > 4;

my $coding_contributions__ = get_coding_contributions( $template_transcript );

### $coding_contributions__

my $combinations__ = get_power_sets( $template_transcript, $coding_contributions__ );

#warn "TARGET: ", $template_transcript->stable_id(), "\n";

shit_sift( $template_transcript, $combinations__ );

sub shit_sift {
    my ( $t, $c ) = @_;

    my %coding_exons = map { $_->stable_id() => $_} @{ $t->get_all_translateable_Exons() };
    my %all_exons    = map { $_->stable_id() => $_} @{ $t->get_all_Exons() };
    
    my @coding = @{ $t->get_all_translateable_Exons() };
    my @all    = @{ $t->get_all_Exons() };

    my %coding_cont = ();
    _coding_cont( \%coding_exons, \%coding_cont );

    my $ce1 = $coding[0];

    my $aas_coded_for_by_ce1 =  (length $ce1->seq()->seq() ) / 3;
    
    # If we have over 35 amino acids we fork one way
    
    if ( $aas_coded_for_by_ce1 >= 35 ) {
        ### More than 35 amino acids
        for my $set ( keys %$c ) {
            # To store the amount of protein KO.
            my %protein_ko = ();
            my @set = split /\s+/, $set;
            my $first_in_set = $all[ $set[0] ];
            # Eliminate a set if the first exon does not code.
            next if ! exists $coding_exons{ $first_in_set->stable_id() };
            ### First exon is coding
            # Get the amount of protein removed - save it to a hash for later too.
            my $set_pct = get_set_sum( \@set, \%coding_cont, \@all );             
            $protein_ko{ $set } = $set_pct; 
            # If we are looking at the very first exon then we don't want it.
            
            #print "$set -> $set_pct ", $coding_exons{ $first_in_set->stable_id() }->stable_id(), ' ',  $coding[0]->stable_id(), "\n";
            # This will fail in some instances - see ENSMUSG0^53206 - Added the check against the all array to solve this - I HOPE!
            ### first in set stable_id: $first_in_set->stable_id
            ### coding[0] stable_id: $coding[0]->stable_id
            ### all[0] stable_id: $all[0]->stable_id
            ### $set_pct            
            
            next if $first_in_set->stable_id() eq $coding[0]->stable_id() and $set_pct < 50
                or $coding[0]->stable_id eq $all[0]->stable_id() ;

            ### Skip the set it the last exon is the last exon in the gene
            next if $all[ $set[-1] ]->stable_id() eq $all[-1]->stable_id();

            ### Skip if the length of the critical set is greater than 3500 nts
            my $set_length = abs( ${$t->get_all_Exons}[ $set[0] ]->start() - ${$t->get_all_Exons}[ $set[-1] ]->end() ) + 1;            
            # Loose criteria
            next if $set_length > $MAX_SET_LEN;
            
            my ( $sphase, $ephase ) = is_it_a_frameshift( \@coding, \@all, \@set );
            
            ### Skip those that hit the start or end exon that do not destroy more than 50% of the protein
            next if ( ( $sphase == 99 or $ephase == 99 ) and $set_pct <= 40 );          
            
            ### Skip the little chaps that are symmetrical - we can't do anything with these until the ELSE block related to this IF block
            next if ( $sphase == $ephase ) and $set_pct <= 40;
            
            ### Skip the ones that have a negative phase and code for less than 50% of the protein
            next if ( $sphase == -1 or $ephase == -1 ) and $set_pct <= 40;
            my $te = $first_in_set->stable_id();
            
            
            my $tt = $template_transcript;
            my $lead_intron = _calculate_intron_flank_size( $tt, $set[0], ( $set[0]  ) - 1, 'l' );
            my $exit_intron = _calculate_intron_flank_size( $tt, $set[0], ( $set[0]  ) + 1, 'r' ) if ${$tt->get_all_Exons()}[ $set[-1] ]->stable_id() ne ${$tt->get_all_Exons()}[-1]->stable_id();

            if ( $flank eq '10k_350_flank' ) {
                if ( ! defined $lead_intron ) { $lead_intron = 350 }
                if ( ! defined $exit_intron ) { $exit_intron = 350 }
            
                next if $lead_intron < 350;
                next if $exit_intron < 350;
            }            
            
            #print "$ensembl_id $te Set remain: [$set], $sphase, $ephase, $set_pct -> $lead_intron -> $exit_intron\n";
            my %hash;
            $hash{ $set } = $set;
            format_for_designs( $tt, \%hash);
            # Arguments -> my ( $tt, $c__) = @_;
            
        }
    }
    # Else we need to test to see if we can induce serveral stop sites elsewhere in the protein
    else {
        ### Missing logic!
        #Must test for new stop sites.
        #Loop over all possible combinations - checking for new stop sites in the sequence - yey
        
        
        
        
    }    
}


#
# This code is verbose so that the person that gets to edit it after me can change it
# It makes some abstract attempt to discern if the CE set is in or out of phase.
#

sub is_it_a_frameshift {
    my ( $c, $n, $s ) = @_;
    
    # The first element of the array is a number, then minus 1 to get the previous exon.
    my $previous_exon = $s->[0]  - 1;
    # The last element of the array is a number, then add 1 to get the next exon.
    my $next_exon     = $s->[-1] + 1;
    
    # Previous exon
    my $pe = $n->[$previous_exon];
    # Next exon
    my $ne = $n->[$next_exon];
    
    my $left_phase  = 100;
    my $right_phase = 101;
    
    if ( defined $pe->end_phase() ) { $left_phase  = $pe->end_phase() }
    if ( defined $ne->phase() ) {     $right_phase = $ne->phase() }
        
    return( $left_phase, $right_phase );
}




#
# Use this to work out how much of the protein is destroyed by removing this set of exons
#

sub get_set_sum {
    my ( $set, $cont, $exons ) = @_;
    my $sum = 0;
    for ( @$set ) {
        my $id = $exons->[$_]->stable_id();
        if ( exists $cont->{$id} ) {
            $sum += $cont->{$id};
        }
    }
    return ( $sum );
}


# Use to get the % contribution of each exon to the final protein
sub _coding_cont {
    my ( $ce, $hash ) = @_;
    my $sum = 0;
    for ( keys %$ce ) {
        $sum += length( $ce->{$_}->seq()->seq() );
        $hash->{ $ce->{$_}->stable_id() } = length( $ce->{$_}->seq()->seq() );
    }
    for ( keys %$hash ) {
        $hash->{$_} = ( $hash->{$_} / $sum ) * 100;
    }
}



#identify_ko( $template_transcript, $combinations__, $coding_contributions__ );

#format_for_designs( $template_transcript, $combinations__ );

#-------------------------------------------------------------------#
#                                                                   #
#                           THE SUBROUTINES                         #
#                                                                   #
#-------------------------------------------------------------------#

#                                                #
# Setup the format for automagic design creation #
#                                                #
sub format_for_designs {
    my ( $tt, $c__) = @_;
    my @l_defaults = (120, 60, 300);
    my @r_defaults = (120, 60, 100);
    my $strand = $tt->transform('chromosome')->strand();
    
    for my $set ( keys %$c__ ) {
        my @set         = split /\s+/, $set;
        my $first       = $set[0 ];
        my $last        = $set[-1];
        my $chrom_start = 0;
        my $chrom_end   = 0;
        my $lf          = 0;
        my $rf          = 0;
        
        $lf = _calculate_intron_flank_size($tt, $set[0] , ( $set[0]  ) - 1, 'l' );
        $rf = _calculate_intron_flank_size($tt, $set[0]  , ( $set[-1] ) + 1, 'r' ) if ${$tt->get_all_Exons()}[ $set[-1] ]->stable_id() ne ${$tt->get_all_Exons()}[-1]->stable_id();
        
        if ( $strand == 1 ) {
            $chrom_start = ${$tt->get_all_Exons()}[$first]->transform('chromosome')->start();
            $chrom_end   = ${$tt->get_all_Exons()}[$last]->transform('chromosome')->end();
        }
        elsif ( $strand == -1 ) {
            $chrom_start = ${$tt->get_all_Exons()}[$last]->transform( 'chromosome')->start();
            $chrom_end   = ${$tt->get_all_Exons()}[$first]->transform('chromosome')->end();
        }
        else {
            die "There is one hell of an error in your code! Strand == ***$strand***\n";
        }
        
       if ( $lf < 700 ) {
            _readjust($lf, \@l_defaults);
        }
        if ( $rf < 700 and $rf != 0 ) {
            _readjust($rf, \@r_defaults);
        }    
        
        print "$ensembl_id ", ${$tt->get_all_Exons()}[$first]->stable_id(), " ",  ${$tt->get_all_Exons()}[$last]->stable_id(), " "
        , $tt->feature_Slice->seq_region_name, " ", $chrom_start, " ", $chrom_end, " @l_defaults @r_defaults\n";
        
    }
}

#                                    #
# Alter the spacer values for flanks #
#                                    #
sub _readjust {
    my ($l, $array) = @_;
    for ( @$array ) {
	$_ = int((( $l / 700 ) * $_) + 0.5);
    }
}

#                                                                        #
# Uses a set of routines to remove the impossilbe/undesirable ko options #
#                                                                        #
sub identify_ko {
    my ( $tt, $c__, $cc__ ) = @_;
    
    for my $set ( keys %$c__ ) {
        #print "CURRENT SET: $set\n";
        my @set = split /\s+/, $set;
        delete $c__->{$set} if ${ $tt->get_all_Exons() }[ $set[0] ]->stable_id() eq ${$tt->get_all_Exons}[0]->stable_id();
        
        #delete $c__->{$set} if ( $cc__->{${$tt->get_all_Exons() }[ $set[-1] ]->stable_id()} < 50 ) and next;
        if ( $cc__->{${$tt->get_all_Exons() }[ $set[-1] ]->stable_id()} < 50 ) {
            
            my $prev_exon_number = $set[0] - 1;
            my $start_phase      = ${$tt->get_all_Exons()}[ ( $prev_exon_number ) ]->end_phase();

            my $trail_exon_number = $set[-1] + 1;
            my $end_phase;
            if ( defined ${ $tt->get_all_Exons() }[  $trail_exon_number  ]  ) {
                $end_phase = ${$tt->get_all_Exons()}[ $trail_exon_number ]->end_phase();
            } else {
                # We are now dealing with the trailing exon !
                #print "SET: $set ( $trail_exon_number )\n";
                delete $c__->{$set};
                next;
            }
            

            #print "Deleting SET: $set $end_phase :: $start_phase\n";
            #print "SET: $set -:> START : $start_phase -> END: $end_phase\n";
            if ( $start_phase == $end_phase ) {
                delete $c__->{$set};   
            }            
            next;
        }
        
        my $crappyness_value = _remove_crappy_coding_sets( \@set, $tt, $cc__ );
        
        delete $c__->{ $set } if $crappyness_value == 0;
                
        my $lead_intron = 0; my $exit_intron = 0;
        
        $lead_intron    = _calculate_intron_flank_size( $tt, $set[0], ( $set[0]  ) - 1, 'l' );
        $exit_intron    = _calculate_intron_flank_size( $tt, $set[0], ( $set[0]  ) + 1, 'r' ) if ${$tt->get_all_Exons()}[ $set[-1] ]->stable_id() ne ${$tt->get_all_Exons()}[-1]->stable_id();

        if ( ${$tt->get_all_Exons() }[ $set[-1] ]->stable_id() eq  ${$tt->get_all_Exons() }[ -1 ]->stable_id()  ) {
            #print $set, ' ', ${$tt->get_all_Exons() }[ $set[-1] ]->stable_id()  ,"\n";
            delete $c__->{ $set } if $lead_intron < 450;
        } else {
            delete $c__->{ $set } if $lead_intron < 450;
            delete $c__->{ $set } if $exit_intron < 450 ; #and scalar @set > 1;
        }
    }
}

#                                           #
# Just what it says - called by identify_ko #
#                                           #

sub _remove_crappy_coding_sets {
    my ( $set_, $tt, $ccp__ ) = @_;
    
    #Get all and coding exons (again!)
    my ( $ae__, $ce__ ) = get_coding_and_all_exons( $tt );
    
    #Get the coding contribution of exons
    my $cc__ = _get_aas_coded( $tt );
    
    #Work out the amount previously coded
    my $number_of_coded_aas = 0;
    for ( keys %$ae__ ) {
        last if $ae__->{$_}->stable_id() eq ${$tt->get_all_Exons() }[ $set_->[0] ]->stable_id();
        if ( exists $ce__->{ $ae__->{$_}->stable_id() } ) {
            $number_of_coded_aas += $cc__->{ $ae__->{$_}->stable_id}
        }
    }
    
    my $pct_coded = 0;
    for ( @$set_ ) { $pct_coded += $ccp__->{${$tt->get_all_Exons() }[$_]->stable_id()} }

    #Get at the phases.
    my $phases_match = 0;
    my $start_phase  = 99; #We won't see these in the wild - we will see 0
    my $end_phase    = 99;
    
    $end_phase   = ${$tt->get_all_Exons()}[  $set_->[-1]      ]->end_phase();
    $start_phase = ${$tt->get_all_Exons()}[ ($set_->[0 ] - 1) ]->end_phase();
    
    if ( $start_phase == $end_phase ) { $phases_match = 1 }
    
    my $span = 0;
    $span = abs( ${$tt->get_all_Exons}[ $set_->[0] ]->start() - ${$tt->get_all_Exons}[ $set_->[-1] ]->end() ) + 1;

    if ( $span > 3500 ) {
        #print "Failed too long: @{$set_}\n";
        return 0;
    }
        
     if ( ! $phases_match and $number_of_coded_aas >= 35 ) {
        #print "PHASES DON'T MATCH ( $phases_match ) - # OF aas: $number_of_coded_aas\n";
        return 1;
     }
    
   if ( $phases_match ) {
        #print "Failed PHASES MATCH: @{$set_}\n";
        return 0;
   }
    
    if ( $pct_coded > 50 ) {
        #print "PCT CODED:  $pct_coded\n";
        return 1;
    }# and $span;
    
    if ( $number_of_coded_aas >= 35 and (${$tt->get_all_Exons}[$set_->[0]]->stable_id() ne ${$tt->get_all_translateable_Exons()}[0]->stable_id()) ) {
        #print "MEH!\n";
        return 1;
    }
    return 0;
}

#                                                             #
# Get the number of amino acids coded by each of the exons    #
#                                                             #

sub _get_aas_coded {
    my ( $transcript ) = @_;
    my $protein_length = ( ( length $transcript->translateable_seq() ) / 3 ) - 1;
    my %contributions = map { $_->stable_id() => _get_aa_count($protein_length, $_) } @{ $transcript->get_all_translateable_Exons() };
    return ( \%contributions );
}

#                                                  #
# Calculate the % of the protein coded by the exon #
# Called by get_aas_coded                          #
#                                                  #

sub _get_aa_count {
    my ( $pl, $e ) = @_;
    my $nts = ( abs( $e->start() - $e->end() )  + 1 ) ;
    my $pc = int ($nts / 3);
}

#                                                                             #
# I think this calculates the evolutionary distance between goats and cats!!! #
#                                                                             #

sub _calculate_intron_flank_size {
    my ( $tt, $c_number, $o_number, $switch ) = @_; #o_number is the next or previous exon number
    my $ces = ${$template_transcript->get_all_Exons() }[ $c_number ]->start; # The current exon start;
    my $cee = ${$template_transcript->get_all_Exons() }[ $c_number ]->end; # The current exon start;
    my $oes = ${$template_transcript->get_all_Exons() }[ $o_number ]->start(); # The current exon start;
    my $oee = ${$template_transcript->get_all_Exons() }[ $o_number ]->end  (); # The current exon start;

    my $length = 0;

    if ( $switch eq 'l' ) {
	$length = abs($ces - $oee) - 1;
    }
    elsif ( $switch eq 'r' ) {
	$length = abs($cee - $oes) - 1;
    }
    else {
	die "Switch '$switch' isn't valid (in function /* _calculate_intron_flank_size *\ \n";
    }
    return($length);
}

#                                          #
# Create the potential power-sets of exons #
#                                          #

sub get_power_sets {
    my ( $template_transcript, $chash ) = @_;
    my @t = @{ $template_transcript->get_all_Exons() };

    tie my %ce_nts, 'Tie::IxHash'; 
    %ce_nts  = map { $_->stable_id() => abs( $_->start() - $_->end() ) + 1 } @{ $template_transcript->get_all_translateable_Exons() };

    my @list = 0 .. $#t;
    my %combinations = ();
    foreach my $start ( 0 .. $#list ) {
        foreach my $end ( $start .. $#list ) {
            my @sublist = @list[ $start .. $end ];
                
            #if ( _begin_and_end_code( \@sublist, \@t, $chash ) ) {
                my $k = join( " ", @sublist );
                for ( @sublist ) {
                    push @{ $combinations{ $k } }, $template_transcript->get_all_Exons()->[ $_ ];
                }
            #}
        }
    }
    return( \%combinations );    
}

#                                          #
# Check that the first and last exons code #
#                                          #

sub _begin_and_end_code {
    my ( $c_, $t_, $chash__ ) = @_;
    my $f = $t_->[ $c_->[0] ];
    my $l = $t_->[ $c_->[-1] ];
    return(0) if $c_->[0] == 0; # Can't take the first exon even if it does code - there won't be an exon
    
    return(0) if $c_->[-1] == (scalar @$t_) - 1 and scalar @$c_ > 1;
    
    if ( exists $chash__->{ $f->stable_id() } and exists $chash__->{ $l->stable_id() }) {
        return (1);
    }
    else {
        return (0);
    }
}


#                                           #
# Get the coding contribution of each exon  #
#                                           #

sub get_coding_contributions {
    my ( $transcript ) = @_;
    my $protein_length = ( ( length $transcript->translateable_seq() ) / 3 ) - 1;
    my %contributions = map {
                            $_->stable_id() => _pct_protein_contribution($protein_length, $_)
                            }
                            @{ $transcript->get_all_translateable_Exons() };
    return ( \%contributions );
}

#                                                  #
# Calculate the % of the protein coded by the exon #
# Called by get_coding_contributions               #
#                                                  #

sub _pct_protein_contribution {
    my ( $pl, $e ) = @_;
    my $nts = ( abs( $e->start() - $e->end() )  + 1 ) ;
    my $pc = (int ($nts / 3) / $pl ) * 100;
}



#                                                  #
# Get the all the exons and coding exons mapped    #
# to tied hashes for convenience                   #
#                                                  #

sub get_coding_and_all_exons {
    my ( $tt ) = @_;
    tie my %coding_exons, 'Tie::IxHash';
    tie my %all_exons, 'Tie::IxHash';
    %coding_exons = map { $_->stable_id() => $_ } @{ $tt->get_all_translateable_Exons() };
    %all_exons = map { $_->stable_id() => $_ }    @{ $tt->get_all_Exons() };
    
    return ( \%all_exons, \%coding_exons );
}


#                               #
# Get a gene on a feature slice #
#                               #

sub get_longest_transcript {
    my ( $gene_object ) = @_;
    my @transcripts = @{ $gene_object->get_all_Transcripts() };
    my $transcript      = '';
    my $longest_protein = 0;
    
    for ( my $i = 0 ; $i < @transcripts; $i++ ) {
        my $protein_length = ( ( length $transcripts[$i]->translateable_seq() ) / 3 ) - 1;
        if ( $ protein_length > $longest_protein ) {
            $longest_protein = $protein_length;
            $transcript      = $transcripts[$i];
        }
    }
    return( $transcript ) if defined $transcript;
    die "A transcript could not be defined for ", $gene_object->stable_id(), "\n";
}

#                               #
# Get a gene on a feature slice #
#                               #

sub get_gene_object {
    my ( $ga, $ens_id ) = @_;
    my $gene = $ga->fetch_by_stable_id( $ens_id );
    die "$ens_id cannot be found - please check manually!\n" if ! defined $gene;
    return ( $gene = $gene->transfer( $gene->feature_Slice() ) );   
}

#                               #
# Open a connection to the data #
#                               #

sub open_ensembl_connection {
    my $registry = 'Bio::EnsEMBL::Registry';
    $registry->load_registry_from_db(
        -host=>'ensembldb.ensembl.org',
        -user=>'anonymous',
        -port=>5306
    );
    return $registry;
}
