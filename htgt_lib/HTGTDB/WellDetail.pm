package HTGTDB::WellDetail;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgtdb/trunk/lib/HTGTDB/WellDetail.pm $
# $LastChangedRevision: 6008 $
# $LastChangedDate: 2011-09-22 10:29:26 +0100 (Thu, 22 Sep 2011) $
# $LastChangedBy: rm7 $

use strict; 
use warnings FATAL => 'all';

use base qw( DBIx::Class );

__PACKAGE__->load_components( qw( InflateColumn::DateTime Core ) );

use overload '""' => \&stringify;

__PACKAGE__->table_class( 'DBIx::Class::ResultSource::View' );
__PACKAGE__->table( 'well_detail' );
__PACKAGE__->result_source_instance->is_virtual(0);

__PACKAGE__->result_source_instance->view_definition( <<'EOT' );
CREATE VIEW well_detail
AS SELECT well.well_id AS "WELL_ID",
          well.design_instance_id AS "DESIGN_INSTANCE_ID",
          well.well_name AS "WELL_NAME",
          well.parent_well_id AS "PARENT_WELL_ID",
          plate.plate_id AS "PLATE_ID",
          plate.created_date AS "CREATED_DATE",
          plate.name AS "PLATE_NAME",
          plate.type AS "PLATE_TYPE",
          wd01.data_value AS "CASSETTE",
          wd02.data_value AS "BACKBONE",
          wd03.data_value AS "DISTRIBUTE",
          wd04.data_value AS "PASS_LEVEL",
          wd05.data_value AS "QCTEST_RESULT_ID",
          wd06.data_value AS "COLONIES_PICKED",
          wd07.data_value AS "TOTAL_COLONIES",
          wd08.data_value AS "DNA_STATUS",
          wd09.data_value AS "TARGETED_TRAP",
          wd10.data_value AS "ALLELE_NAME",
          wd11.data_value AS "CLONE_NAME",
          wd12.data_value AS "WELL_ES_CELL_LINE",
          wd13.data_value AS "WELL_SPONSOR",
          wd14.data_value AS "FIVE_ARM_PASS_LEVEL",
          wd15.data_value AS "THREE_ARM_PASS_LEVEL",
          wd16.data_value AS "LOXP_PASS_LEVEL",
          pd01.data_value AS "BACS",
          pd02.data_value AS "PLATE_ES_CELL_LINE",
          pd03.data_value AS "PLATE_SPONSOR"
    FROM well
    JOIN plate ON well.plate_id = plate.plate_id
    LEFT OUTER JOIN well_data wd01 ON wd01.well_id = well.well_id AND wd01.data_type = 'cassette'
    LEFT OUTER JOIN well_data wd02 ON wd02.well_id = well.well_id AND wd02.data_type = 'backbone'
    LEFT OUTER JOIN well_data wd03 ON wd03.well_id = well.well_id AND wd03.data_type = 'distribute'
    LEFT OUTER JOIN well_data wd04 ON wd04.well_id = well.well_id AND wd04.data_type = 'pass_level'
    LEFT OUTER JOIN well_data wd05 ON wd05.well_id = well.well_id AND wd05.data_type = 'qctest_result_id'
    LEFT OUTER JOIN well_data wd06 ON wd06.well_id = well.well_id AND wd06.data_type = 'COLONIES_PICKED'
    LEFT OUTER JOIN well_data wd07 ON wd07.well_id = well.well_id AND wd07.data_type = 'TOTAL_COLONIES'
    LEFT OUTER JOIN well_data wd08 ON wd08.well_id = well.well_id AND wd08.data_type = 'DNA_STATUS'
    LEFT OUTER JOIN well_data wd09 ON wd09.well_id = well.well_id AND wd09.data_type = 'targeted_trap'
    LEFT OUTER JOIN well_data wd10 ON wd10.well_id = well.well_id AND wd10.data_type = 'allele_name'
    LEFT OUTER JOIN well_data wd11 ON wd11.well_id = well.well_id AND wd11.data_type = 'clone_name'
    LEFT OUTER JOIN well_data wd12 ON wd12.well_id = well.well_id AND wd12.data_type = 'es_cell_line'
    LEFT OUTER JOIN well_data wd13 ON wd13.well_id = well.well_id AND wd13.data_type = 'sponsor'
    LEFT OUTER JOIN well_data wd14 ON wd14.well_id = well.well_id AND wd14.data_type = 'computed_five_arm_pass_level'
    LEFT OUTER JOIN well_data wd15 ON wd15.well_id = well.well_id AND wd15.data_type = 'computed_three_arm_pass_level'
    LEFT OUTER JOIN well_data wd16 ON wd16.well_id = well.well_id AND wd16.data_type = 'computed_loxP_pass_level'
    LEFT OUTER JOIN plate_data pd01 ON pd01.plate_id = well.plate_id AND pd01.data_type = 'bacs'
    LEFT OUTER JOIN plate_data pd02 ON pd02.plate_id = well.plate_id AND pd02.data_type = 'es_cell_line'
    LEFT OUTER JOIN plate_data pd03 ON pd03.plate_id = well.plate_id AND pd03.data_type = 'sponsor'
EOT

#__PACKAGE__->add_columns(
#    qw(
#          well_id
#          design_instance_id
#          well_name
#          parent_well_id
#          plate_id
#          plate_name
#          plate_type
#          cassette
#          backbone
#          qctest_result_id
#          distribute
#          pass_level
#          colonies_picked
#          total_colonies
#          dna_status
#          targeted_trap
#          allele_name
#          clone_name
#          well_es_cell_line
#          plate_es_cell_line
#          well_sponsor
#          plate_sponsor
#          bacs
#          five_arm_pass_level
#          three_arm_pass_level
#          loxp_pass_level
#  ),
#    created_date => { data_type => 'date' }
#
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
# WELL_DETAILS is an Oracle materialized veiw
__PACKAGE__->add_columns(
  "well_id",
  {
    data_type => "numeric",
    is_nullable => 0, # Primary keys cannot be nullable - DJP-S
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
  "parent_well_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "plate_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "plate_type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "cassette",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "backbone",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "distribute",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "qctest_result_id",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "colonies_picked",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "total_colonies",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "dna_status",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "targeted_trap",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "allele_name",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "clone_name",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "well_es_cell_line",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "well_sponsor",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "five_arm_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "three_arm_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "loxp_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "bacs",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "plate_es_cell_line",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "plate_sponsor",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'well_id' );
__PACKAGE__->belongs_to( well  => 'HTGTDB::Well' => 'well_id' );
__PACKAGE__->belongs_to( plate => 'HTGTDB::Plate' => 'plate_id' );
__PACKAGE__->belongs_to( design_instance => 'HTGTDB::DesignInstance', 'design_instance_id', { join_type => 'left' } );
__PACKAGE__->belongs_to( parent_well => 'HTGTDB::WellDetail', 'parent_well_id' );
__PACKAGE__->has_many( children => 'HTGTDB::WellDetail', 'parent_well_id' );

sub es_cell_line {
    my $self = shift;

    $self->well_es_cell_line || $self->plate_es_cell_line;
}

sub sponsor {
    my $self = shift;

    $self->well_sponsor || $self->plate_sponsor;
}

sub stringify {
    my ( $self ) = @_;
    sprintf( '%s[%s]', $self->plate_name || 'UNKNOWN PLATE', $self->well_name || 'UNNAMED WELL' );
}

sub design_well {
    my ( $self ) = @_;

    my $well = $self;
    while ( $well and $well->plate->type ne 'DESIGN' ) {
        $well = $well->parent_well;
    }

    return $well;        
}

sub descendants {
    my ( $self ) = @_;

    _descendants_r( $self );
}

sub _descendants_r {

    my @descendants;
    for my $c ( map $_->children, @_ ) {
        push @descendants, $c, _descendants_r( $c );
    }

    return @descendants;
}

1;

__END__

=head1 NAME

HTGTDB::WellDetail - DBIx::Class view for well_detail

=head1 SYNOPSIS

   use HTGTDB::DBFactory;
   my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );
   my $well = $htgt->resultset( 'WellDetail' )->find( { well_id => 46022 } );
   print join( " ", $well->plate_name, $well->plate_type, $well->cassette ) . "\n";


=head1 DESCRIPTION

This module defines a L<DBIx::Class::ResultSource::View> that joins the C<well> table with the
C<plate>, C<plate_data> and C<well_data> tables, simplifying access to a number of commonly used
data items.

=head1 METHODS

=over

=item well_id

=item well_name

=item design_instance_id

=item parent_well_id

=item plate_id

=item plate_name

=item plate_type

=item bacs

=item es_cell_line

=item cassette

=item backbone

=item distribute

=item pass_level

=item qctest_result_id

=item colonies_picked

=item total_colonies

=item targeted_trap

=item allele_name

=item clone_name

=back

=head1 SEE ALSO

L<DBIx::Class::ResultSource::View>, L<HTGTDB::Well>, L<HTGTDB::WellData>, L<HTGTTDB::Plate>,
L<HTGTDB::PlateData>.

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
