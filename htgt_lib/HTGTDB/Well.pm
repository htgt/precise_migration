package HTGTDB::Well;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer
David K Jackson <david.jackson@sanger.ac.uk>
Darren Oakley <do2@sanger.ac.uk>

Modified by D J Parry-Smith (htgt_migration)

=cut

use base qw/DBIx::Class/;

use HTGT::Utils::PassLevel qw( qc_update_needed );
use HTGT::Utils::WellName;
use HTGT::QC::DistributionLogic;
__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('well');
#__PACKAGE__->add_columns(
#  "plate_id",
#  {
#    data_type => "numeric",
#    is_foreign_key => 1,
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "design_instance_id",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "well_name",
#  { data_type => "varchar2", is_nullable => 1, size => 24 },
#  "well_id",
#  {
#    data_type => "numeric",
#    is_auto_increment => 1,
#    is_nullable => 0,
#    original => { data_type => "number" },
#    sequence => "s_well",
#    size => [10, 0],
#  },
#  "parent_well_id",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "qctest_result_id",
#  {
#    data_type   => "integer",
#    is_nullable => 1,
#    original    => { data_type => "number", size => [38, 0] },
#  },
#  "edit_user",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "edit_date",
#  {
#    data_type   => "datetime",
#    is_nullable => 1,
#    original    => { data_type => "date" },
#  },
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_instance_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "well_id",
  {
#    data_type => "numeric", -- not for SQLite
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_well",
    size => [10, 0],
  },
  "parent_well_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "qctest_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edit_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
);
# End of dbicdump add_columns data
#__PACKAGE__->add_columns(
#  qw/
#   plate_id
#   well_id
#   well_name
#   parent_well_id
#   design_instance_id
#   qctest_result_id
#   edit_user/,
#   'edit_date' => { data_type => 'TIMESTAMP' }
#);

__PACKAGE__->set_primary_key(qw/well_id/);
__PACKAGE__->sequence('S_WELL');

__PACKAGE__->add_unique_constraint( plate_id_well_name => [qw/plate_id well_name/] );

__PACKAGE__->has_many( well_data                 => 'HTGTDB::WellData',               'well_id' );
__PACKAGE__->has_many( primer_reads              => 'HTGTDB::WellPrimerReads',        'well_id' );
__PACKAGE__->has_many( child_wells               => 'HTGTDB::Well',                   'parent_well_id' );
__PACKAGE__->has_many( pc_primer_reads           => 'HTGTDB::PcPrimerRead',           'well_id' );
__PACKAGE__->has_one( well_detail                => 'HTGTDB::WellDetail',             'well_id', { cascade_update => 0, cascade_delete => 0 } );
__PACKAGE__->might_have( design_instance_jump    => 'HTGTDB::WellDesignInstanceJump', 'well_id' );
__PACKAGE__->might_have( repository_qc_result    => 'HTGTDB::RepositoryQCResult',     'well_id' );
__PACKAGE__->might_have( user_qc_result          => 'HTGTDB::UserQCResult',           'well_id' );
__PACKAGE__->might_have( grc_alt_clone_chosen    => 'HTGTDB::GRCAltCloneChosen',      'chosen_well_id' );
__PACKAGE__->might_have( grc_alt_clone_alternate => 'HTGTDB::GRCAltCloneAlternate',   'alt_clone_well_id' );
__PACKAGE__->might_have( grc_gateway             => 'HTGTDB::GRCGateway',             'pcs_well_id' );
__PACKAGE__->might_have( grc_redesign            => 'HTGTDB::GRCRedesign',            'design_well_id' );
__PACKAGE__->might_have( gr_redesign             => 'HTGTDB::GRRedesign',             'rdr_well_id' );
__PACKAGE__->might_have( gr_gateway              => 'HTGTDB::GRGateway',              'gwr_well_id' );
__PACKAGE__->might_have( gr_alt_clone            => 'HTGTDB::GRAltClone',             'acr_well_id' );

# design_instance matching child wells
__PACKAGE__->has_many(
  dim_child_wells => 'HTGTDB::Well',
  {
    'foreign.parent_well_id'     => 'self.well_id',
    'foreign.design_instance_id' => 'self.design_instance_id'
  }
);

__PACKAGE__->belongs_to( parent_well => 'HTGTDB::Well', 'parent_well_id', { join_type => 'left' } );

# design_instance matching parent well
__PACKAGE__->belongs_to(
  dim_parent_well => 'HTGTDB::Well',
  {
    'foreign.well_id'            => 'self.parent_well_id',
    'foreign.design_instance_id' => 'self.design_instance_id'
  },
  { join_type => 'left' }
);

__PACKAGE__->belongs_to( plate => 'HTGTDB::Plate', 'plate_id' );
__PACKAGE__->belongs_to( design_instance => 'HTGTDB::DesignInstance', 'design_instance_id', { join_type => 'left' } );

use overload '""' => \&stringify;

sub stringify {
    my ( $self ) = @_;
    sprintf( '%s[%s]', $self->plate->name || 'UNKNOWN PLATE', $self->well_name || 'UNNAMED WELL' );
}

#__PACKAGE__->has_many(well_summary_rows => 'HTGTDB::WellSummaryByDI', 'epd_well_id' );

# Utility functions:

=head2 well_data_value()

Return the value of the requested well_data

=cut 

sub well_data_value {
    my ( $self, $data_type ) = @_;
    if ( my $wd = $self->related_resultset( 'well_data' )->find( { data_type => $data_type } ) ) {
        return $wd->data_value;
    }
    return;
}

=head2 clone_name()

Return the name of the clone in this well, recursing into parent wells
if it is not specified for this well

=cut

sub clone_name {
    my ( $self ) = @_;
    if ( my $clone_name = $self->well_data_value( 'clone_name' ) ) {
        return $clone_name;
    }
    if ( $self->parent_well_id ) {
        return $self->parent_well->clone_name;
    }
    return;        
}


#TODO: check into removing this - an old script that Darren used.
our @EXPORT;
push( @EXPORT, qw/well_name_spp inherit_from_parent convertWellType to96 to384 targeted_trap/ );

# This is a hacky method to get the mgi marker name for a well.
sub mgi_gene {
  my ($self) = @_;

  my $dbh = $self->result_source()->storage()->dbh();

  my $sql = $dbh->prepare( "
                            SELECT gene.marker_symbol
                            FROM
                            well w,
                            project p,
                            mgi_gene gene
                            WHERE w.well_id = ?
                            AND p.design_instance_id = w.design_instance_id
                            AND gene.mgi_gene_id = p.mgi_gene_id
                            " );
  $sql->execute( $self->well_id );
  my $gene = $sql->fetchall_arrayref()->[0][0];
  return ($gene);
}

=head2 well_name_spp

Removes the plate prefix from a well name (sans plate prefix)

=cut

sub well_name_spp {
  my ($self) = @_;
  my $wn     = $self->well_name;
  my $pn     = $self->plate->name;
  $wn =~ s/^${pn}_//;
  return $wn;
}

=head2 inherit_from_parent

Helper method to allow a well to inherit information from its parent.

INPUT:  $self -> the child well to update
        $opt_params -> an array ref containing the names of well_data entries that you want to inherit too
        $method_opt -> hash ref of method options

=cut

sub inherit_from_parent {
  my ( $self, $opt_params, $method_opt ) = @_;
  my $edit_user = ( $method_opt ? $method_opt->{edit_user} : undef );

  if ( my $pw = $self->parent_well ) {
    $self->update(
      {
        design_instance_id => $pw->design_instance_id,
        ( $edit_user ? ( edit_user => $edit_user ) : () )
      }
    ) unless ( $method_opt and $method_opt->{no_inherit_design_instance_id} );

    if ( scalar( @{$opt_params} ) > 0 ) {
      foreach my $data_type ( @{$opt_params} ) {
        if ( my $pd = $pw->well_data->find( { data_type => $data_type } ) ) {
          $self->well_data->update_or_create(
            {
              data_value => $pd->data_value,
              data_type  => $data_type,
              ( $edit_user ? ( edit_user => $edit_user ) : () )
            },
            { key => 'well_id_data_type' }
          );
        }
      }
    }
    return 1;
  }
  return 0;
}

=head2 cascade_to_descendants

Helper method to allow a well to pass on information to all its descendants.

INPUT:  $self -> the well whose decsendants should be updated
        $opt_params -> an array ref containing the names of well_data entries that you want to inherit too

=cut

sub cascade_to_descendants {

  #tried using related_resultset with child_wells but had problem with phatom Well objects being created - reverted to simple recursive method....
  my ( $self, $opt_params, $max_rec, $method_opt ) = @_;
  $max_rec = 12 unless defined $max_rec;
  my $children = $self->child_wells;
  $max_rec--;
  die "Supposed max depth of descendants exceeded!" unless $max_rec >= 0;
  foreach ( $children->all ) {
    unless ( $_->id ) { warn "null id"; return; }
    $_->inherit_from_parent( $opt_params, $method_opt );
    $_->cascade_to_descendants( $opt_params, $max_rec, $method_opt );
  }
}

=head2 oldest_ancestor

Method to return oldest ancestor well.

=cut

sub oldest_ancestor {
  my ( $well, $max_rec ) = @_;
  $max_rec = 12 unless defined $max_rec;
  while ( my $parent = $well->parent_well and $max_rec-- ) { $well = $parent; }
  die "Supposed max depth of descendants exceeded!" unless $max_rec >= 0;
  return $well;
}

=head2 ancestor_well_plate_of_type

Method to return ancestor (or current) of given type well and its plate.

=cut

sub ancestor_well_plate_of_type {

  #should be a faster SQL way...
  my ( $well, $type, $max_rec ) = @_;
  $max_rec = 12 unless defined $max_rec;
  my $plate = $well->plate;
  return ( $well, $plate ) if ( $plate->type eq $type );
  while ( my $parent = $well->parent_well and $max_rec-- ) {
    $well  = $parent;
    $plate = $well->plate;
    return ( $well, $plate ) if ( $well->plate->type eq $type );
  }
  die "Supposed max depth of descendants exceeded!" unless $max_rec >= 0;
  return undef;
}

=head2 dim_ancestor_well_plate_of_type

Method to return design instance matching ancestor (or current) of given type well and its plate.

=cut

sub dim_ancestor_well_plate_of_type {

  #should be a faster SQL way...
  my ( $well, $type, $max_rec ) = @_;
  $max_rec = 12 unless defined $max_rec;
  my $plate = $well->plate;
  return ( $well, $plate ) if ( $plate->type eq $type );
  while ( my $parent = $well->dim_parent_well and $max_rec-- ) {
    $well  = $parent;
    $plate = $well->plate;
    return ( $well, $plate ) if ( $well->plate->type eq $type );
  }
  die "Supposed max depth of descendants exceeded!" unless $max_rec >= 0;
  return undef;
}

=head2 ep_well_plate

DEPRECATED!!!!!
Method to return EP ancestor (or current) well and its plate. If there is a design_instance mismatch trust first parent plate (not well) if it is an EP.

=cut

sub ep_well_plate {

  #should be a faster SQL way...
  my ( $well, $max_rec ) = @_;
  $max_rec = 12 unless defined $max_rec;
  my $design_instance_id = $well->design_instance_id;
  my $plate              = $well->plate;
  return ( $well, $plate ) if ( $plate->type eq 'EP' );
  while ( my $parent = $well->parent_well and $max_rec-- ) {
    if ( ( not $design_instance_id ) or ( $parent->design_instance_id ) or $parent->design_instance_id == $design_instance_id ) {
      $well  = $parent;
      $plate = $well->plate;
      return ( $well, $plate ) if ( $well->plate->type eq 'EP' );
    }
    else {
      my $p_rs = $well->related_resultset('parent_well')->related_resultset('plate')->search( {}, { distinct => 1 } );
      if ( $p_rs->count == 1 ) {
        $plate = $p_rs->first;
        if ( $plate->type eq 'EP' ) { return ( undef, $plate ) }
      }
      return ( undef, undef );
    }
  }
  die "Supposed max depth of descendants exceeded!" unless $max_rec >= 0;
  return undef;
}

=head2 es_cell_line

Convenience method for getting ES cell line. We check for design 
instance consistent well ancestry, or unambiguous data from plate ancestory.

=cut

sub es_cell_line {
  my ($self) = @_;
  
  #my ( $w, $p ) = $this->dim_ancestor_well_plate_of_type('EP');
  # changed to use ancestor_well_plate_of_type rather than dim_ancestor_well_plate_of_type wy1 May 29, 2010
 
  my ( $w, $p ) = $self->ancestor_well_plate_of_type('EP');
  
  # find es_cell_line from  ep plate_data or ep well_data or epd well_data
  
  if ($p) {
    my $pd = $p->plate_data->find( { data_type => 'es_cell_line' } );
    
    if( $pd ){
       return $pd->data_value;   
    }else{
        my $pwd = $self->parent_well->well_data_value('es_cell_line');
        if ($pwd){
            return $pwd;
        }else{
            my $wd = $self->well_data_value('es_cell_line');
            return $wd ? $wd : undef ;
        }
    }
  }
  else {
    my $p_rs = $self->plate->ancestor_plates->search( { type => 'EP' } );
    return unless $p_rs->count;
    my @r = $p_rs->related_resultset('plate_data')->search( { data_type => 'es_cell_line' } )->get_column('plate_data.data_value')->all;
    @r = keys %{ { map { $_ => 1 } @r } };
    return $r[0] if ( scalar(@r) == 1 );
  }
}

=head2 design_well_plate

DEPRECATED!!!!!
Method to return DESIGN ancestor (or current) well and its plate.

=cut

sub design_well_plate {

  #should be a faster SQL way...
  my ( $well, $max_rec ) = @_;
  $max_rec = 12 unless defined $max_rec;
  my $plate = $well->plate;
  return ( $well, $plate ) if ( $plate->type eq 'DESIGN' );
  while ( my $parent = $well->parent_well and $max_rec-- ) {
    $well  = $parent;
    $plate = $well->plate;
    return ( $well, $plate ) if ( $well->plate->type eq 'DESIGN' );
  }
  die "Supposed max depth of descendants exceeded!" unless $max_rec >= 0;
  return undef;
}

=head2 bacs

Convenience method for getting BACs. We check for design instance 
consistent well ancestry, or unambiguous data from plate ancestory.

=cut

sub bacs {
  my ($this) = @_;
  my ( $w, $p ) = $this->dim_ancestor_well_plate_of_type('DESIGN');
  if ($p) {
    my $pd = $p->plate_data->find( { data_type => 'bacs' } );
    return $pd ? $pd->data_value : undef;
  }
  else {
    my $p_rs = $this->plate->ancestor_plates->search( { type => 'DESIGN' } );
    return unless $p_rs->count;
    my @r = $p_rs->related_resultset('plate_data')->search( { data_type => 'bacs' } )->get_column('plate_data.data_value')->all;
    @r = keys %{ { map { $_ => 1 } @r } };
    return $r[0] if ( scalar(@r) == 1 );
  }
}

=head2 cassette

Convenience method for getting cassette.

=cut

sub cassette {
  my ($this) = @_;
  my $wd = $this->well_data->find( { data_type => 'cassette' } );
  return $wd ? $wd->data_value : undef;
}

=head2 backbone

Convenience method for getting backbone.

=cut

sub backbone {
  my ($this) = @_;
  my $wd = $this->well_data->find( { data_type => 'backbone' } );
  return $wd ? $wd->data_value : undef;
}

sub to96 {
  my ($self) = @_;
  return HTGT::Utils::WellName::to96( $self->well_name );
}

sub to384 {
  my ($self) = @_;
  return HTGT::Utils::WellName::to384( $self->plate->name, $self->well_name );
}

=head2 insert_update_qc_data

Utility function for the QC data loading routines.  This function checks to see if a 
well already has a QC pass level, and if it could be updated with a new (better) 
result.  B<Really should be ran from within a transaction block>.

B<Input:>
 * $options             Hashref containing the following:
    - well_data         Hashref containing welldata_type / welldata_value pairs
    - stage             The QC test 'stage' - i.e. 'allele' etc.
    - user              The username to attribute this data entry to
    - log               Reference to a logging function (optional)
    - override          Flag to override the existing QC data - set as '1' (optional)

=head2 insert_update_qc_data

Utility function for the QC data loading routines.  This function loads/updates the 
WellPrimerReads table with information on the primer reads for this well/construct clone. 
B<Really should be ran from within a transaction block>.

B<Input:>
 * $options             Hashref containing the following:
    - primer_reads      Hashref containing primer reads - keys are column names
    - log               Reference to a logging function (optional)

=head2 log_di_mismatch

Helper function to write details of a DI mismatch to a log file.

B<Input>
 * $qc_result:        DBIx Object for the QctestResult
 * $expected_di_id:   The expected design instance id

=head2 prepare_allele_well_data

Utility function for the QC data loading routines.  This function collects and 
prepares the well data entries for a given QC test.

B<Input:>
 * $options             Hashref containing the following:
    - qctest_result     DBIx Object for the QctestResult
    - stage             The QC test 'stage' - i.e. 'allele' etc.
    - log               Reference to a logging function (optional)

=head2 prepare_primer_results

Utility function for the QC data loading routines.  This function collects and 
prepares primer results for a given QC test.

B<Input:>
 * $options             Hashref containing the following:
    - qctest_result     DBIx Object for the QctestResult


=head2 set_vector_distribute_flag



=head2 set_allele_distribute_flag



=cut

sub insert_update_qc_data {
  my ( $well, $options ) = @_;
  
  my $well_data_ref = $options->{well_data};
  my $stage         = $options->{stage};
  my $user          = $options->{user};
  my $log           = $options->{log} ? $options->{log} : sub{};
  my $override      = $options->{override};

  # This subroutine applies the following logic...
  #
  #  -- See if we already have a pass_level associated with this well
  #   |-- No? - Insert the WellData we have...
  #   |-- Yes? - See if the 'new' pass level is better
  #     |-- No? - Leave alone
  #     |-- Yes? - Update the WellData

  my $well_data_types = {
    allele_fponly => 'five_arm_pass_level',
    allele_tponly => 'three_arm_pass_level',
    allele_tronly => 'target_region_pass_level'
  };

  my $run_update = undef;

  my $well_data = $well->well_data->find(
    { data_type => $well_data_types->{$stage} ? $well_data_types->{$stage} : 'pass_level' },
    { key => 'well_id_data_type' }
  );

  if ( $well_data ) {
    # Are we forcing an override?
    if ( defined $override && $override == 1 ) {
      $run_update = 1;
    }
    else {
      # Compare the new and old pass_levels...
      my $current_pass_level = $well_data->data_value;
      my $new_pass_level = $well_data_types->{$stage} ? $well_data_ref->{$well_data_types->{$stage}} : $well_data_ref->{pass_level};
      $run_update = qc_update_needed( $current_pass_level, $new_pass_level );
    }
  }
  else {
    # We have no QC results associated with this well, add them...
    $run_update = 1;
  }

  if ( defined $run_update && $run_update == 1 ) {
    use DateTime;
    my $dt   = DateTime->now;
    my $date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;

    # WellData updates...
    foreach my $data_type ( keys %{$well_data_ref} ) {
      
      # Small bit of plate specific logic here - if we're working with a GRD/GRQ plate 
      # (internal recovery activities) there should already be a clone name on the 
      # well - DO NOT over-write it!!!!
      
      if ( $data_type eq 'clone_name' && $well->plate->type =~ /GRD|GRQ/ ) { next; }
      else {
        
        $well->well_data->update_or_create(
          {
            data_type  => $data_type,
            data_value => $well_data_ref->{$data_type},
            edit_user  => $user,
            edit_date  => $date
          },
          { key => 'well_id_data_type' }
        );
        
        &$log( "[HTGTDB::Well::insert_update_qc_data] " . $well->plate->name . "_" . $well->well_name . " WellData Entry - [$data_type => " . $well_data_ref->{$data_type} . "]" );
        
      }
    }
  }
}

sub insert_update_primer_reads {
  my ( $well, $options ) = @_;
  
  my $primer_read_data = $options->{primer_reads};
  my $log              = $options->{log} ? $options->{log} : sub{};
  
  if ( keys %{$primer_read_data} and defined $primer_read_data->{clone_plate} ) {
    my $schema = $well->result_source->schema;
    $primer_read_data->{well_id} = $well->well_id;
    my $read = $schema->resultset('WellPrimerReads')->find(
      { well_id => $primer_read_data->{well_id}, clone_plate => $primer_read_data->{clone_plate} }
    );
    
    if ( $read ) {
      # We need to determine if it's worth updating this entry - don't override good 
      # data with bad...
      
      my $old_read = {};
      if ( $read->lr_qcresult_status and $read->lr_qcresult_status =~ /pass|ok|valid/i )   { $old_read->{lr}++;  }
      if ( $read->lrr_qcresult_status and $read->lrr_qcresult_status =~ /pass|ok|valid/i ) { $old_read->{lrr}++; }
      if ( $read->lf_qcresult_status and $read->lf_qcresult_status =~ /pass|ok|valid/i )   { $old_read->{lf}++;  }
      if ( $read->r1r_qcresult_status and $read->r1r_qcresult_status =~ /pass|ok|valid/i ) { $old_read->{r1r}++; }
      if ( $read->r2r_qcresult_status and $read->r2r_qcresult_status =~ /pass|ok|valid/i ) { $old_read->{r2r}++; }
      
      my $new_read = {};
      if ( $primer_read_data->{lr_qcresult_status} and $primer_read_data->{lr_qcresult_status} =~ /pass|ok|valid/i )   { $new_read->{lr}++;  }
      if ( $primer_read_data->{lrr_qcresult_status} and $primer_read_data->{lrr_qcresult_status} =~ /pass|ok|valid/i ) { $new_read->{lrr}++; }
      if ( $primer_read_data->{lf_qcresult_status} and $primer_read_data->{lf_qcresult_status} =~ /pass|ok|valid/i )   { $new_read->{lf}++;  }
      if ( $primer_read_data->{r1r_qcresult_status} and $primer_read_data->{r1r_qcresult_status} =~ /pass|ok|valid/i ) { $new_read->{r1r}++; }
      if ( $primer_read_data->{r2r_qcresult_status} and $primer_read_data->{r2r_qcresult_status} =~ /pass|ok|valid/i ) { $new_read->{r2r}++; }
      
      my $old_read_count = scalar( keys %{$old_read} );
      my $new_read_count = scalar( keys %{$new_read} );
      
      # If we have more good reads, update the data
      if ( $new_read_count > $old_read_count ) {
        &$log( "[HTGTDB::Well::insert_update_qc_data] ".$well->well_name." UPDATING primer reads: " );
        use Data::Dumper; &$log( Dumper($primer_read_data) );
        
        $read->update($primer_read_data);
      }
      else {
        &$log( "[HTGTDB::Well::insert_update_qc_data] ".$well->well_name." NOT updating primer reads " );
      }
    }
    else {
      &$log( "[HTGTDB::Well::insert_update_qc_data] ".$well->well_name." INSERTING primer reads: " );
      use Data::Dumper; &$log( Dumper($primer_read_data) );
      
      $schema->resultset('WellPrimerReads')->create($primer_read_data);
    }
  }
}


sub log_di_mismatch {
  my ( $well, $qc_result, $expected_di_id ) = @_;
  my $schema = $well->result_source->schema;
  
  # Get the info needed to log...
  
  # Timestamp
  use DateTime;
  my $timestamp = DateTime->now;
  
  # Current pass level
  my $htgt_pass = undef;
  my $htgt_pass_obj = $well->well_data->find( { data_type => 'pass_level' } );
  if ( $htgt_pass_obj ) { $htgt_pass = $htgt_pass_obj->data_value; }
  
  # QC target gene
  my $qc_gene = $schema->resultset('Project')->search(
    { design_instance_id => $expected_di_id },
    { prefetch => 'mgi_gene' }
  )->first->mgi_gene;
  
  my $log_info = [
    $timestamp,
    $well->plate->name,
    $well->well_name,
    $well->design_instance_id,
    $well->mgi_gene,
    $htgt_pass,
    $qc_result->qctest_result_id,
    $expected_di_id,
    $qc_gene->marker_symbol,
    $qc_result->pass_status
  ];
  
  open( OUT, ">>epd_qc_di_mismatch.csv" );
  print OUT join( ',', @{$log_info} ) . "\n";
  close OUT;
}

sub prepare_allele_well_data {
  my ( $well, $options ) = @_;
  
  my $well_data_to_return = {};
  
  my $plate   = $well->plate;
  my $schema  = $well->result_source->schema;
  
  my $qc      = $options->{qctest_result};
  my $stage   = $options->{stage};
  my $log     = $options->{log} ? $options->{log} : sub{};
  
  my $expected_di_id    = undef;
  my $observed_di_id    = $qc->matchedEngineeredSeq->syntheticVector->design_instance_id;
  my $engineered_seq_id = $qc->matchedEngineeredSeq->engineered_seq_id;

  if ( $qc->expected_engineered_seq_id ) {
    $expected_di_id = $qc->expectedEngineeredSeq->syntheticVector->design_instance_id;
  }
  else {
    $expected_di_id = $observed_di_id;
  }

  my $expected_di = $schema->resultset('DesignInstance')->find({ design_instance_id => $expected_di_id });
  my $observed_di = $schema->resultset('DesignInstance')->find({ design_instance_id => $observed_di_id });
  
  # Check that the well has a DI set... If not, set it - not an ideal 
  # situation, but it's better than not loading a possibly valid result.

  if ( $well->design_instance_id ) {

    # Do we have a DI mis-match?
    if ( $well->design_instance_id != $expected_di_id ) {

      # Before we just log a mismatched design instance ID...
      # See if the Genes are the same.  If yes, we can take this result!

      my $htgt_gene = $schema->resultset('Project')->search(
        { design_instance_id => $well->design_instance_id },
        { prefetch => 'mgi_gene' }
      )->first->mgi_gene;

      my $qc_gene = $schema->resultset('Project')->search(
        { design_instance_id => $expected_di_id },
        { prefetch => 'mgi_gene' }
      )->first->mgi_gene;

      if ( $htgt_gene and $qc_gene and ( $htgt_gene->marker_symbol eq $qc_gene->marker_symbol ) ) {
        # The gene's match!!!
      }
      else {

        # This is a true mismatch... log it!
        &$log( "[HTGTDB::Well::prepare_allele_well_data] ".$plate->name." : ".$well->well_name." - ERROR: DI Mismatch with QC Result ID ".$qc->qctest_result_id );
        $well->log_di_mismatch( $qc, $expected_di_id );

      }

    }

  }
  else {

    # No DI?!?! - Hmm'kay, someone forgot to link a sample...
    $well->update({ design_instance_id => $expected_di_id });
    &$log( "[HTGTDB::Well::prepare_allele_well_data] ".$plate->name." : ".$well->well_name." - WARNING: No DI set, setting as $expected_di_id" );

  }

  if ( $stage eq 'allele' ) {
    
    my $proc_pass_level = undef;
    if ( $qc->result_comment ) {
      if ( $qc->result_comment =~ /pass 4/ ) { $proc_pass_level = 'pass4'; }
      else                                   { $proc_pass_level = $qc->result_comment; }
    }
    elsif ( $observed_di_id != $expected_di_id ) {
      $proc_pass_level = 'fail';
    }
    else {
      $proc_pass_level = $qc->chosen_status || $qc->pass_status;
    }

    $well_data_to_return = {
      qctest_result_id    => $qc->qctest_result_id,
      pass_level          => $proc_pass_level,
      synthetic_allele_id => $engineered_seq_id,
      exp_design_id       => $expected_di->platewelldesign,
      obs_design_id       => $observed_di->platewelldesign
    };
    
  }
  else {
    
    my $proc_pass_level = undef;
    if    ( $qc->result_comment )                { $proc_pass_level = $qc->result_comment; }
    elsif ( $observed_di_id != $expected_di_id ) { $proc_pass_level = 'fail'; }
    else                                         { $proc_pass_level = $qc->chosen_status || $qc->pass_status; }
    
    if    ( $stage eq 'allele_fponly' ) {
      $well_data_to_return = {
        five_arm_qctest_result_id => $qc->qctest_result_id,
        five_arm_pass_level       => $proc_pass_level,
        synthetic_allele_id       => $engineered_seq_id,
        exp_design_id             => $expected_di->platewelldesign,
        obs_design_id             => $observed_di->platewelldesign
      };
    }
    elsif ( $stage eq 'allele_tponly' ) {
      $well_data_to_return = {
        three_arm_qctest_result_id => $qc->qctest_result_id,
        three_arm_pass_level       => $proc_pass_level,
        synthetic_allele_id        => $engineered_seq_id,
        exp_design_id              => $expected_di->platewelldesign,
        obs_design_id              => $observed_di->platewelldesign
      };
    }
    elsif ( $stage eq 'allele_tronly' ) {
      
      # Tony asked for this specific string to be inserted on DI mismatch 
      # on the TR PCR tests.
      if ( $observed_di_id != $expected_di_id ) {
        $proc_pass_level = $qc->chosen_status || $qc->pass_status;
        $proc_pass_level = $qc->matchedEngineeredSeq->name . " " . $proc_pass_level;
        $proc_pass_level = $proc_pass_level . "_di" . $observed_di_id;
      }
      
      $well_data_to_return = {
        target_region_qctest_result_id => $qc->qctest_result_id,
        target_region_pass_level       => $proc_pass_level,
        synthetic_allele_id            => $engineered_seq_id,
        exp_design_id                  => $expected_di->platewelldesign,
        obs_design_id                  => $observed_di->platewelldesign
      };
    }
    
  }
  
  return $well_data_to_return;
}

sub prepare_primer_reads {
  my ( $well, $options ) = @_;
  
  my $qc                    = $options->{qctest_result};
  my $primer_data_to_return = {};
  my $return_some_data      = undef;
  
  my $allowed_primers = {
    LF  => 1,
    LR  => 1,
    LRR => 1,
    R1R => 1,
    R2R => 1
  };
  
  foreach my $primer ( $qc->qctestPrimers ) {
    if ( defined $allowed_primers->{ uc($primer->primer_name) } ) {
      $return_some_data = 1;
      my $pn = lc($primer->primer_name);
      $primer_data_to_return->{ $pn."_qcresult_status" } = $primer->primer_status;

      if ( $primer->seqAlignFeature ) {
        $primer_data_to_return->{ $pn."_align_length" }  = $primer->seqAlignFeature->align_length;
        $primer_data_to_return->{ $pn."_pct_id" }        = $primer->seqAlignFeature->percent_identity;
        $primer_data_to_return->{ $pn."_loc_status" }    = $primer->seqAlignFeature->loc_status;
      }
    }
  }
  
  if ( defined $return_some_data ) {
    $primer_data_to_return->{clone_plate}               = $qc->qctestRun->clone_plate;
    $primer_data_to_return->{primer_design_instance_id} = $qc->matchedEngineeredSeq->syntheticVector->design_instance_id;
  }
  
  return $primer_data_to_return;
}

sub get_all_primer_reads {
  my ( $well, $options ) = @_;
  
  my $qc                    = $options->{qctest_result};
  my $primer_data_to_return = {};
  my $return_some_data      = undef;
  
  foreach my $primer ( $qc->qctestPrimers ) {
    $return_some_data = 1;
    my $pn = lc($primer->primer_name);
    $primer_data_to_return->{ $pn }->{qcresult_status} = $primer->primer_status;
    if ( $primer->seqAlignFeature ) {
      $primer_data_to_return->{ $pn }->{align_length}  = $primer->seqAlignFeature->align_length;
      $primer_data_to_return->{ $pn }->{pct_id}        = $primer->seqAlignFeature->percent_identity;
      $primer_data_to_return->{ $pn }->{loc_status}    = $primer->seqAlignFeature->loc_status;
    }
  }
  
  if ( defined $return_some_data ) {
    $primer_data_to_return->{clone_plate}               = $qc->qctestRun->clone_plate;
    $primer_data_to_return->{primer_design_instance_id} = $qc->matchedEngineeredSeq->syntheticVector->design_instance_id;
  }
  
  return $primer_data_to_return;
}

sub set_vector_distribute_flag {
  my ( $well ) = @_;
  
  
  
}

sub set_allele_distribute_flag {
  my ( $well ) = @_;
  
  
  
}

=head2 three_arm_pass_level

Utility function to return the 3' arm pass level for a well after considering it's QC data.

=head2 five_arm_pass_level

Utility function to return the 5' arm pass level for a well after considering it's QC data.

=head2 loxP_pass_level

Utility function to return the loxP pass level for a well after considering it's QC data.

=head2 do_i_have_reads_and_bands

Utility function for the pass level calling.  Simply determines if there is any QC data worth looking at.

=head2 get_primer_reads_and_bands

Utility function for the pass level calling.  This collates all of the QC data for the pass 
level calling functions and presents it to the functions in a uniform manner.

=head2 distribute

Utility function for distribution calling.  Will return either of the strings 'distribute', 
'targeted_trap' or 'no' for a well after considering its pass levels.

=cut

sub three_arm_pass_level {
    shift->_pass_level_helper( 'three_arm_pass', @_ );
}

sub five_arm_pass_level {
    shift->_pass_level_helper( 'five_arm_pass', @_ );
}

sub loxP_pass_level {
    shift->_pass_level_helper( 'loxp_pass', @_ );
}

sub _pass_level_helper {
    my ( $well, $pass_level_type, $recompute ) = @_;

    my $well_data_type = 'computed_' . $pass_level_type . '_level';
    my $pass_level = $well->well_data_value( $well_data_type );

    if ( $recompute or not defined $pass_level ) {
        my ( $qc_data, $qc_done ) = get_qc_data($well);

        if ($pass_level_type eq 'five_arm_pass' and !$well->plate->have_i_had_five_arm_qc){
            return 'na';
        }

        return 'nd' if !$qc_done;

        $pass_level = 'fail';

        my $dist_logic = HTGT::QC::DistributionLogic->new(
            {
                qc_data => $qc_data,
                profile => 'standard'
            }
        );

        my $pass = $dist_logic->$pass_level_type;
        if (defined $pass and $pass == 1 ){
            $pass_level = 'pass';
        }
        $well->well_data_rs->update_or_create(
            {
                data_type  => $well_data_type,
                data_value => $pass_level,
                edit_user  => 'HTGTDB::Well',
                edit_date  => \'current_timestamp',
            },
            {
                key => 'well_id_data_type'
            }
        );
    }

    return $pass_level;
}

sub get_qc_data{
    my ( $well ) = @_;

    my $schema = $well->result_source->schema;

    my $target_wells = $well->get_target_wells( $schema );

    my ( $qc_data, $qc_done );

    if ( $well->related_resultset('well_data')->find(
        { data_type => 'new_qc_test_result_id' } ) ){
        ( $qc_data, $qc_done ) = $well->get_qc_data_new_qc( $schema, $target_wells );
    }
    else{
        ( $qc_data, $qc_done ) = $well->get_qc_data_old_qc( $schema, $target_wells );
    }

    return ( $qc_data, $qc_done );
}

sub get_target_wells{
    my ( $well, $schema ) = @_;

    my $target_wells = [$well->well_id];

    my $use_recovery_data = $well->use_recovery_data( $schema );

    if ( defined $use_recovery_data and $use_recovery_data->data_value ){
        my $child_well_rs = $schema->resultset('Well')->search(
            {
                parent_well_id => $well->well_id,
            },
            {
                prefetch       => 'plate'
            }
        );

        while ( my $child_well = $child_well_rs->next ){
            if ( $child_well->plate->type =~ /REPD|RHEPD/ ){
                push( @{$target_wells}, $child_well->well_id );
            }
        }
    }

    return $target_wells;
}

sub use_recovery_data{
    my ( $well, $schema ) = @_;

    return $schema->resultset('WellData')->find(
        {
            well_id   => $well->well_id,
            data_type => 'pass_from_recovery_QC'
        },
        {
            key => 'well_id_data_type'
        }
    );
}


sub get_qc_data_new_qc{
    my ( $well, $schema, $target_wells ) = @_;

    my $valid_primers = $well->related_resultset('well_data')->find(
        { data_type => 'valid_primers' } );
    my $valid_primer_string = defined $valid_primers ? $valid_primers->data_value : '';
    my @valid_primers = split( ',', $valid_primer_string );

    my %qc_data = map { 'primer_read_' . $_ => 1 } @valid_primers;

    %qc_data = %{add_bands_to_qc_data( $schema, $target_wells, \%qc_data )};

    return ( \%qc_data, 1 );
}

sub get_qc_data_old_qc{
    my ( $well, $schema, $target_wells ) = @_;

    my %qc_data;
    my $qc_done = 0;

    my $primer_read_rs = $schema->resultset('WellPrimerReads')->search(
        { well_id   => $target_wells } );

    my $matching_design_instance;
    while ( my $primer_read = $primer_read_rs->next ){
        $matching_design_instance = 0;
        my $plate_type = substr( $primer_read->clone_plate, -1);
        next unless $plate_type =~ /^[ABRZC]$/;

        if ( defined $well->design_instance_id
                 and defined $primer_read->primer_design_instance_id 
                     and $primer_read->primer_design_instance_id == $well->design_instance_id ){
            $matching_design_instance = 1;
        }

        if ( $primer_read->lr_qcresult_status and $primer_read->lr_qcresult_status =~ /pass|ok|valid|weak_read/i ){
            $qc_done = 1;
            $qc_data{ 'primer_read_' . $plate_type . '_LR' } = 1 if $matching_design_instance;
        }
        if ( $primer_read->lrr_qcresult_status and $primer_read->lrr_qcresult_status =~ /pass|ok|valid|weak_read/i ){
            $qc_done = 1;
            $qc_data{ 'primer_read_' . $plate_type . '_LRR' } = 1 if $matching_design_instance;
        }
        if ( $primer_read->lf_qcresult_status and $primer_read->lf_qcresult_status =~ /pass|ok|valid|weak_read/i ){
            $qc_done = 1;
            $qc_data{ 'primer_read_' . $plate_type . '_LF' } = 1 if $matching_design_instance;
        }
        if ( $primer_read->r1r_qcresult_status and $primer_read->r1r_qcresult_status =~ /pass|ok|valid|weak_read/i ){
            $qc_done = 1;
            $qc_data{ 'primer_read_' . $plate_type . '_R1R' } = 1 if $matching_design_instance;
        }
        if ( $primer_read->r2r_qcresult_status and $primer_read->r2r_qcresult_status =~ /pass|ok|valid|weak_read/i ){
            $qc_done = 1;
            $qc_data{ 'primer_read_' . $plate_type . '_R2R' } = 1 if $matching_design_instance;
        }
    }

    %qc_data = %{add_bands_to_qc_data( $schema, $target_wells, \%qc_data )};

    return ( \%qc_data, $qc_done );
}

sub add_bands_to_qc_data{
    my ( $schema, $target_wells, $qc_data ) = @_;

    my $primer_band_rs = $schema->resultset('WellData')->search(
        {
            well_id   => $target_wells,
            data_type => { 'like', 'primer_band_%' }
        }
    );

    while ( my $primer_band = $primer_band_rs->next ){
        my ( $band_type ) = $primer_band->data_type =~ /^primer_band_(.+)$/;
        $qc_data->{ 'primer_band_' . uc $band_type } = 1;
    }

    return $qc_data;
}

sub distribute {
    my ( $well ) = @_;

    my ( $qc_data, $qc_done ) = get_qc_data($well);
    my $dist_logic = HTGT::QC::DistributionLogic->new(
        {
            qc_data => $qc_data,
            profile => 'standard'
        }
    );

    return 'distribute' if $dist_logic->distribute and $dist_logic->distribute == 1;

    return 'targeted_trap' if $dist_logic->targeted_trap and $dist_logic->targeted_trap == 1;

    return 'no';
}

return 1;

