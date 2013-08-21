#!/usr/bin/env perl

#####################################################################
#                                                                   #
# INITIAL DETAILS:                                                  #
#                                                                   #
# Targets are the on holds and conditional design not possible      #
# Max target length = 3500                                          #
# Must consume 30% or more of the protein                           #
# Must kill 50% of a domain                                         #
# Minimum intron length is 450                                      #
#                                                                   #
# PROTEIN DATABASES                                                 #
# 1. PFAM DOMAINS                                                   #
# 2. InterPro -> contains PFAM                                      #
# 3. UniProt  -> this is place of choice                            #
#                                                                   #
#####################################################################
#####################################################################
# Key:                                                              #
# $var   = scalar                                                   #
# $var_  = ref to array                                             #
# $var__ = ref to hash                                              #
# _some_sub = A subroutine called by another subroutine             #
#####################################################################

use warnings;
use strict;
use Data::Dumper;
use Tie::IxHash;
use Bio::EnsEMBL::Registry;
use Getopt::Long;
use Readonly;

Readonly my %CONSTANTS => (
    '10k_350_flank' => {
        min_flank => 350,
        max_span  => 10000,
    },
    '3500bp_450_flank' => {
        min_flank => 450,
        max_span  => 3500
    }
);

Readonly my %DATASOURCE => (
    genscan => 'enscan',
    pirsf => 'pirsf', 
    pfam => 'pfam',
    prints => 'prints',
    rfamblast => 'rfamblast',
    smart => 'smart',
    superfamily => 'superfamily',
    trf => 'trf' ,
    Unigene => 'unigene',
    havana => 'havana',
    pfscan => 'pfscan',
    scanprosite => 'scanprosite',
    tmhmm => 'tmhmm',
    everything => 'everything',
);

Readonly my $ENSEMBL_DB_NAME => 'mus_musculus_core_58_37k';

GetOptions(
    'flank=s' => \my $flank
) and @ARGV == 2 or die "Usage: $0 --flank=FLANK ENSEMBL_GENE_ID DOMAIN_DB_ID\n";

die "Must specify --flank: " . join( "|", sort keys %CONSTANTS ) . "\n"
    unless defined $flank and $CONSTANTS{$flank};

my ( $MIN_FLANK, $MAX_SPAN ) = @{ $CONSTANTS{$flank} }{ qw( min_flank max_span ) };

my $registry      = open_ensembl_connection();
my $gene_adaptor  = $registry->get_adaptor('Mouse', 'Core', 'Gene') or die "Failed to get gene adaptor\n";
my $dbh = $registry->get_DBAdaptor('Mouse', 'Core') or die "Failed to get the DBAdaptor!\n";

#
# Test gene: PCBP2 - ENSMUSG00000056851
#

my ( $ensembl_id, $domain_db ) = @ARGV;

if ( ! exists $DATASOURCE{$domain_db} ) {
    print "\nThe options datasource options are: \n";
    for ( keys %DATASOURCE ) {
        print "\t$_\n";
    }
    exit;
}

#print "TARGET:$ensembl_id DOM_DB:$domain_db\n";

# Get the gene.
my $gene = get_gene_object( $gene_adaptor, $ensembl_id );

# Get the longest transcript
my $template_transcript = get_longest_transcript( $gene );
die "Failed to get transcript!\n" if ! defined $template_transcript;

# Translate to a protein
my $template_protein = $template_transcript->translation() or die "!!! $ensembl_id !!!"; #Something odd going on here! Not using chromosomes?
die "Failed to translate!\n" if ! defined $template_protein;

# Grab ALL protein feature - will include SNPs
my @protein_features = @{ $template_protein->get_all_ProteinFeatures() };

# Get the domain features - PFAM, interpro etc
my @domain_features = @{ $template_protein->get_all_DomainFeatures()  };

# Get a set of the domains that we want to use in designs
my $domains__ = get_domain_definitions( \@domain_features, $domain_db );

#Get the contribution of each exon to the protein sequence
my $coding_contributions__ = get_coding_contributions( $template_transcript );

#Get a list of all possible exon combinations
my $combinations__ = get_power_sets( $template_transcript, $coding_contributions__ );

#There are some combinations that can never be attempted and so don't get a score at all
remove_impossible_flank_sizes_and_long_combinations( $combinations__, $template_transcript );

#Validate a knockout based on the domain definition
my ( $dom_ko__ ) = validate_domain_ko( $combinations__, $domains__, $template_transcript );

#One characteristic ugly block to finish off the script.

format_for_automatic_design( $dom_ko__, $template_transcript );

#####################################################################
#                                                                   #
#                           THE SUBROUTINES                         #
#                                                                   #
#####################################################################
#                                               #
# Complete the format for the automatic designs #
#                                               #
sub format_for_automatic_design {
    my ( $dom_ko__, $template_transcript ) = @_;

    my %u = ();

    for my $k ( keys %$dom_ko__ ) {
        my ($set, $domain) = split/:/, $k;
        my @set = split /\s+/, $set;
        
        #Get the domain name - this is the ID that Alejo would like
        my $displayed_domain_name = _get_domain_info( $domain );

        sub _get_domain_info {
            my ( $dom ) = @_;
            my $domain_name;
            my $dbh = DBI->connect(
                "dbi:mysql:$ENSEMBL_DB_NAME:ens-livemirror",
                'ensro',
                '',
                {
                    RaiseError=> 1
                }
            ) or die "oops, an error occured!\n";
            my $get_domain_id = "select hit_name from protein_feature where protein_feature_id = ?";
            my $gdi = $dbh->prepare( $get_domain_id );
            $gdi->execute( $dom );
            my $names = $gdi->fetchall_arrayref();
            return( $names->[0][0] );
        }

        my $left_flank  = _calculate_intron_flank_size( $template_transcript, $set[0] , ( $set[0]  ) - 1, 'l' );
        my $right_flank = _calculate_intron_flank_size( $template_transcript, $set[-1], ( $set[-1] ) + 1, 'r' );
        my $span = 5000 - abs( ${ $template_transcript->get_all_Exons() }[ $set[0] ]->start() - ${ $template_transcript->get_all_Exons() }[ $set[-1] ]->end() );
        
        if ( $left_flank  >= 700 ) { $left_flank  = 700 }
        if ( $right_flank >= 700 ) { $right_flank = 700 }
    
        my @l_defaults = (120, 60, 300);
        my @r_defaults = (120, 60, 100);
        my $chrom_start = 0;
        my $chrom_end   = 0;
        
        my $strand = $template_transcript->transform('chromosome')->strand();

        for my $l ( keys %{$dom_ko__->{$k}} ) {
            my @set = split /\s+/, $l;
            
            #                                                                             #
            # Weight the left and right flank and the overall length (span) of the design #
            #                                                                             #
            my $score = sprintf("%.3f", ( $left_flank + $right_flank + $span + ${$dom_ko__->{$k}}{$l} ) / 6500);
            
            if ( $strand == 1 ) {
                $chrom_start = ${$template_transcript->get_all_Exons()}[$set[0]]->transform('chromosome')->start();
                $chrom_end   = ${$template_transcript->get_all_Exons()}[$set[-1]]->transform('chromosome')->end();
            }
            elsif ( $strand == -1 ) {
                $chrom_start = ${$template_transcript->get_all_Exons()}[$set[-1]]->transform('chromosome')->start();
                $chrom_end   = ${$template_transcript->get_all_Exons()}[$set[0 ]]->transform('chromosome')->end();
            }
            else {
                die "There is one hell of an error in your code! Strand == ***$strand***\n";
            }
        
            if ( $left_flank < 700 ) {
                _readjust($left_flank, \@l_defaults);
            }
            if ( $right_flank < 700) {
                _readjust($right_flank, \@r_defaults);
            }
                        
            my $string = "$ensembl_id " .
                          ${$template_transcript->get_all_Exons()}[ $set[0]  ]->transform('chromosome')->stable_id() . " " .
                          ${$template_transcript->get_all_Exons()}[ $set[-1] ]->transform('chromosome')->stable_id() . " " .
                          $gene->feature_Slice->seq_region_name . " " .
                          $chrom_start . " " .
                          $chrom_end   . " " .
                         join(" ", @l_defaults) .
                         " " .
                         join(" ", @r_defaults) .
                         " ($domain_db:$displayed_domain_name:$score)";
                         
            if ( ! $u{"$chrom_start:$chrom_end:$displayed_domain_name"} ) { $u{"$chrom_start:$chrom_end:$displayed_domain_name"} = $string }
        }
    }
    for ( keys %u ) { print "$u{$_}\n" }
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
#                                                                 #
# This determines how much of a domain each critical set overlaps #
#                                                                 #
sub validate_domain_ko {
    my ( $c__, $d__, $tt ) = @_;
    my $coding_start = ${$tt->get_all_translateable_Exons()}[0]->cdna_start($tt);
    my %domain_overlap = ();

    for my $domain ( keys %$d__ ) {
	my @dom = @{$d__->{$domain} };
	my $dom_start = $dom[0];
	my $dom_end   = $dom[1];

	for my $set ( keys %$c__ ) {
	    my @set   = split /\s+/, $set;
	    my @exons = @{$c__->{$set}};
            
	    my $start_point = $exons[0] ->cdna_coding_start( $tt );
	    my $end_point   = $exons[-1]->cdna_coding_end( $tt );
                        
	    $start_point = abs($coding_start - $start_point);
	    $end_point   = abs($coding_start - $end_point); #for some reason this was $start_point !!!
	    my $koed = 0; #The variable to store the amount koed.
            
	    if ( $start_point <= $dom_start and $end_point >= $dom_end ) {
		#rock on - we got the whole domain !!!
		$koed = 100;
	    }
	    elsif ( $start_point >= $dom_start and $end_point <= $dom_end ) {
		#Calculate %
		my $dom_len = abs( $dom_start   - $dom_end );
		my $len     = abs( $start_point - $end_point);
		$koed = ( $len / $dom_len ) * 100;
	    }
	    elsif ( ( $start_point >= $dom_start  and  $start_point < $dom_end )  and $end_point >= $dom_end  ) {		
                my $koed = abs( $start_point - $dom_end );
                $koed = ( $koed / ( abs( $dom_end - $dom_start) ) ) * 100;
	    }
	    elsif ( $start_point <= $dom_start and ( ( $end_point > $dom_start ) and ( $end_point < $dom_end ) ) ) {
		my $overlap = abs( $start_point - $dom_start );
		my $len     = $end_point - ( $start_point + $overlap);
		my $dom_len = abs( $dom_start - $dom_end );
		$koed = ( $len / $dom_len ) * 100;
                #print "$set $koed $dom_start $dom_end\n";
	    }
	    else {
                # !!! THERE IS NOTHING TO HIT !!!
		#print  "#Domain Start: $dom_start Domain End: $dom_end \tCODE start: $start_point CODE end: $end_point\n";
                next;
	    }
            if ( $koed > 40 ) {
                $domain_overlap{"$set:$domain"}{$set} = $koed;
            }
	}	
    }
    return( \%domain_overlap ); 
}


#                                                                                    #
# Remove combination where the flanking exons are short or the construct is too long #
#                                                                                    #
sub remove_impossible_flank_sizes_and_long_combinations {
    my ( $combinations__, $template_transcript ) = @_;
    foreach my $combination ( keys %$combinations__ ) {
	my @all_exons = @{ $template_transcript->get_all_Exons() }; 
	my @list      = @{ $combinations__->{$combination} };
	my @comb      = split /\s+/, $combination;
	
	my $left_flank  = _calculate_intron_flank_size( $template_transcript, $comb[0]  , ( $comb[0]  ) - 1, 'l' );
	my $right_flank = _calculate_intron_flank_size( $template_transcript, $comb[-1] , ( $comb[-1] ) + 1, 'r' );

	if ( $left_flank < $MIN_FLANK or $right_flank < $MIN_FLANK ) {
	    delete $combinations__->{$combination};
	}
	
	my $span = abs( ${$template_transcript->get_all_Exons()}[ $comb[0] ]->start() - ${$template_transcript->get_all_Exons()}[ $comb[-1] ]->end() ); 
	if ( $span > $MAX_SPAN ) {
	    delete $combinations__->{$combination};
	}
    }
}

#                                             #
# Do the calculation of flanking intron sizes #
#                                             #
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
            #print "@sublist (",   _ko_thirty_pct( \@sublist, \@t, $chash ), " " .  _begin_and_end_code( \@sublist, \@t, $chash ), ")\n";
            # // DON'T DELETE THE NEXT LINE \\ #
            if ( _ko_thirty_pct( \@sublist, \@t, $chash ) and _begin_and_end_code( \@sublist, \@t, $chash ) ) {
            #if ( _begin_and_end_code( \@sublist, \@t, $chash ) ) {
                my $k = join( " ", @sublist );
                for ( @sublist ) {
                    push @{ $combinations{ $k } }, $template_transcript->get_all_Exons()->[ $_ ];
                }
            }
        }
    }
    return( \%combinations );    
}

#                                                                    #
# Check that the critical set codes for more than 30% of the protein #
#                                                                    #
sub _ko_thirty_pct {
    my ( $c_, $t_, $chash__ ) = @_;
    my $amount_ko = 0;
    #print "@$c_\n";
    for my $i ( @$c_ ) {
        #print "$i -> ";
        my $e = $t_->[$i];
        if ( exists $chash__->{ $e->stable_id() } ) {
            #print $chash__->{ $e->stable_id() }, "\n";
            $amount_ko += $chash__->{ $e->stable_id() };
        }
    }
    return(1) if $amount_ko >= 30;
    return(0);
}


#                                          #
# Check that the first and last exons code #
#                                          #
sub _begin_and_end_code {
    my ( $c_, $t_, $chash__ ) = @_;
    my $f = $t_->[ $c_->[0] ];
    my $l = $t_->[ $c_->[-1] ];
    return(0) if $c_->[0] == 0; # Can't take the first exon even if it does code - there won't be an exon
    return(0) if $c_->[-1] == (scalar @$t_) - 1;
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
    my %contributions = map { $_->stable_id() => _pct_protein_contribution($protein_length, $_) } @{ $transcript->get_all_translateable_Exons() };
    my $sum = 0;
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

#                                        #
# Get the longest example of each domain #
# THIS METHOD IS INCOMPLETE              #
#                                        #
sub get_domain_definitions {
    my ( $domains_, $dom_db ) = @_;
    
    my $dbh = DBI->connect(
        "dbi:mysql:$ENSEMBL_DB_NAME:ens-livemirror",
        'ensro',
        '',
        {
            RaiseError=> 1
        }
    ) or die "oops, an error occured!\n";
    
    my $sql = (q/
               select display_label
               from protein_feature, analysis_description
               where protein_feature_id = ? and protein_feature.analysis_id = analysis_description.analysis_id;
               /);
    
    #my $get_domain_id = (q/
    #                     select protein_feature_id from protein_feature where protein_feature_id = (?);
    #                     /);
    
    my %domains = ();
    for ( my $i = 0; $i < @$domains_; $i++ ) {
        my $d   = $domains_->[$i];
        
        my $sql_exe = $dbh->prepare($sql);
        $sql_exe->execute( $d->dbID() );

        my $feature_source = $sql_exe->fetchall_arrayref();

        if ( $feature_source->[0][0] =~ /$dom_db/i or $dom_db =~ /everything/i ) { 
	    my $cdna_start = $d->start * 3;
	    my $cdna_end   = $d->end   * 3;
            $domains{ $d->dbID } = [ $cdna_start, $cdna_end ];
	}
    }
    return ( \%domains );
    $dbh->disconnect();
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

#                                                  #
# Get a connection to the latest ensembl release.  #
#                                                  #
sub open_ensembl_connection {
    my $registry = 'Bio::EnsEMBL::Registry';
    $registry->load_registry_from_db(
        -host=>'ensembldb.ensembl.org',
        -user=>'anonymous',
        -port=>5306
    );
    return $registry;
}
