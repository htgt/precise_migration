package HTGT::Utils::Report::Recovery;

use warnings;
use strict;
use HTGT::Utils::DBI;

use base 'Exporter';

BEGIN {
    our @EXPORT = qw(
        get_gene_recovery_counts
        read_gene_recovery_table
    );
    our @EXPORT_OK   = @EXPORT;
    our %EXPORT_TAGS = ();
}

sub read_gene_recovery_table {
    my ( $opts) = @_;
    
    my $base_recovery_report_by_program_and_status_sql = qq[
        select distinct
        mgi_gene.marker_symbol, 
        gene_recovery.rdr_plates, 
        gene_recovery.rdr_attempts, 
        gene_recovery.rdr_candidate_evidence, 
        gene_recovery.gwr_plates, 
        gene_recovery.gwr_attempts,
        gene_recovery.gwr_candidate_evidence, 
        gene_recovery.acr_plates, 
        gene_recovery.acr_attempts, 
        gene_recovery.acr_candidate_evidence, 
        project_status.order_by, project_status.name, project.design_plate_name, project.design_well_name, project.targvec_plate_name, project.targvec_well_name
        from 
        mgi_gene, gene_recovery, project, project_status
        where 
            mgi_gene.mgi_gene_id = gene_recovery.mgi_gene_id
            and project.mgi_gene_id = mgi_gene.mgi_gene_id
            and project.project_status_id = project_status.project_status_id
            and project.is_latest_for_gene = 1
        
    ];

    my $is_eucomm = $opts->{ 'is_eucomm' };
    my $is_komp_csd = $opts->{ 'is_komp_csd' };
    my $stage = $opts->{ 'stage' };
    my $dbh = $opts->{dbh};
    die "database handle must be passed in" unless ($dbh);
    

    my $stage_sql = '';
    my $status_sql = '';
    my $program_sql = '';
    
    my $addon_sql = '';
    
    if($stage eq 'acr_initiation'){
        $stage_sql = ' and acr_candidate_evidence is not null ';
    }elsif($stage eq 'gwr_initiation'){
        $stage_sql = ' and gwr_candidate_evidence is not null ';
    }elsif($stage eq 'rdr_initiation'){
        $stage_sql = ' and rdr_candidate_evidence is not null ';
    }elsif($stage eq 'acr'){
        $stage_sql = ' and acr_attempts > 0 ';
    }elsif($stage eq 'gwr'){
        $stage_sql = ' and gwr_attempts > 0 ';
    }elsif($stage eq 'rdr'){
        $stage_sql = ' and rdr_attempts > 0 ';
    }
    
    if ($is_eucomm){
        $program_sql = qq[ and is_eucomm = 1 ];
    }elsif ($is_komp_csd){
        $program_sql = qq[ and is_komp_csd = 1 ];
    }
    
    $addon_sql = $program_sql . $stage_sql . $status_sql . q[ order by marker_symbol ];
    
    my $sql = $base_recovery_report_by_program_and_status_sql . $addon_sql;
    
    #First argument is unneccessary catalyst object.
    my $data = HTGT::Utils::DBI::process_statement( undef, $dbh, $sql );
  
    my $return_data;
    $return_data->{columns} = $data->{columns};
    $return_data->{rows} = $data->{rows};
    return $return_data;
}

sub get_komp_genes_for_rdr_recovery {
    my ( $self, $opts ) = @_;
    my $return_data = $self->read_gene_recovery_table($opts);
    return $return_data;
}

sub get_eucomm_genes_for_rdr_recovery {
    my ( $self, $c ) = @_;
    my $return_list;
}

sub get_komp_genes_for_gwr_recovery {
    my ( $self, $c ) = @_;
    my $return_list;
}

sub get_eucomm_genes_for_gwr_recovery {
    my ( $self, $c ) = @_;
    my $return_list;
}

sub get_gene_recovery_counts {
    my $c = shift;
    my $return_hash = {};
    my $eucomm_genes_for_rdr;
    my $eucomm_genes_for_gwr;
    my $komp_genes_for_rdr;
    my $komp_genes_for_gwr;
    $return_hash->{komp_genes_for_gwr} = $eucomm_genes_for_rdr;
    $return_hash->{komp_genes_for_rdr} = $eucomm_genes_for_gwr;
    $return_hash->{eucomm_genes_for_rdr} = $komp_genes_for_rdr;
    $return_hash->{eucomm_genes_for_gwr} = $komp_genes_for_gwr;
    
    #$c->log->debug("Entering recovery counts");
    my $root_sql = qq [
        select count (distinct(mgi_gene.mgi_gene_id)) gene_count
        from 
        mgi_gene, gene_recovery, project
        where 
        mgi_gene.mgi_gene_id = gene_recovery.mgi_gene_id
        and project.mgi_gene_id = mgi_gene.mgi_gene_id
    ];
    
    my $sql_additions = {
        'eucomm_genes_for_gwr' => " and is_eucomm = 1 and gwr_candidate_evidence is not null",
        'eucomm_genes_for_rdr' => " and is_eucomm = 1 and rdr_candidate_evidence is not null",
        'komp_genes_for_gwr' => " and is_komp_csd = 1 and gwr_candidate_evidence is not null",
        'komp_genes_for_rdr' => " and is_komp_csd = 1 and rdr_candidate_evidence is not null"
    };
    
    foreach my $addition_key (keys %{$sql_additions}){
        my $sth = $c->model('HTGTDB')->storage->dbh->prepare($root_sql . $sql_additions->{$addition_key});
        $sth->execute();
        $return_hash->{$addition_key} = $sth->fetchrow_arrayref->[0];
        #$c->log->debug("AFTER COUNTS FOR $addition_key");
        #$c->log->debug(Data::Dumper->Dump([$return_hash]));
    }
    
    my $base_status_sql = qq[
        select nvl(is_komp_csd, 0) is_komp, nvl(is_eucomm, 0) is_eucomm, project.project_status_id, project_status.code, project_status.order_by, count(*) gene_number
        from project_status, project
        where 
        project.project_status_id = project_status.project_status_id
        and (is_eucomm = 1 or is_komp_csd = 1)
        and (is_trap is null or is_trap = 0)
        and is_latest_for_gene = 1
        group by nvl(is_komp_csd, 0), nvl(is_eucomm, 0), project.project_status_id, project_status.code, project_status.order_by
        order by nvl(is_komp_csd, 0), nvl(is_eucomm, 0), project_status.order_by desc
    ];
    
    my $sth = $c->model('HTGTDB')->storage->dbh->prepare($base_status_sql);
    $sth->execute();
    
    while(my $result = $sth->fetchrow_hashref){
        if($result->{IS_EUCOMM}){
            $return_hash->{$result->{CODE}}->{eucomm}->{base} = $result->{GENE_NUMBER};
        }else{
            $return_hash->{$result->{CODE}}->{komp}->{base} = $result->{GENE_NUMBER};
        }
    }
    
    #$c->log->debug("AFTER BASE STATUS: ");
    #$c->log->debug(Data::Dumper->Dump([$return_hash]));
        
    my $base_recovery_status_sql = qq[
        select project_status.code, nvl(is_eucomm, 0) is_eucomm, nvl(is_komp_csd, 0) is_komp, count(distinct(project.mgi_gene_id)) gene_number
        from project, gene_recovery, project_status
        where 
        project.project_status_id = project_status.project_status_id
        and gene_recovery.mgi_gene_id = project.mgi_gene_id
        and is_latest_for_gene = 1
        and (is_eucomm = 1 or is_komp_csd = 1)
        
    ];

    my $sql_adds = {
        'acr' => " and gene_recovery.acr_attempts > 0 group by nvl(is_eucomm, 0), nvl(is_komp_csd, 0), project_status.code ",
        'gwr' => " and gene_recovery.gwr_attempts > 0 group by nvl(is_eucomm, 0), nvl(is_komp_csd, 0), project_status.code ",
        'rdr' => " and gene_recovery.rdr_attempts > 0 group by nvl(is_eucomm, 0), nvl(is_komp_csd, 0), project_status.code "
    };
        
    #$c->log->debug("before executing the recovery results");
    foreach my $addition_key (keys %{$sql_adds}){
        #$c->log->debug("SQL ADD KEY: $addition_key");
        my $sum_sql = $base_recovery_status_sql . $sql_adds->{$addition_key};
        #$c->log->debug(" sql : $sum_sql ");
        
        my $sth = $c->model('HTGTDB')->storage->dbh->prepare($base_recovery_status_sql . $sql_adds->{$addition_key});
        $sth->execute();
        while(my $result = $sth->fetchrow_hashref){
            if($result->{IS_EUCOMM}){
                #$c->log->debug(" STATUS: ".$result->{CODE}." EUCOMM addition key: $addition_key number : " . $result->{GENE_NUMBER});
                $return_hash->{$result->{CODE}}->{eucomm}->{$addition_key} = $result->{GENE_NUMBER};
            }else{
                #$c->log->debug(" STATUS: ".$result->{CODE}." KOMP addition key: $addition_key number : " . $result->{GENE_NUMBER});
                $return_hash->{$result->{CODE}}->{komp}->{$addition_key} = $result->{GENE_NUMBER};
            }
        }
        #$c->log->debug("recovery_status $addition_key");
        #$c->log->debug(Data::Dumper->Dump([$return_hash]));
    }
    
    $c->log->debug(Data::Dumper->Dump([$return_hash]));
    return $return_hash;
}

1;
