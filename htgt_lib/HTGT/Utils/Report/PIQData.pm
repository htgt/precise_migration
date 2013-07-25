package HTGT::Utils::Report::PIQData;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( get_piq_data ) ]
};

use Const::Fast;

const my $GET_COLUMNS_QUERY => <<'EOT';
select distinct data_type
from well_data
join well on well.well_id = well_data.well_id
join plate on plate.plate_id = well.plate_id
where plate.type = 'PIQ'
and data_type not in ( 'cassette', 'backbone' )
order by data_type
EOT

const my $GET_TAQMAN_DATA => <<'EOT';
select DISTINCT design_taqman_assay.design_id, design_taqman_assay.assay_id, design_taqman_assay.deleted_region
from well
join plate on well.plate_id = plate.plate_id
join design_instance on design_instance.design_instance_id = well.design_instance_id
join design_taqman_assay on design_taqman_assay.design_id = design_instance.design_id
where plate.type = 'PIQ'
EOT

const my $GET_DNA_PLATE_DATA => <<'EOT';
select parent_well.well_name as parent_well, plate.type plate_type, plate.name plate_name, well.well_name
from well inner join plate on plate.plate_id = well.plate_id
join well parent_well on parent_well.well_id = well.parent_well_id
join plate parent_plate on parent_plate.plate_id = parent_well.plate_id
where plate.type IN ('SBDNA', 'QPCRDNA')
EOT

const my $GET_DATA_QUERY => <<'EOT';
select grandparent_well.well_name, well_data.data_type, well_data.data_value, well_data.edit_date, mgi_gene.marker_symbol, design.design_id, coalesce( design.design_type, 'KO' ) as design_type
from plate
join well on well.plate_id = plate.plate_id
left outer join well_data on well_data.well_id = well.well_id and well_data.data_type not in ( 'cassette', 'backbone' )
join well parent_well on parent_well.well_id = well.parent_well_id
join well grandparent_well on grandparent_well.well_id = parent_well.parent_well_id
join project on project.design_instance_id = grandparent_well.design_instance_id
join mgi_gene on mgi_gene.mgi_gene_id = project.mgi_gene_id
join design on design.design_id = project.design_id
where plate.type = 'PIQ'
order by well_name
EOT

sub get_piq_data {
    my $schema = shift;

    $schema->storage->dbh_do( \&_get_piq_data );
}

sub _get_piq_data {
    my ( $storage, $dbh ) = @_;

    my $columns = $dbh->selectcol_arrayref( $GET_COLUMNS_QUERY );

    my @csv_header = (
        'well_name', 'marker_symbol', 'design_id', 'design_type', 'targeting_pass_date',
        'taqman_assays', 'sbdna_wells', 'qpcrdna_wells', @{$columns}
    );
    my @data = ( \@csv_header );

    my $taqman_data    = _get_taqman_data( $dbh );
    my $dna_plate_data = _get_dna_plate_data( $dbh );

    my $sth = $dbh->prepare( $GET_DATA_QUERY );
    $sth->execute;

    my $r = $sth->fetchrow_hashref( 'NAME_lc' );
    
    while ( $r ) {
        my $well_name     = $r->{well_name};
        my $marker_symbol = $r->{marker_symbol};        
        my $design_id     = $r->{design_id};
        my $design_type   = $r->{design_type};
        my $taqman_data   = $taqman_data->{$design_id};
        my $sbdna_data    = join ' : ', @{ $dna_plate_data->{$well_name}{SBDNA} }
            if exists $dna_plate_data->{$well_name}{SBDNA};
        my $qpcrdna_data  = join ' : ', @{ $dna_plate_data->{$well_name}{QPCRDNA} }
            if exists $dna_plate_data->{$well_name}{QPCRDNA};

        my ( %well_data, $targeting_pass_date );
        while ( $r and $well_name eq $r->{well_name} ) {
            if ( defined $r->{data_type} ) {                
                $well_data{ $r->{data_type} } = $r->{data_value};
                if ( $r->{data_type} eq 'targeting_pass' ) {
                    $targeting_pass_date = $r->{edit_date};
                }                
            }            
            $r = $sth->fetchrow_hashref( 'NAME_lc' );
        }
        push @data, [ $well_name, $marker_symbol, $design_id, $design_type, 
                      $targeting_pass_date, $taqman_data, $sbdna_data, $qpcrdna_data, 
                      @well_data{ @{$columns} } ];
    }
    
    return \@data;
}

sub _get_taqman_data {
    my $dbh = shift;
    my %taqman_data;

    my $sth = $dbh->prepare( $GET_TAQMAN_DATA );
    $sth->execute;

    while ( my $r = $sth->fetchrow_hashref( 'NAME_lc' ) ) {
        my $taqman_assay = $r->{assay_id} . ' (' . $r->{deleted_region} . ')';
        if ( exists $taqman_data{$r->{design_id}} ) {
            $taqman_data{$r->{design_id}} .= ', ' .  $taqman_assay;
        } 
        else {
            $taqman_data{$r->{design_id}} = $taqman_assay;
        }
    }

    return \%taqman_data;
}

sub _get_dna_plate_data {
    my $dbh = shift;
    my %data;

    my $sth = $dbh->prepare( $GET_DNA_PLATE_DATA );
    $sth->execute;

    while ( my $r = $sth->fetchrow_hashref( 'NAME_lc' ) ) {
        my $dna_well = $r->{plate_name} . '_' . $r->{well_name};
        push @{ $data{ $r->{parent_well} }{ $r->{plate_type} } }, $dna_well;
    }

    return \%data;
}

1;

__END__
