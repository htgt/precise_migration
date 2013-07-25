package HTGTDB::WellSummary;
use strict;

=head1 AUTHOR

Dan Klose <dk3@sanger.ac.uk>

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('well_summary');
__PACKAGE__->add_columns(
    qw/
      project_id
      build_gene_id
      gene_id
      design_instance_id
      design_plate_name
      design_well_name
      design_well_id
      design_design_instance_id
      bac
      pcs_plate_name
      pcs_well_name
      pcs_well_id
      pcs_design_instance_id
      pc_qctest_result_id
      pc_pass_level
      pcs_distribute
      pgdgr_plate_name
      pgdgr_well_name
      pgdgr_well_id
      pgdgr_design_instance_id
      pg_qctest_result_id
      pg_pass_level
      cassette
      backbone
      pgdgr_distribute
      ep_plate_name
      ep_well_name
      ep_well_id
      ep_design_instance_id
      es_cell_line
      colonies_picked
      total_colonies
      epd_plate_name
      epd_well_name
      epd_well_id
      epd_design_instance_id
      epd_qctest_result_id
      epd_pass_level
      epd_distribute
      allele_name
      /
);
__PACKAGE__->set_primary_key( qw(project_id design_instance_id design_well_id pcs_well_id pgdgr_well_id ep_well_id epd_well_id) );
__PACKAGE__->belongs_to( gene            => 'HTGTDB::GnmGene',          'gene_id' );
__PACKAGE__->belongs_to( build_gene      => 'HTGTDB::GnmGeneBuildGene', 'build_gene_id' );
__PACKAGE__->belongs_to( design_instance => 'HTGTDB::DesignInstance',   'design_instance_id' );
__PACKAGE__->belongs_to( design_well     => 'HTGTDB::Well',             'design_well_id' );
__PACKAGE__->belongs_to( pcs_well        => 'HTGTDB::Well',             'pcs_well_id' );
__PACKAGE__->belongs_to( pgdgr_well      => 'HTGTDB::Well',             'pgdgr_well_id' );
__PACKAGE__->belongs_to( epd_well        => 'HTGTDB::Well',             'epd_well_id' );


__PACKAGE__->add_unique_constraint( unique_epd_well_id => [qw/epd_well_id/] );

sub get_distribute_counts_by_design_plate {
    my ( $self, $c ) = @_;

    my $sql = qq[
              select
              distinct
                project.project_id,
                project.is_eucomm,
                project.is_komp_csd,
                project.is_eutracc,
                project.is_norcomm,
                well_summary.design_plate_name,
                well_summary.design_well_name,
                well_summary.PGDGR_PLATE_NAME,
                well_summary.PGDGR_WELL_NAME,
                well_summary.PGDGR_DISTRIBUTE,
                well_summary.PG_PASS_LEVEL
              from 
                well_summary, 
                project
              where 
                project.project_id = well_summary.project_id 
          ];

    my $return_ref = {};

    my $sth = $c->model('HTGTDB')->storage->dbh->prepare($sql);

    $sth->execute();

    while ( my $result = $sth->fetchrow_hashref() ) {
        my $plate = $result->{DESIGN_PLATE_NAME};
        next unless $plate;

        my $project_id             = $result->{PROJECT_ID};
        my $well                   = $result->{DESIGN_WELL_NAME};
        my $pg_pass                = $result->{PG_PASS_LEVEL};
        my $tv_plate               = $result->{PGDGR_PLATE_NAME};
        my $distribute             = $result->{PGDGR_DISTRIBUTE};
        my $is_eucomm = $result->{IS_EUCOMM};
        my $is_norcomm = $result->{IS_NORCOMM};
        my $is_mgp = $result->{IS_MGP};
        my $is_komp_csd = $result->{IS_KOMP_CSD};
        my $is_eutracc = $result->{IS_EUTRACC};

        unless ( $is_eucomm || $is_komp_csd || $is_eutracc || $is_norcomm) {
            next;
            #die "project ".$project_id." is neither EUCOMM nor KOMP nor NorCOMM nor EUTRACC\n";
        }
        if ( $is_eucomm ) {
            $return_ref->{$plate}->{eucomm_count}++;
        }
        elsif ( $is_komp_csd ) {
            $return_ref->{$plate}->{komp_count}++;
        }
        elsif ( $is_eutracc ) {
            $return_ref->{$plate}->{eutracc_count}++;
        }
        elsif ( $is_norcomm) {
            $return_ref->{$plate}->{norcomm_count}++;
        }

        if ($tv_plate) {
            my $first_part = $tv_plate;
            if($tv_plate =~ /(\S+)_(\S+)/){
                $first_part = $1;
            }
            
            $return_ref->{$plate}->{main_tv_plates}->{$first_part} = 1;
            if ( $distribute && $distribute eq 'yes' ) {
                $return_ref->{$plate}->{wells}->{$well}->{main_distribute} = 1;
            }
        }
    }

    foreach my $plate_name ( sort keys %$return_ref ) {
        my $plate_ref = $return_ref->{$plate_name};
        my $eucomm_count = $return_ref->{$plate_name}->{eucomm_count};
        my $komp_count = $return_ref->{$plate_name}->{komp_count};
        my $norcomm_count = $return_ref->{$plate_name}->{norcomm_count};
        my $eutracc_count = $return_ref->{$plate_name}->{eutracc_count};
        
        my $plate_project;
        if($eucomm_count > 48){
            $plate_project = 'EUCOMM';
        }elsif($komp_count > 48){
            $plate_project = 'KOMP';
        }elsif($eutracc_count > 48){
            $plate_project = 'EUTRACC';
        }elsif($norcomm_count > 48){
            $plate_project = 'NorCOMM';
        } else {
            $plate_project = '??';
        }

        my $main_child_plates    = '';
        $c->log->debug(Data::Dumper->Dump([$return_ref->{$plate_name}->{main_tv_plates}]));
        if ( $return_ref->{$plate_name}->{main_tv_plates} ) {
            $main_child_plates = join( '  ', sort keys %{ $return_ref->{$plate_name}->{main_tv_plates} } );
        }

        my $main_count     = 0;
        my $total_count    = 0;
        foreach my $well ( keys %{ $return_ref->{$plate_name}->{wells} } ) {
            my $increment_total = 0;
            if ( $return_ref->{$plate_name}->{wells}->{$well}->{main_distribute} ) {
                $main_count++;
                $increment_total = 1;
            }

            if ($increment_total) {
                $total_count++;
            }
        }

        $return_ref->{$plate_name}->{name}                  = $plate_name;
        $return_ref->{$plate_name}->{project}               = $plate_project;
        $return_ref->{$plate_name}->{main_count}            = $main_count;
        $return_ref->{$plate_name}->{total_count}           = $total_count;
        $return_ref->{$plate_name}->{main_child_plates}     = $main_child_plates;

    }

    return $return_ref;
}

return 1;
