package HTGT::Utils::QCTestResults;

use strict;
use warnings FATAL => 'all';
use Data::Dumper;

use Sub::Exporter -setup => {
    exports => [ qw( fetch_test_results_for_run ) ]
};

use Log::Log4perl qw( :easy );
use Const::Fast;
use List::Util qw(sum);
use HTGT::QC::Util::DesignLocForPlate qw( design_loc_for_plate  design_loc_for_epd_plate );
use HTGT::Utils::WellName qw ( to384 );
use HTGT::QC::DistributionLogic;
use HTGT::QC::Config;
use HTGT::QC::Config::Profile;
use JSON;

const my $FETCH_RESULTS_SQL => <<'EOT';
select distinct r.plate_name, r.well_name, r.pass, s.design_id, m.marker_symbol,
a.primer_name, a.pass as PRIMER_PASS, a.score, a.features, a.target_start, a.target_end,
sr.length as PRIMER_READ_LENGTH,
g.name as REGION_NAME, g.length as REGION_LENGTH, g.match_count as REGION_MATCH_COUNT, g.pass as REGION_PASS
from qc_test_results r
join qc_synvecs s on s.qc_synvec_id = r.qc_synvec_id
join project p on p.design_id = s.design_id
join mgi_gene m on m.mgi_gene_id = p.mgi_gene_id
join qc_test_result_alignment_map am on am.qc_test_result_id = r.qc_test_result_id
join qc_test_result_alignments a on a.qc_test_result_alignment_id = am.qc_test_result_alignment_id 
join qc_test_result_align_regions g on g.qc_test_result_alignment_id = a.qc_test_result_alignment_id
join qc_seq_reads sr on sr.qc_seq_read_id = a.qc_seq_read_id
where r.qc_run_id = ?
order by plate_name, well_name, design_id, primer_name
EOT

const my $FETCH_PRIMER_BAND_DATA_SQL => <<'EOT';
select w.well_name, wd.data_type, wd.data_value
from well_data wd
join well w on w.well_id = wd.well_id
join plate p on p.plate_id = w.plate_id
where p.name in (
  select distinct plate_name
  from qc_test_results r
  where r.qc_run_id = ?
)
and wd.data_type like 'primer_band_%'
EOT

sub fetch_test_results_for_run {
    my ( $schema, $qc_run_id ) = @_;

    my $qc_run = $schema->resultset( 'QCRun' )->find( { qc_run_id => $qc_run_id } );
    unless ( $qc_run ) {
        WARN( "QC run $qc_run_id not found" );
        return;
    }

    my $vector_stage = get_vector_stage( $qc_run );

    my $expected_design_loc; 
    if ( $vector_stage eq 'allele' ) {
        $expected_design_loc = design_loc_for_epd_plate( $qc_run->template_plate->name );    
    }
    else{
        $expected_design_loc = design_loc_for_plate( $qc_run->template_plate->name );    
    }

    #we store all the plates, wells, primers and sequence read lengths in here. 
    my %read_length_for;

    #populate read_length_for with seq_reads data (from the qc_seq_reads table)  
    for my $seq_read ( $qc_run->seq_reads ) {
        my $plate_name = $seq_read->plate_name;
        my $well_name  = lc $seq_read->well_name;
        my $primer_name = $seq_read->primer_name;
        if ( $plate_name and $well_name and $primer_name ) {
            #only overwrite an existing primer sequence length if we have a longer one
            if ( exists $read_length_for{ $plate_name }{ $well_name }{ primers }{ $primer_name } ) {
                if ( $read_length_for{$plate_name}{$well_name}{primers}{$primer_name} > $seq_read->length ) {
                    $read_length_for{$plate_name}{$well_name}{primers}{$primer_name} = $seq_read->length;
                }

                next; #we don't want to increase the num_reads 
            }

            $read_length_for{ $plate_name }{ $well_name }{ primers }{ $primer_name } = $seq_read->length;
            #we found another primer, so update the total number of primers for this well
            $read_length_for{ $plate_name }{ $well_name }{ num_reads } += 1; #undef + 1 = 1

            #there are likely multiple primers per well, but the well_name_384 doesnt change,
            #so if its already set we don't need to set it again.
            next if exists $read_length_for{ $plate_name }{ $well_name }{ well_name_384 };

            my $well_name_384 = ( $vector_stage eq 'allele' ) ? "" : to384( $plate_name, $well_name );
            $read_length_for{ $plate_name }{ $well_name }{ well_name_384 } = $well_name_384;
        }
    }

    #if a plate map has been set we assume this is a merged run
    my $merged_run = ( $qc_run->plate_map ) ? 1 : 0;

    #if we detect this as being a merged run recreate the read_length_for hash
    #with the mapped plate names, so we can refer to the seq read data from our
    #database query. see comments in get_merged_data for more info
    if ( $merged_run ) {
        #decode_json returns a hashref 
        my $merged_data = get_merged_data( decode_json $qc_run->plate_map, \%read_length_for );

        #overwrite read_length_for with our new merged data.
        %read_length_for = %{ $merged_data };
    }

    #es cell runs need plates merged
    %read_length_for = %{ combine_ABRZ_plates( \%read_length_for) } if $vector_stage eq 'allele';

    my ( @results, %processed );
    
    $schema->storage->dbh_do(
        sub {
            my $sth = $_[1]->prepare( $FETCH_RESULTS_SQL );
            $sth->execute( $qc_run->qc_run_id );
            my $r = $sth->fetchrow_hashref;
            while ( $r ) {
                #r gets changed within this loop so save the plate name and well name here.
                my $plate_name = $r->{PLATE_NAME};
                my $well_name = lc $r->{WELL_NAME};

                my $expected_design_id = 'replace me';
                my $strict_well_name = uc substr( $well_name, -3 );
                if ( $vector_stage eq 'allele' ) {
                    $expected_design_id = $expected_design_loc->{ $plate_name }->{ $strict_well_name };
                    if ( ! $expected_design_id ) {
                        if ( $r->{PLATE_NAME} =~ /(\S*EPD)0+(\S+)/ ) {
                            my $tmp_plate = $1 . "0" . $2;
                            $expected_design_id = $expected_design_loc->{ $tmp_plate }->{ $strict_well_name } || '-';
                        }
                    }
                } else {
                    $expected_design_id = $expected_design_loc->{ $strict_well_name } || '-';
                }

                my %result = (
                    plate_name         => $plate_name,
                    well_name          => $well_name,
                    design_id          => $r->{DESIGN_ID},
                    expected_design_id => $expected_design_id,
                    pass               => $r->{PASS},
                    marker_symbol      => $r->{MARKER_SYMBOL},
                    num_reads          => $read_length_for{ $plate_name }{ $well_name }{ num_reads },
                    well_name_384      => $read_length_for{ $plate_name }{ $well_name }{ well_name_384 },
                );

                #all this primer information is used in the csv generation on view_run.

                my %primers;
                while ( $r and $r->{PLATE_NAME} eq $result{plate_name}
                            and lc($r->{WELL_NAME}) eq $result{well_name}
                                and $r->{DESIGN_ID} == $result{design_id} ) {
                    my $this_primer = $r->{PRIMER_NAME};
                    $primers{$this_primer}{pass} = $r->{PRIMER_PASS};
                    $primers{$this_primer}{score} = $r->{SCORE};
                    $primers{$this_primer}{features} = $r->{FEATURES};
                    $primers{$this_primer}{target_align_length} = abs( $r->{TARGET_END} - $r->{TARGET_START} );

                    $primers{$this_primer}{read_length} = $r->{PRIMER_READ_LENGTH};

                    my @regions;                    
                    while ( $r and $r->{PLATE_NAME} eq $result{plate_name}
                                and lc($r->{WELL_NAME}) eq $result{well_name}
                                    and $r->{DESIGN_ID} == $result{design_id}
                                        and $r->{PRIMER_NAME} eq $this_primer ) {
                        my $pass_or_fail = $r->{REGION_PASS} ? 'pass' : 'fail';
                        push @regions, "$r->{REGION_NAME}: $r->{REGION_MATCH_COUNT}/$r->{REGION_LENGTH} ($pass_or_fail)";
                        $r = $sth->fetchrow_hashref;
                    }
                    $primers{$this_primer}{regions} = join( q{, }, @regions );
                }
                my @valid_primers = sort { $a cmp $b } grep { $primers{$_}->{pass} } keys %primers;
                $result{valid_primers}       = \@valid_primers;
                $result{num_valid_primers}   = scalar @valid_primers;
                $result{score}               = sum( 0, map $_->{score}, values %primers );
                $result{valid_primers_score} = sum( 0, map $primers{$_}->{score}, @valid_primers );

                while ( my ( $primer_name, $primer ) = each %primers ) {
                    $result{ $primer_name . '_pass' }                = $primer->{pass};
                    $result{ $primer_name . '_critical_regions' }    = $primer->{regions};
                    $result{ $primer_name . '_target_align_length' } = $primer->{target_align_length};
                    $result{ $primer_name . '_score' }               = $primer->{score};
                    $result{ $primer_name . '_features' }            = $primer->{features};
                    $result{ $primer_name . '_read_length' }         = $primer->{read_length};
                }

                #this plate/well combo is complete, so we can safely remove it,
                #we do this to make checking for wells without any test results below easier
                #we cant simply delete the entry from read_length_for as some wells have multiple entries.
                $processed{ $plate_name }{ $well_name } = 1;

                push @results, \%result;
            }
        }
    );

    # Merge in the number of primer reads (this has to be done in a
    # separate loop to catch wells with primer reads but no test
    # results)
    
    #we only do this for results not processed above, as a last resort.

    for my $plate_name ( keys %read_length_for ) {
        for my $well_name ( keys %{ $read_length_for{ $plate_name } } ) {
            #only do ones that didnt have test results
            next if exists $processed{ $plate_name }{ $well_name };

            push @results, {
                plate_name          => $plate_name,
                well_name           => $well_name,
                well_name_384       => $read_length_for{ $plate_name }{ $well_name }{ well_name_384 },
                num_reads           => $read_length_for{ $plate_name }{ $well_name }{ num_reads },
                num_valid_primers   => 0,
                valid_primers_score => 0,
                map { $_ . '_read_length' => $read_length_for{$plate_name}{$well_name}{primers}{$_} } 
                    keys %{ $read_length_for{$plate_name}{$well_name}{primers} }
            };
        }
    }

    @results = sort {
        $a->{plate_name} cmp $b->{plate_name}
            || lc($a->{well_name}) cmp lc($b->{well_name})
                || $b->{num_valid_primers} <=> $a->{num_valid_primers}
                    || $b->{valid_primers_score} <=> $a->{valid_primers_score};        
    } @results;
    
    return ( $qc_run, \@results  );
}

sub get_vector_stage {
    my ( $qc_run ) = @_;

    my $profile_name = $qc_run->profile;

    my $profile = HTGT::QC::Config->new->profile( $profile_name );

    return $profile->vector_stage;
}

#called for es cell runs only
sub combine_ABRZ_plates {
    my ( $read_length_for ) = @_;

    my %combined;
    for my $plate_name ( keys %{ $read_length_for } ) {
        my $plate_name_stem = $plate_name;
        my $plate_type;

        if ( $plate_name =~ /_[ABRZ]_\d$/ ) {
            ( $plate_name_stem, $plate_type ) = $plate_name =~ /^(.+)_([ABRZ])_\d$/;
        }

        for my $well_name ( keys %{ $read_length_for->{$plate_name} } ) {
            my $num_reads;

            #extract the specific primer information into our new hash, under its new name
            for my $primer ( keys %{ $read_length_for->{$plate_name}{$well_name}{primers} } ){
                my $primer_name = $primer;
                $primer_name = $plate_type . '_' . $primer if $plate_type; #new name

                #transfer the primer read length over, split to two lines as it was too long.
                my $read_length = $read_length_for->{$plate_name}{$well_name}{primers}{$primer};
                $combined{$plate_name_stem}{$well_name}{primers}{$primer_name} = $read_length;

                $num_reads++; #we need the number of primers
            }

            $combined{$plate_name_stem}{$well_name}{num_reads} = $num_reads;

            #no 384 plate name as es cell runs don't have them
        }
    }

    return \%combined;
}

sub get_merged_data {
    #we expect two hashrefs.
    my ( $map, $read_length_for ) = @_;

    my %merged_data;

    #attempt to find any different plates that share the same well name.
    #if they do, the primers and number of reads must be merged into a
    #single entry in the hash using the new plate name (generated from the plate map). 
    #we have to do this because the qc test results table stores the NEW plate name,
    #but all the sequencing reads retain the old, unmapped one. so when comparing
    #data from the two tables nothing matches.  

    for my $plate_name ( keys %{ $read_length_for } ) {
        for my $well_name ( keys %{ $read_length_for->{ $plate_name } }) {
            my $new_plate_name = $map->{ $plate_name }; #we need this to id this plate later

            #if this happens an entire plates worth of rows will be missing from the display.
            #it happened to me as my map had GRD090_Y_1 instead of GRD0090_Y_1 so be careful.
            unless ( $new_plate_name ) {
                WARN( "Plate map invalid, skipping $plate_name." );
                next;
            }

            #we've already done this one; each plate only has to be done once, as when we come across 
            #a plate we find ALL other plates with the same well name.
            next if exists $merged_data{ $new_plate_name }{ $well_name };

            #for each well see if any other projects have a well of the same name,
            #INCLUDING the very project we're checking against, as it is needed for the total.
            my @plates = grep { exists $read_length_for->{ $_ }{ $well_name } } keys %{ $read_length_for };

            #now iterate our list of plates with the same wells, merging their data
            for my $p_name ( @plates ) {
                my %old = %{ $read_length_for->{ $p_name }{ $well_name } }; #this makes it easier to read
                $merged_data{ $new_plate_name }{ $well_name }{ num_reads } += $old{ num_reads };
                #these should all be the same so overwriting shouldnt be a problem
                $merged_data{ $new_plate_name }{ $well_name }{ well_name_384 } = $old{ well_name_384 };

                #merge any new primers into our hash
                #primer reads with the same name are overwritten if the read length is larger.
                for ( keys %{ $old{ primers } } ) {
                    #skip if old val is set & smaller than current.
                    my $read_len = $merged_data{ $new_plate_name }{ $well_name }{ primers }{ $_ };
                    next if $read_len and $read_len > $old{ primers }{ $_ };

                    $merged_data{ $new_plate_name }{ $well_name }{ primers }{ $_ } = $old{ primers }{ $_ };
                }
            }
        }
    }

    return \%merged_data;
}

1;

__END__
