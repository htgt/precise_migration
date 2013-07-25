package HTGT::Utils::Recovery::StateUpdater;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-recovery/trunk/lib/HTGT/Utils/Recovery/StateUpdater.pm $
# $LastChangedRevision: 4289 $
# $LastChangedDate: 2011-03-11 16:29:41 +0000 (Fri, 11 Mar 2011) $
# $LastChangedBy: rm7 $

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';

use HTGT::DBFactory;
use HTGT::Utils::Recovery::GeneData;
use HTGT::Utils::Recovery::Constants qw( :state :limits $OLFACTORY_MARKER_RX );
use List::MoreUtils qw( all any uniq );
use Readonly;

=attr schema

B<HTGTDB> schema object (must be specified in the constructor).

=cut

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1
);

has commit => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 0
);

has gene_data => (
    is      => 'rw',
    isa     => 'HTGT::Utils::Recovery::GeneData',
    clearer => 'clear_gene_data',
);

has gene_status => (
    is         => 'rw',
    isa        => 'HTGTDB::GRGeneStatus',
    clearer    => 'clear_gene_status',
    lazy_build => 1,
);

has _gene_status_notes => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    traits  => [ 'Array' ],
    handles => {
        clear_gene_status_notes => 'clear',
        add_gene_status_note    => 'push',
        gene_status_notes       => 'elements',
    },
    default => sub { [] },
);

sub _build_gene_status {
    my $self = shift;

    my $gd = $self->gene_data
        or confess "gene_data not initialized";

    $self->schema->resultset( 'GRGeneStatus' )->find_or_new( { mgi_gene_id => $gd->mgi_gene_id } );    
}

=method update_all_genes

Find every gene in the pipeline with at least one KOMP_CSD or EUCOMM
project and call B<update_state_for_gene> for each gene.

=cut

sub update_all_genes {
    my $self = shift;
    my $wanted = shift || sub { 1 };

    my $genes_in_pipeline = $self->schema->storage->dbh->prepare( <<'EOT' );
select distinct project.mgi_gene_id
from project
join well_summary_by_di on well_summary_by_di.project_id = project.project_id
where ( project.is_komp_csd = 1 or project.is_eucomm = 1 )
EOT

    $genes_in_pipeline->execute;

    my $rc = 0;
    
    while ( my ( $mgi_gene_id ) = $genes_in_pipeline->fetchrow_array ) {
        next unless $wanted->( $mgi_gene_id );
        my $this_rc = $self->update_gene( $mgi_gene_id );
        $rc ||= $this_rc;
    }

    return $rc;    
}

=method update_gene( I<$mgi_gene_id> )

Find the current state of I<$mgi_gene_id> and update the GR* tables to
reflect the current state.

=cut

sub update_gene {
    my ( $self, $mgi_gene_id ) = @_;

    my $rc = 0;
    
    $self->schema->txn_do(
        sub {
            Log::Log4perl::MDC->put( 'mgi_gene_id', $mgi_gene_id );

            eval {
                my $gene_data = HTGT::Utils::Recovery::GeneData->new(
                    schema      => $self->schema,
                    mgi_gene_id => $mgi_gene_id
                );

                $self->gene_data( $gene_data );

                my $initial_state = $self->gene_status->state || 'unknown';
    
                Log::Log4perl::MDC->put( initial_state => $initial_state );
        
                $self->set_current_state_for_gene;
            };
            if ( $@ ) {
                $self->log->error( $@ );
                $rc = 2;            
            }
            
            $self->clear_gene_data;
            $self->clear_gene_status;
            $self->clear_gene_status_notes;
    
            Log::Log4perl::MDC->remove();

            $self->schema->txn_rollback unless $self->commit;
        }
    );

    return $rc;
}

#
# Main Processing
#

sub set_current_state_for_gene {
    my $self = shift;

    $self->check_projects_ignore_gene;
}

sub check_projects_ignore_gene {
    my $self = shift;
    
    if ( $self->gene_data->has_project_with_ignore_gene_status ) {
        $self->log->info( "gene has project with status indicating that the gene should be ignored" );
        my ( $p ) = ( $self->gene_data->projects_with_ignore_gene_status )[0];
        $self->add_gene_status_note( $p->status->name );
        $self->set_state_no_recovery;
    }
    else {
        $self->log->info( "gene has no project with status indicating that the gene should be ignored" );
        $self->check_active_projects;
    }
}

sub check_active_projects {
    my $self = shift;
    
    if ( $self->gene_data->has_active_projects ) {
        $self->log->info( "gene has at least 1 active KOMP_CSD or EUCOMM project" );
        $self->check_olfr_symbol;
    }
    else {
        $self->log->info( "gene has no active KOMP_CSD or EUCOMM projects" );
        $self->add_gene_status_note( 'No active KOMP_CSD or EUCOMM projects' );
        $self->set_state_no_recovery;
    }
}

sub check_olfr_symbol{
    my $self = shift;

    if ( ( $self->gene_data->mgi_gene->marker_symbol || '' ) =~ m/$OLFACTORY_MARKER_RX/ ) {
        $self->log->info( "gene is an olfactory or taste receptor" );
        $self->add_gene_status_note( "Olfactory and taste receptors excluded from recovery" );
        $self->set_state_no_recovery;
    }
    else {
        $self->log->info( "gene is not an olfactory or taste receptor" );
        $self->check_epd_distribute_count;
    }    
}

sub check_epd_distribute_count {
    my $self = shift;

    my $epd_count = $self->gene_data->epd_distribute_count;
    
    if ( $epd_count > $EPD_DISTRIBUTE_THRESHOLD ) {
        $self->log->info( "gene has $epd_count distributable EPDs" );
        $self->add_gene_status_note( "more than $EPD_DISTRIBUTE_THRESHOLD distributable EPDs" );
        $self->set_state_no_recovery;
    }
    else {
        $self->log->info( "gene has insufficient distributable EPD wells" );
        $self->check_redesign_requested;
    }
}

sub check_redesign_requested {
    my $self = shift;

    if ( $self->gene_data->has_redesign_requested_project ) {
        $self->log->info( "gene has a project with status redesign requested" );
        $self->add_gene_status_note( "Project with status redesign requested" );
        $self->set_state_rdr_c;
    }
    else {
        $self->log->info( "gene has no projects with status redesign requested" );
        $self->check_recovery_design;
    }
}

sub check_recovery_design {
    my $self = shift;

    if ( $self->gene_data->has_redesign_recovery_project ) {
        $self->log->info( "gene has a recovery design" );
        $self->add_gene_status_note( "Gene has recovery design ready to order" );
        $self->set_state_rdr;
    }
    else {
        $self->log->info( "Gene has no recovery design ready to order" );
        $self->check_design_wells;        
    }
}

sub check_design_wells {
    my $self = shift;

    if ( $self->gene_data->has_design_wells ) {
        $self->log->info( "gene has at least one design well" );
        $self->check_design_bacs;
    }
    else {
        $self->log->info( "gene has no design wells" );
        $self->add_gene_status_note( "no design wells" );
        $self->set_state_no_recovery;
    }    
}

sub check_design_bacs {
    my $self = shift;

    if ( $self->gene_data->has_bl6_design_wells ) {
        $self->log->info( "gene has at least one design well with Bl6/J BAC strain" );
        $self->check_distributable_targvecs;        
    }
    else {
        $self->log->info( "gene has no design wells with Bl6/J BAC strain" );
        $self->add_gene_status_note( "no design wells with Bl6/J BAC strain" );
        $self->set_state_rdr_c;        
    }
}

sub check_distributable_targvecs {
    my $self = shift;

    if ( $self->gene_data->has_distributable_targvecs ) {
        $self->log->info( "gene has at least one distributable targeting vector" );
        $self->check_targvec_promoter_status;
    }
    else {
        $self->log->info( "gene has no distributable targeting vectors" );
        #$self->check_targvec_primers;
        $self->check_qc_done_pcs_wells;        
    }
}

# sub check_targvec_primers {
#     my $self = shift;

#     if ( $self->gene_data->has_fail_targvec_with_good_primers ) {
#         $self->log->info( "gene has failed targvec with good primers" );
#         $self->check_not_in_recovery;
        
#     }
#     else {
#         $self->log->info( "gene has no failed targvec with good primers" );
#         $self->check_qc_done_pcs_wells;
#     }
# }

# sub check_not_in_recovery {
#     my $self = shift;

#     if ( $self->gene_data->has_gwr_wells or $self->gene_data->has_rdr_wells ) {
#         $self->log->info( "gene is already on a gateway/redesign/resynthesis recovery plate" );
#         $self->check_qc_done_pcs_wells;
#     }
#     else {
#         $self->log->info( "gene does not appear on a gateway/redesign/resynthesis recovery plate" );
#         $self->set_state_reseq_c;
#     }
# }

sub check_qc_done_pcs_wells {
    my $self = shift;

    if ( $self->gene_data->has_qc_done_pcs_wells ) {
        $self->log->info( "gene has at least one PCS well marked 'qc_done'" );
        $self->check_pcs_loxp_primer;
    }
    else {
        $self->log->info( "gene has no PCS wells marked 'qc_done'" );
        $self->check_redesign_recovery;
    }
}

sub check_redesign_recovery {
    my $self = shift;

    if ( $self->gene_data->has_rdr_wells ) {
        $self->log->info( "Gene has redesign recovery wells" );
        my @plates = uniq map $_->plate->name, $self->gene_data->rdr_wells;
        $self->add_gene_status_note( "Recovery design on plate(s) " . join( q{, }, sort @plates ) );
        $self->set_state_rdr;        
    }
    else {
        $self->log->info( "Gene has no active redesign recovery wells" );
        $self->set_state_no_pcs_qc;
    }   
}

sub check_pcs_loxp_primer {
    my $self = shift;

    if ( $self->gene_data->has_pcs_well_with_loxp_primer ) {
        $self->log->info( "gene has PCS well with loxP primer" );
        $self->check_pcs_cassette_primer;
    }
    else {
        $self->log->info( "gene has no PCS well with loxP primer" );
        $self->add_gene_status_note( 'no PCS well with loxP primer' );
        $self->check_rdr_status();
    }
}

sub check_pcs_cassette_primer {
    my $self = shift;

    if ( $self->gene_data->has_pcs_well_with_loxp_and_cassette_primer ) {
        $self->log->info( "gene has PCS well with loxP and cassette primer" );
        $self->add_gene_status_note( 'valid loxP and cassette primer' );
        $self->check_gwr_status;
    }
    else {
        $self->log->info( "gene does not have PCS well with loxP and cassette primer" );
        $self->add_gene_status_note( 'valid loxP primer only' );
        $self->check_gwr_status;
    }
}

sub check_targvec_promoter_status {
    my $self = shift;

    if ( $self->gene_data->needs_promoter_but_no_targvec_with_promoter ) {
        $self->log->info( "gene needs cassette with a promoter, but no targvec with promoter" );
        $self->add_gene_status_note( 'gene not suitable for promoterless targeting, but no targeting vectors with promoter' );
        $self->check_qc_done_pcs_wells;
    }
    else {
        $self->log->info( "gene has distributable targvec with appropriate cassette" );
        $self->check_acr_status;
    }
}

#
# Gateway Recovery
#

sub check_gwr_status {
    my $self = shift;

    if ( $self->gene_data->has_gwr_wells ) {
        $self->log->info( "gene has gateway_recovery wells" );
        $self->check_gwr_qc_done;
    }
    else {
        $self->log->info( "gene has no gateway_recovery wells" );
        $self->set_state_gwr_c;
    }
}

sub check_gwr_qc_done {
    my $self = shift;

    if ( all { defined $_->well_data_value( 'pass_level' ) } $self->gene_data->gwr_wells ) {
        $self->log->info( "all gwr wells have pass_level marked" );
        $self->check_gwr_stage;
    }
    else {
        $self->log->info( "not all gwr wells have pass_level marked" );
        $self->add_gene_status_note( 'gwr QC pending' );
        $self->set_state_gwr;
    }
}

sub check_gwr_stage {
    my $self = shift;

    if ( any { $_->plate->name =~ qr/^HTGR04/o } $self->gene_data->gwr_wells ) {
        $self->log->info( "gene appears on a HTGR04000 series plate" );
        $self->add_gene_status_note( 'HTGR04000 QC fail' );
        $self->check_rdr_status;
    }
    else {
        $self->log->info( "gene does not appear on a HTGR04000 series plate" );
        $self->set_state_gwr_c;
    }
}

#
# Alternate Clone Recovery
#
    
sub check_acr_status {
    my $self = shift;

    if ( $self->gene_data->has_acr_wells ) {
        $self->log->info( "gene has alternate_clone_recovery wells" );
        $self->check_acr_qc_done;
    }
    else {
       $self->log->info( "gene has no alternate_clone_recovery wells" );
       $self->check_acr_alternates;
   }
}

sub check_acr_qc_done {
    my $self = shift;

    if ( all { defined } $self->gene_data->acr_well_pass_levels ) {        
        $self->log->info( "all acr wells have pass_level marked" );
        $self->check_acr_sequence_qc;
    }
    else {
        $self->log->info( "not all acr wells have pass_level marked" );
        $self->add_gene_status_note( 'sequencing QC pending' );
        $self->set_state_acr;
    }
}

sub check_acr_sequence_qc {
    my $self = shift;
    
    if ( $self->gene_data->has_acr_wells_with_qc_pass ) {
        $self->log->info( "acr wells with sequencing QC pass found" );
        $self->check_acr_dna_qc_done;
    }
    else {
        $self->log->info( "all acr wells failed sequencing QC" );
        $self->check_fresh_acr_candidates;
    }
}

sub check_acr_dna_qc_done {
    my $self = shift;

    if ( all { defined } $self->gene_data->acr_well_dna_statuses ) {
        $self->log->info( "all acr wells have DNA status marked" );
        $self->check_acr_dna_qc;
    }
    else {
        $self->log->info( "not all acr wells have DNA status marked" );
        $self->add_gene_status_note( 'DNA QC pending' );        
        $self->set_state_acr;
    }
}

sub check_acr_dna_qc {
    my $self = shift;

    if ( $self->gene_data->has_acr_wells_with_dna_pass ) {
        $self->log->info( "acr wells with DNA pass found" );
        # $self_>check_acr_epd_attempts;
        $self->add_gene_status_note( 'acr wells with DNA pass' );
        $self->set_state_acr;
    }
    else {
        $self->log->info( "no acr wells with DNA pass found" );
        $self->check_fresh_acr_candidates;        
    }
}

sub check_fresh_acr_candidates {
    my $self = shift;

    my $latest_acr_date = $self->gene_data->latest_acr_attempt_date;

    my $latest_targvec_date = $self->gene_data->latest_distributable_targvec_date;

    if ( $latest_acr_date > $latest_targvec_date ) {
        $self->log->info( "latest acr attempt was more recent than latest distributable targvec" );
        $self->add_gene_status_note( 'alternate clone recovery failed' );
        $self->check_qc_done_pcs_wells;
    }
    else {
        $self->log->info( "distributable targvecs generated since last alternate clone recovery attempt" );
        $self->check_acr_alternates;
    }    
}

sub check_acr_alternates {
    my $self = shift;

    if ( $self->gene_data->has_alternate_clones ) {
        $self->log->info( "gene has alternate clones" );
        $self->set_state_acr_c;
    }
    else {
        $self->log->info( "gene has no alternate clones" );
        $self->check_acr_chosen;
    }
}

sub check_acr_chosen {
    my $self = shift;

    if ( $self->gene_data->has_chosen_for_recovery ) {
        $self->log->info( "gene has chosen clones suitable for alt clone recovery" );
        $self->set_state_acr_c_no_alt;
    }
    else {
        $self->log->info( "gene has no chosen clones suitable for alt clone recovery" );
        $self->add_gene_status_note( "found no suitable targvecs for alt clone recovery" );
        $self->check_qc_done_pcs_wells;
    }    
}

#sub check_acr_epd_attempts {
#    my $self = shift;
#
#    if ( $self->gene_data->has_acr_wells_with_eps ) {
#        $self->log->info( "DNA pass acr wells have EPs" );
#        # XXX TODO: what next?
#        $self->add_gene_status_note( 'DNA pass acr wells have EPs: analysis incomplete' );
#        $self->set_state_acr;
#    }
#    else {
#        $self->log->info( "DNA pass acr wells have no EPs" );
#        $self->add_gene_status_note( 'pending electroporation' );
#        $self->set_state_acr;
#    }
#}

#
# Redesign / resynthesis recovery
#

sub check_rdr_status {
    my $self = shift;

    if ( $self->gene_data->has_rdr_wells ) {
        $self->log->info( "gene has rdr wells" );
        $self->check_rdr_progress;
    }
    else {
        $self->log->info( "gene has no rdr wells" );
        $self->set_state_rdr_c;
    }
}

sub check_rdr_progress {
    my $self = shift;

    # XXX TODO: how do we check whether or not we need to initiate a 2nd round
    # of redesign/resynthesis?

    
    $self->set_state_rdr;
}


#
# Methods to record auxiliary data and set state
#

sub set_state_acr_c {
    my $self = shift;

    my $gs = $self->set_state( $ST_ACR_C );

    $gs->acr_candidate_chosen_rs->delete;
    
    for my $c ( $self->gene_data->chosen_clones ) {
        $gs->acr_candidate_chosen_rs->create(
            {
                chosen_well_id    => $c->{chosen_well}->well_id,
                chosen_clone_name => $c->{chosen_clone_name},
                child_plates      => $c->{child_plates}
            }
        );
    }

    $gs->acr_candidate_alternates_rs->delete;

    for my $a ( $self->gene_data->alternate_clones ) {
        $gs->acr_candidate_alternates_rs->create(
            {
                alt_clone_well_id => $a->well_id
            }
        );
    }
    
}

sub set_state_acr_c_no_alt {
    my $self = shift;

    my $gs = $self->set_state( $ST_ACR_C_NO_ALT );

    $gs->acr_candidate_alternates_rs->delete;
    $gs->acr_candidate_chosen_rs->delete;

    for my $c ( $self->gene_data->chosen_for_recovery ) {
        $gs->acr_candidate_chosen_rs->create(
            {
                chosen_well_id    => $c->{chosen_well}->well_id,
                chosen_clone_name => $c->{chosen_clone_name},
                child_plates      => $c->{child_plates}
            }
        );
    }    
}

sub set_state_acr {
    my $self = shift;

    my $gs = $self->set_state( $ST_ACR );

    $gs->in_acr_rs->delete;
    
    for my $a ( $self->gene_data->acr_wells ) {
        $gs->in_acr_rs->create(
            {
                acr_well_id => $a->well_id
            }
        );
    }
    
}

# sub set_state_reseq_c {
#     my $self = shift;

#     my $gs = $self->set_state( $ST_RESEQ_C );

#     $gs->reseq_candidates_rs->delete;

#     for my $r ( $self->gene_data->fail_targvecs_with_good_primers ) {
#         $self->log->debug( "Inserting reseq_c candidate targvec well $r->{well}" );
#         $gs->reseq_candidates_rs->create(
#             {
#                 targvec_well_id => $r->{well}->well_id,
#                 valid_primers   => join( q{,}, keys %{ $r->{primers} } )
#             }
#         );
#     }    
# }

sub set_state_gwr_c {
    my $self = shift;

    my $gs = $self->set_state( $ST_GWR_C );

    $gs->gwr_candidates_rs->delete;

    my $pcs_well = $self->gene_data->best_valid_pcs_well
        or return;
    
    $gs->gwr_candidates_rs->create(
        {
            pcs_well_id   => $pcs_well->well_id,
            valid_primers => join( q{,}, keys %{ $self->gene_data->get_pcs_well_valid_primers( $pcs_well->well_id ) } )
        }
    );
}

sub set_state_gwr {
    my $self = shift;

    my $gs = $self->set_state( $ST_GWR );

    $gs->in_gwr_rs->delete;

    for my $g ( $self->gene_data->gwr_wells ) {
        $gs->in_gwr_rs->create(
            {
                gwr_well_id => $g->well_id
            }
        );
    }
}

sub set_state_rdr_c {
    my $self = shift;

    my $gs = $self->set_state( $ST_RDR_C );

    $gs->rdr_candidates_rs->delete;

    for my $d ( $self->gene_data->design_wells ) {
        $gs->rdr_candidates_rs->create(
            {
                design_well_id => $d->well_id
            }
        );        
    }
}

sub set_state_rdr {
    my $self = shift;

    my $gs = $self->set_state( $ST_RDR );

    $gs->in_rdr_rs->delete;

    for my $d ( $self->gene_data->rdr_wells ) {
        $gs->in_rdr_rs->create(
            {
                rdr_well_id => $d->well_id
            }
        );
    }
}

sub set_state_no_pcs_qc {
    my $self = shift;

    $self->set_state( $ST_NO_PCS_QC );
}

sub set_state_no_recovery {
    my $self = shift;

    my $gs = $self->set_state( $ST_NONE );

    $gs->in_rdr_rs->delete;
    $gs->in_gwr_rs->delete;    
    $gs->in_acr_rs->delete;
    
    $gs->rdr_candidates_rs->delete;
    $gs->gwr_candidates_rs->delete;
    $gs->acr_candidate_chosen_rs->delete;
    $gs->acr_candidate_alternates_rs->delete;
}

#
# Helper methods
#

sub set_state {
    my $self  = shift;
    my $state = shift;

    $self->log->info( "setting state to '$state'" );

    my $gs = $self->gene_status;

    my $cur_state = $gs->state || '';
    my $cur_note = $gs->note || '';

    my $note = join( q{, }, $self->gene_status_notes ) || '';        
    
    unless ( $cur_state eq $state and $cur_note eq $note ) {
        
        if ( $gs->in_storage ) {
            $gs->delete; # Oracle will cascade the deletion to auxiliary tables
        }
        
        $gs = $self->schema->resultset( 'GRGeneStatus' )->create(
            {
                mgi_gene_id => $self->gene_data->mgi_gene_id,
                state       => $state,
                note        => $note,                
            }
        );

        $self->gene_status( $gs );
    }
    
    return $gs;
}   

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Foo - Perl extension for blah blah blah

=head1 SYNOPSIS

   use Foo;
   blah blah blah

=head1 DESCRIPTION

Stub documentation for Foo, 

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ray Miller, E<lt>rm7@hpgen-1-14.internal.sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
