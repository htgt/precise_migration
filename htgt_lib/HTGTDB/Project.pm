package HTGTDB::Project;

use strict;
use warnings;

use HTGT::Constants qw( %SPONSOR_FOR );

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/InflateColumn::DateTime PK::Auto Core/);

__PACKAGE__->table('project');

__PACKAGE__->sequence('S_PROJECT');

__PACKAGE__->add_column( project_id => { is_auto_increment => 1 } );

__PACKAGE__->add_column( status_change_date => { data_type => 'date' } );

#__PACKAGE__->add_columns(
#    qw/
#      project_status_id
#      mgi_gene_id
#      computational_gene_id
#      is_publicly_reported
#      is_komp_csd
#      is_komp_regeneron
#      is_eucomm
#      is_eucomm_tools
#      is_eucomm_tools_cre
#      is_switch
#      is_norcomm
#      is_mgp
#      is_trap
#      is_eutracc
#      is_mgp_bespoke
#      is_tpp
#      design_id
#      design_instance_id
#      bac
#      intermediate_vector_id
#      targeting_vector_id
#      cassette
#      backbone
#      design_plate_name
#      design_well_name
#      intvec_plate_name
#      intvec_well_name
#      intvec_pass_level
#      targvec_plate_name
#      targvec_well_name
#      targvec_pass_level
#      targvec_distribute
#      total_colonies
#      colonies_picked
#      epd_distribute
#      targeted_trap
#      edit_user
#      edit_date
#      epd_recovered
#      is_latest_for_gene
#      vector_only
#      esc_only
#      phenotype_url
#      distribution_centre_url
#      /
#  );

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "project_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_project",
    size => [10, 0],
  },
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "is_publicly_reported",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "computational_gene_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "is_komp_csd",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_komp_regeneron",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_eucomm",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_norcomm",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_mgp",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "design_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_instance_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "intermediate_vector_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "targeting_vector_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "edit_user",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "edit_date",
  {
    data_type   => "datetime",
    is_nullable => 0,
    original    => { data_type => "date" },
  },
  "cassette",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "backbone",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "design_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "design_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "intvec_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "intvec_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "targvec_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "targvec_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "project_status_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "total_colonies",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "colonies_picked",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "epd_distribute",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "intvec_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 50 },
  "targvec_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 50 },
  "targvec_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 50 },
  "epd_recovered",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_latest_for_gene",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_trap",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_eutracc",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "targeted_trap",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "vector_only",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "esc_only",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_eucomm_tools",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_switch",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_eucomm_tools_cre",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "status_change_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "is_tpp",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_mgp_bespoke",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "phenotype_url",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "distribution_centre_url",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('project_id');

#wtf? this is just specifying a subset of the columns defined in the unique constraint in the database
__PACKAGE__->add_unique_constraint( unique_project => [qw/design_instance_id cassette backbone/] );

__PACKAGE__->belongs_to( status              => 'HTGTDB::ProjectStatus',           'project_status_id' );
__PACKAGE__->belongs_to( mgi_gene            => 'HTGTDB::MGIGene',                 'mgi_gene_id' );
__PACKAGE__->belongs_to( design              => 'HTGTDB::Design',                  'design_id' );
__PACKAGE__->belongs_to( design_instance     => 'HTGTDB::DesignInstance',          'design_instance_id' );
__PACKAGE__->belongs_to( intermediate_vector => 'HTGTDB::Well',                    'intermediate_vector_id' );
__PACKAGE__->belongs_to( targeting_vector    => 'HTGTDB::Well',                    'targeting_vector_id' );
__PACKAGE__->belongs_to( publicly_reported   => 'HTGTDB::ProjectPubliclyReported', 'is_publicly_reported');

__PACKAGE__->has_many( ws_by_di_entries => 'HTGTDB::WellSummaryByDI', 'project_id', { cascade_copy => 0 } );
__PACKAGE__->has_many( new_ws_entries   => 'HTGTDB::NewWellSummary', 'project_id', { cascade_copy => 0 } );

__PACKAGE__->might_have( primer_band_sizes => 'HTGTDB::PrimerBandSize', 'project_id', { cascade_delete => 0 } );

## TRAPS ##
__PACKAGE__->has_many( gene_trap_links => 'HTGTDB::ProjectGeneTrapWell', 'project_id', { cascade_copy => 0 } );
__PACKAGE__->many_to_many( gene_trap_wells => 'gene_trap_links', 'gene_trap_well' );


##
## Helper Methods
##

sub intvec_distribute {
  my $self = shift;
  my $ws_by_di_entries = $self->ws_by_di_entries->first
      or return;
  return $ws_by_di_entries->pcs_distribute;
}

sub sponsor {
    my ( $self ) = @_;
    
    # Assume the sponsor flags are mutually exclusive and return the 
    # first match we find
    foreach my $flag ( grep { !/is_mgp/ } keys %SPONSOR_FOR ) {
        if ( $self->$flag ) {
            my $sponsor = $SPONSOR_FOR{ $flag };
            $sponsor .= ":MGP" if $self->is_mgp;
            return $sponsor;
        }
    }   
    return;
}

sub sponsors {
    my ( $self ) = @_;

    # Return a list of all the sponsors
    my @sponsors = map $SPONSOR_FOR{$_}, grep $self->$_, keys %SPONSOR_FOR;
    return sort @sponsors;
}

sub sponsors_str {
    my ( $self, $separator ) = @_;
    
    $separator = '/' unless defined $separator;
    join $separator, $self->sponsors;
}

sub terminate {
  my $self = shift;
  my $edit_user = shift;
  
  my $schema = $self->result_source->schema;
  my $project_status_rs = $schema->resultset('HTGTDB::ProjectStatus');
  
  my $vector_complete_status = $project_status_rs->find ({ code => 'TVC'});
  die 'cant find vector complete status' unless $vector_complete_status;
  
  my $targ_confirmed_status = $project_status_rs->find ({ code => 'ES-TC' }) ;
  die 'cant find targeting confirmed status' unless $targ_confirmed_status;
  
  my $incomplete_terminated_status = $project_status_rs->find({ code => 'TV-PT' }) ;
  die 'cant find vector unsuccesful terminated status' unless $incomplete_terminated_status;
  
  my $complete_terminated_status = $project_status_rs->find ({ code => 'TVC-PT' });
  die 'cant find vector complete terminated status' unless $complete_terminated_status;
  
  if ( $self->status->order_by < $vector_complete_status->order_by ){
    
    $self->update (
      {
        project_status_id => $incomplete_terminated_status->project_status_id ,
        edit_user => $edit_user,
        edit_date => \'sysdate'
      });
    
  }elsif ( $self->status->order_by < $targ_confirmed_status->order_by){
    
    $self->update (
      {
        project_status_id => $complete_terminated_status->project_status_id,
        edit_user => $edit_user,
        edit_date => \'sysdate',
        status_change_date => \'sysdate'
      }
    );
    
  }
}

return 1;
