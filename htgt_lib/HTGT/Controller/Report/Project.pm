package HTGT::Controller::Report::Project;

=head1 Name

HTGT::Controller::Report::Project

Utility module to house all of the methods to do with project/construct reporting.

=head1 Author

Darren Oakley <do2@sanger.ac.uk>

=head1 Methods

=cut

use strict;
use warnings;

=head2 Utility Methods for 'HTGT::Controller::Report::project_gene_report'

=head3 get_project_status_info

Helper method for project_gene_report to get/stash info info about the project_status table - 
used in drawing the pipeline progress bar.

=head3 get_regeneron_info

Helper method for project_gene_report to get/stash the velocigene id for a gene if we have a regeneron project.

=head3 get_vector_seq_features

Helper method for project_gene_report to get/stash the Bioperl SeqIO object for a given construct.

=head3 get_design_info

Helper method for project_gene_report to get/stash information on the design for a given construct.

=head3 get_es_cell_info

Helper method for project_gene_report to get/stash distributable es cell info.

=head3 get_display_features

Helper method to get the display_features linked to a design - this is used for displaying 
a link to ensembl for the floxed exon(s).

=cut

sub get_project_status_info {
    my ( $self, $c ) = @_;
    
    my $status_dict;
    my $stage_upper_threshold;
    my $stage_lower_threshold;
    
    my @statuses    = $c->model('HTGTDB::ProjectStatus')->search({},{ order_by => { -asc  => 'order_by' } });
    my @statusesinv = $c->model('HTGTDB::ProjectStatus')->search({},{ order_by => { -desc => 'order_by' } });
    
    foreach my $status ( @statuses ) {
        $status_dict->{ $status->name } = $status->order_by;
        $stage_upper_threshold->{ $status->stage || '' } = $status->order_by;
    }
    
    foreach my $status ( @statusesinv ) {
        $stage_lower_threshold->{ $status->stage || '' } = $status->order_by;
    }
    
    $c->stash->{status_dict} = $status_dict;
    $c->stash->{stage_upper_threshold} = $stage_upper_threshold;
    $c->stash->{stage_lower_threshold} = $stage_lower_threshold;
    
}

sub get_display_features {
    my ( $self, $c ) = @_;
    
    # Retrieve the project info...
    my $project = $c->stash->{project};
    
    if( $project->design_id ) {
        my $features = $project->design->validated_display_features;
        
        if ($features->{G5} and $features->{G3} ) {
            if ( $features->{G5}->feature_strand == 1 ) {
                $c->stash->{design_chr_name}  = $features->{G5}->chromosome->name;
                $c->stash->{design_start_pos} = $features->{G5}->feature_start - 100;
                $c->stash->{design_end_pos}   = $features->{G3}->feature_end + 100;
            } else {
                $c->stash->{design_chr_name}  = $features->{G5}->chromosome->name;
                $c->stash->{design_start_pos} = $features->{G3}->feature_start - 100;
                $c->stash->{design_end_pos}   = $features->{G5}->feature_end + 100;
            }
        } else {
            for ( qw( G5 G3 ) ) {
                $c->stash->{error_msg} .= "$_ (display feature) missing for design " . $project->design_id;
            }
        }
        
        if ( $project->design->start_exon ) {
            $c->stash->{design_start_exon} = $project->design->start_exon->primary_name
        }
        if ( $project->design->end_exon ) {
            $c->stash->{design_end_exon}   = $project->design->end_exon->primary_name
        }        
    } else {
        $c->stash->{error_msg} .= " Design data missing for " . $project->targvec_plate_name . "_" . $project->targvec_well_name;
    }
}

sub get_vector_seq_features {
    my ( $self, $c ) = @_;
    
    # Retrieve the project info...
    my $project = $c->stash->{project};
    
    eval{
    # get two sets of the allele seq and features    
    my $conditional_allele_seq   = $project->design->allele_seq( $project->cassette );
    my $targeted_trap_allele_seq = $project->design->allele_seq( $project->cassette, 1 );
    
    $c->stash->{vector_seq_features} = &get_features( $conditional_allele_seq );
    $c->stash->{targeted_trap_vector_seq_features} = &get_features( $targeted_trap_allele_seq );    
    };
    $c->log->error("Failed to create allele seq: ".$@) if ($@);
    
}
    
sub get_features {
    my ( $seq ) = @_;

    my @features;
    
    foreach my $feat ( sort { $a->start <=> $b->start } $seq->get_SeqFeatures ) {
        if ( my @note = $feat->annotation->get_Annotations('note') ) {
            my $name = join( "", @note );
            if ( $feat->primary_tag eq 'exon' ) {
                if ( $name =~ /(OTTMUSE|ENSMUSE)(\d+)/ ) {
                    $name = $1.$2;
                    push( @features, { type => 'exon', name => $name, start => $feat->start, end => $feat->end } );
                }
            } elsif ( $feat->primary_tag eq 'rcmb_primer' ) {
                if ( $name =~ /(G5|G3)/) {
                    push( @features, { type => 'rcmb_primer', name => $name, start => $feat->start, end => $feat->end, seq => $feat->seq } );
                } elsif ( $name =~ /U5/ ) {
                    push( @features, { type => 'rcmb_primer', name => $name, start => $feat->start, end => $feat->end, seq => $feat->seq } );
                    push( @features, { type => 'cassette', start => $feat->start, end => $feat->end, seq => $feat->seq } );
                } elsif ( $name =~ /D5/ ) {
                    push( @features, { type => 'loxP', start => $feat->start, end => $feat->end, seq => $feat->seq } );
                } else {
                    push( @features, { type => 'rcmb_primer', name => $name, start => $feat->start, end => $feat->end, seq => $feat->seq } );
                }
            } elsif ( $feat->primary_tag eq 'LRPCR_primer' ) {
                push( @features, { type => 'lrpcr_primer', name => $name, start => $feat->start, end => $feat->end, seq => $feat->seq } );
            } elsif ( $feat->primary_tag eq 'primer_bind' ) {
                push( @features, { type => 'primer_bind', name => $name, start => $feat->start, end => $feat->end, seq => $feat->seq } );
            }
        }
    }
    
    return \@features;
}

sub get_design_info {
    my ( $self, $c ) = @_;
    
    # Retrieve the project info...
    my $project = $c->stash->{project};
    
    if ( ! defined $project->bac ) {
        if ($project->design_instance) {
           if ( scalar($project->design_instance->design_instance_bacs) > 0 ) {
              $c->stash->{design_bac} = $project->design_instance->design_instance_bacs->first->bac->clone_lib->library;
           }
        }
    }
    
}

sub get_es_cell_info {
    my ( $self, $c ) = @_;
    
    # Retrieve the project info...
    my $project = $c->stash->{project};
    
    # Collect the EPD entries from WellSummaryByDI
    
    my $allele_rs = $c->model('HTGTDB::WellSummaryByDI')->search(
        { project_id => $project->project_id },
        { distinct => '1' }
    );
    
    my @alleles = $allele_rs->search( 
        [ { epd_distribute => 'yes' }, { targeted_trap => 'yes' } ], 
        { order_by => { -asc => 'epd_well_name' } }
    )->all();    
    $c->stash->{alleles} = \@alleles;
    
    # Now do some counting etc if we have some EPD's...
    if ( scalar( @alleles ) > 0 ) {
        
        ##
        ## Get colony counts...
        ##
        
        my $colonies_picked;
        my $colonies_picked_rs = $allele_rs->search( {}, { columns => [ 'ep_well_id', 'colonies_picked' ] } );
        while (my $res = $colonies_picked_rs->next) { $colonies_picked += $res->colonies_picked; }
        
        my $epd_count = $allele_rs->search( {}, { columns => [ 'epd_well_id' ] } )->count;
        
        # epd_pass_count includes conditional KO and deletion clones
        my $epd_pass_count = $allele_rs->search( { epd_distribute => 'yes' }, { columns => [ 'epd_well_id' ] } )->count;
        
        my $targeted_trap_count = $allele_rs->search( { targeted_trap => 'yes' }, { columns => [ 'epd_well_id' ] } )->count;
        
        # get the counts for deletion alleles
        my $deletion_allele_count;
        
        foreach my $allele (@alleles){
            if ($allele->design_instance->design->is_deletion){
                $deletion_allele_count++;
            }
        }
        
        $c->stash->{colonies_picked} = $colonies_picked;
        $c->stash->{epd_count} = $epd_count;
        
        $c->stash->{conditional_allele_count} =  $epd_pass_count - $deletion_allele_count;
        $c->stash->{targeted_trap_count} = $targeted_trap_count;
        $c->stash->{deletion_allele_count} = $deletion_allele_count;
        
        ##
        ## Figure out ship dates for HZM and CSD...
        ##
        
        # Get the plates represented by the EPD wells...
        my @epd_plates;
        foreach my $epd_well ( @alleles ) { push( @epd_plates, $epd_well->epd_plate_name );}
        
        # Get the FP plates from each EPD plate...
        my @fp_plate_ids;
        foreach my $epd_plate_name ( @epd_plates ) {
            
            my $epd_plate = $c->model('HTGTDB::Plate')->find( { name => $epd_plate_name } );
            if ( $epd_plate and $epd_plate->child_plates ) {
              foreach my $fp_plate ( $epd_plate->child_plates ) { push( @fp_plate_ids, $fp_plate->plate_id ); }
            }
            
        }
        
        if ( scalar(@fp_plate_ids) > 0 ) {
            
            # Now get the ship dates...
            my $plate_data_rs = $c->model('HTGTDB::PlateData')->search( 
                { plate_id  => \@fp_plate_ids, data_type => { 'like' => 'ship_date_%' } }, 
                { distinct => ['data_type','data_value'] }
            );

            my %ship_dates;
            while ( my $plate_data = $plate_data_rs->next ) {
                push( @{$ship_dates{ $plate_data->data_type }}, $plate_data->data_value );
            }

            # If we have more than one ship date - report the EARLIEST for each centre...
            if ( $ship_dates{'ship_date_hzm'} ) {
                my @dates = sort { $a cmp $b } @{ $ship_dates{'ship_date_hzm'} };
                $c->stash->{hzm_date} = $dates[0];
            }
            if ( $ship_dates{'ship_date_csd'} ) {
                my @dates = sort { $a cmp $b } @{ $ship_dates{'ship_date_csd'} };
                $c->stash->{csd_date} = $dates[0];
            }
            
        }
        
    }
    
}

=head1 License

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
