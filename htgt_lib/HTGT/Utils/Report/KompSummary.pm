package HTGT::Utils::Report::KompSummary;

use strict;
use warnings FATAL => 'all';

use base 'Exporter';

BEGIN {
    our @EXPORT      = qw( get_komp_summary_data get_komp_summary_columns );
    our @EXPORT_OK   = @EXPORT;
    our %EXPORT_TAGS = ();
}

use Const::Fast;
use List::MoreUtils 'zip';

const my @COLUMN_NAMES => ( 'Marker Symbol', 'MGI Accession Id', 'Total Count', 'Conditional Count','Consortium');

const my $DIST_TRAP_COUNT_QUERY => <<'EOT';
select marker_symbol, mgi_accession_id, sum(cond_count) + sum(trap_count), sum(cond_count),
case 
when is_komp_csd=1 then 'komp_csd'
when is_komp_regeneron=1 then 'komp_regeneron'
when is_eucomm=1 then 'eucomm'
when is_eucomm_tools=1 then 'eucomm_tools'
when is_eucomm_tools_cre=1 then 'eucomm_tools_cre'
when is_eutracc=1 then 'eutracc'
when is_norcomm=1 then 'norcomm'
when is_mgp=1 then 'mgp'
else 'other'
end
from
  (
    select marker_symbol, mgi_accession_id, 
    project.is_komp_csd, project.is_komp_regeneron, 
    project.is_eucomm, project.is_eucomm_tools, project.is_eucomm_tools_cre,
    project.is_eutracc, project.is_norcomm, project.is_mgp,
    (
       select count(distinct epd_well_id) 
       from well_summary_by_di ws, design_instance di, design d 
       where ws.project_id = project.project_id 
       and ws.epd_distribute = 'yes'
       and ws.design_instance_id = di.design_instance_id
       and di.design_id = d.design_id
       and (d.design_type is null or d.design_type like 'KO%')
    ) as cond_count,
    (
       select count(distinct epd_well_id)
       from well_summary_by_di
       where well_summary_by_di.project_id = project.project_id
       and well_summary_by_di.targeted_trap = 'yes'
    ) as trap_count
    
    from project
    join mgi_gene on mgi_gene.mgi_gene_id = project.mgi_gene_id
    
    where ( project.vector_only is null or project.vector_only = 0 )
  )
where cond_count > 0 or trap_count > 0
group by marker_symbol, mgi_accession_id,
is_komp_csd, is_komp_regeneron, 
is_eucomm, is_eucomm_tools, is_eucomm_tools_cre,
is_eutracc, is_norcomm, is_mgp
order by marker_symbol
EOT

sub get_komp_summary_columns {    
    return \@COLUMN_NAMES;
}

sub get_komp_summary_data {
    my ( $schema ) = @_;

    my @data;
    
    my $sth = $schema->storage->dbh->prepare( $DIST_TRAP_COUNT_QUERY );
    $sth->execute;

    while ( my $d = $sth->fetchrow_arrayref ) {
        push @data, { zip @COLUMN_NAMES, @{$d} };
    }

    return \@data;
}

1;

__END__
