package HTGT::Utils::Recovery::Report::GatewayDistribute;

use Moose;
use namespace::autoclean;
use Iterator;
use List::MoreUtils 'all';

with qw( HTGT::Utils::Report::GenericIterator MooseX::Log::Log4perl );

sub _build_name {
    'Gateway Recovery Distributable Vectors'
}

sub _build_columns {
    [ qw( recovery_plate marker_symbol unique_to_plate plates_with_distributes ) ]
}

sub _build_iterator {
    my $self = shift;

    my $dbh = $self->schema->storage->dbh;
    local $dbh->{FetchHashKeyName} = 'NAME_lc';
    
    my $sth = $dbh->prepare( <<'EOT' );
select distinct regexp_replace( target_plate.name, '_[[:digit:]]$', '' ) as recovery_plate, mgi_gene.marker_symbol, plate.name as plate_name
from mgi_gene
join project
  on project.mgi_gene_id = mgi_gene.mgi_gene_id
  and project.design_instance_id is not null
  and ( project.is_komp_csd = 1 or project.is_eucomm = 1 )
join well
  on well.design_instance_id = project.design_instance_id
join well_data wd1
  on wd1.well_id = well.well_id
  and wd1.data_type = 'distribute'
  and wd1.data_value = 'yes'  
join plate
  on plate.plate_id = well.plate_id
  and plate.type in ( 'PGD', 'GR' )
join project target_project
  on target_project.mgi_gene_id = mgi_gene.mgi_gene_id
join well target_well
  on target_well.design_instance_id = target_project.design_instance_id
  and target_well.design_instance_id is not null
join plate target_plate
  on target_plate.plate_id = target_well.plate_id
join plate_data target_plate_data
  on target_plate_data.plate_id = target_plate.plate_id
  and target_plate_data.data_type = 'gateway_recovery'
  and target_plate_data.data_value = 'yes'
order by 1,2,3
EOT
    
    $sth->execute;
    
    my $this_row = $sth->fetchrow_hashref;

    return Iterator->new (
        sub {
            Iterator::is_done unless $this_row;
            my $plate  = $this_row->{recovery_plate};
            my $marker = $this_row->{marker_symbol};
            my @dist = ( $this_row->{plate_name} );
            my $next_row;
            while ( $next_row = $sth->fetchrow_hashref
                        and $next_row->{recovery_plate} eq $plate
                            and $next_row->{marker_symbol} eq $marker ) {
                push @dist, $next_row->{plate_name};
            }
            $this_row = $next_row;            
            my $is_uniq = all { $_ =~ qr/^\Q$plate\E/ } @dist;
            return {
                recovery_plate          => $plate,
                marker_symbol           => $marker,
                unique_to_plate         => $is_uniq ? 1 : 0,
                plates_with_distributes => join( q{, }, @dist )
            };
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
