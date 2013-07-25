package HTGT::Utils::FPData;

use strict;
use warnings FATAL => 'all';
use Const::Fast;

use Sub::Exporter -setup => {
    exports => [ qw ( get_fp_data ) ]
};

const my $GET_EPD_WELL_DATA_QUERY => <<'EOT';
select well.well_name, well.well_id, well_data.data_value, well_data.data_type
from mgi_gene
join project on project.mgi_gene_id = mgi_gene.mgi_gene_id
join well on well.design_instance_id = project.design_instance_id
join plate on well.plate_id = plate.plate_id
left outer join well_data on well.well_id = well_data.well_id and (
  well_data.data_type = 'computed_five_arm_pass_level'
  or well_data.data_type = 'computed_three_arm_pass_level'
  or well_data.data_type = 'computed_loxP_pass_level'
  or well_data.data_type = 'distribute'
  or well_data.data_type = 'targeted_trap'
)
where mgi_gene.mgi_accession_id = ?
and plate.type = 'EPD'
order by well.well_id
EOT

const my $GET_LOA_WELL_DATA_QUERY => <<'EOT';
select well.well_name, well_data.data_value, well_data.data_type
from well
join plate on plate.plate_id = well.plate_id
join well_data on well.well_id = well_data.well_id
where well.parent_well_id = ?
and (
  well_data.data_type = 'taqman_loxp_qc_result'
  or well_data.data_type = 'loa_qc_result'
)
and plate.type = 'REPD'
EOT

const my $GET_FP_WELL_NAMES_QUERY => <<'EOT';
select well.well_name from well
join plate on plate.plate_id = well.plate_id
where well.parent_well_id = ?
and plate.type = 'FP'
EOT

sub get_fp_data {
    my ( $dbh, $mgi_accession_id ) = @_;

    my $sth = $dbh->prepare( $GET_EPD_WELL_DATA_QUERY );
    $sth->execute( $mgi_accession_id );

    my @fp_wells;
    
    my $r = $sth->fetchrow_hashref( 'NAME_uc' );

    while ( $r ) {
        my %well_data = (
            well_id       => $r->{WELL_ID},
            epd_well_name => $r->{WELL_NAME}
        );        
        while ( $r and $r->{WELL_ID} == $well_data{well_id} ) {
            $r->{DATA_TYPE} =~ s/^computed_//;
            $well_data{ $r->{DATA_TYPE} } = $r->{DATA_VALUE};
            $r = $sth->fetchrow_hashref( 'NAME_uc' );
        }

        my $loa_data = get_loa_well_data( $dbh, $well_data{well_id} );
        for my $fp_well_name ( @{ get_fp_well_names( $dbh, $well_data{well_id} ) } ) {
            push @fp_wells, { %{ $loa_data }, %well_data, fp_well_name => $fp_well_name };            
        }
    }

    return \@fp_wells;
}

sub get_loa_well_data {
    my ( $dbh, $epd_well_id ) = @_;

    my $sth = $dbh->prepare( $GET_LOA_WELL_DATA_QUERY );
    $sth->execute( $epd_well_id );

    my %loa_data;    
    while ( my $loa_well_rs = $sth->fetchrow_hashref( 'NAME_uc' ) ){

        my ( $data_type, $data_value ) = @{$loa_well_rs}{ qw( DATA_TYPE DATA_VALUE ) };

        if ( defined $loa_data{$data_type} and $loa_data{$data_type} ne $data_value ) {
            die "Inconsistent $data_type LOA data for well $epd_well_id";
        }

        $loa_data{$data_type} = $data_value;
    }

    return \%loa_data;
}

sub get_fp_well_names {
    my ( $dbh, $epd_well_id ) = @_;

    return $dbh->selectcol_arrayref( $GET_FP_WELL_NAMES_QUERY, {}, $epd_well_id );
}

1;
