package HTGT::Controller::Report::AssignedGenesAndClones;

use warnings;
use strict;
#use Exporter();

=head1 NAME

HTGT::Controller::Report::AssignedGenesAndClones;

=head1 AUTHOR

Vivek Iyer vvi@sanger.ac.uk

=cut

=head2 index 

=cut

our @ISA     = qw(Exporter);

#The methods that we want to export
our @EXPORT_OK  = qw(get_clones_by_gene get_unassigned_genes get_genes_or_cells_in_conflict get_assigned_genes_and_clones get_clones_by_epd); 


=head2 get_unassigned_genes
Get a list of genes which have distributed cells, where
none of the cells have been assigned to other centers.
=cut
sub get_unassigned_genes {
    my ($c) = @_;
    
    my $return_ref;
    
    # 1. get all gene-ids for distributable cells,
    # 2. MINUS gene-ids for already assigned / injected
    # -- that yields a list of gene-ids which can be assigned.

    my $all_distributable_genes_query = qq [
        select
           mgi_gene.mgi_gene_id,
           mgi_gene.MARKER_SYMBOL,
           count(distinct(s.epd_well_id)),
           project.is_komp_csd,
           project.is_eucomm,
           project.is_mgp,
           s.ES_CELL_LINE,
           s.ep_plate_name
        from
        well_summary_by_di s, 
        mgi_gene,
        project
        where s.epd_distribute = 'yes' 
        and project.project_id = s.project_id
        and mgi_gene.mgi_gene_id = project.mgi_gene_id
        group by mgi_gene.MGI_GENE_ID, mgi_gene.MARKER_SYMBOL, project.is_komp_csd, project.is_eucomm, is_mgp, s.es_cell_line, s.ep_plate_name
    ];
    
    my $all_genes_assigned_via_clones_query = qq [
    select distinct(mgi_gene.mgi_gene_id)
    from mgi_gene,
    project,
    well_summary_by_di ws,
    well_data
    where mgi_gene.mgi_gene_id = project.mgi_gene_id
    and project.project_id = ws.project_id
    and ws.epd_well_id = well_data.WELL_ID
    and ( well_data.data_type like 'cell_%_status' )
    and ( well_data.data_value = 'assigned' or well_data.data_value = 'injected' )
    ];
    
    my $sth = $c->model('HTGTDB')->storage->dbh->prepare($all_distributable_genes_query);
    $sth->execute();
    while(my @result = $sth->fetchrow_array()){
        my $source;
        my $mgp;
       
        #$c->log->debug("cell line: ".$result[6]);
       
        if($result[3] and $result[3] == 1){
            $source = 'KOMP';
        }
        if($result[4] and $result[4] == 1){
            $source = 'EUCOMM';
        }
        if($result[5] and $result[5] == 1){
            $mgp = "yes";
        }    

        if( $source ){
            $return_ref->{$result[0]} = {
                name=>$result[1],
                cell_count=>$result[2],
                source=>$source,
                mgp => $mgp,
                cell_line => $result[6],
                ep_plate => $result[7]
            };
        }
    }
    $sth = $c->model('HTGTDB')->storage->dbh->prepare($all_genes_assigned_via_clones_query);
    $sth->execute();
    while(my @result = $sth->fetchrow_array()){
        delete ($return_ref->{$result[0]});
    }
   
   return $return_ref; 
}

=head2 genes_or_cells_in_conflict

print out
- Genes with assignments to two parties (and any clones)
- Gen
es with CLONES assigned to two different parties
- Genes where the CLONES have been assigned, but the GENES havent

=cut
sub get_genes_or_cells_in_conflict {
    my ($c) = @_;
    
    my $multiple_assigned_genes_query = qq[
        select *
        from (
          select 
          gene_info.gene_id, sng_status, mrc_status, ics_status, gsf_status, cnr_status,
          decode(sng_status, 'assigned',1, 'interest', 0, 'injected', 1, null, 0)+
          decode(mrc_status, 'assigned',1, 'interest', 0, 'injected', 1, null, 0)+
          decode(ics_status, 'assigned',1, 'interest', 0, 'injected', 1, null, 0)+
          decode(gsf_status, 'assigned',1, 'interest', 0, 'injected', 1, null, 0)+
          decode(cnr_status, 'assigned',1, 'interest', 0, 'injected', 1, null, 0) gene_sum
          from gene_info
          where  (
          sng_status is not null or 
          mrc_status is not null or 
          ics_status is not null or 
          gsf_status is not null or 
          cnr_status is not null
          )
        )
        where gene_sum > 1
    ];
    
    my $genes_ref;
    
    my $genes_sth = $c->model('HTGTDB')->storage->dbh->prepare($multiple_assigned_genes_query);
    $genes_sth->execute();
    while(my $result = $genes_sth->fetchrow_hashref){
        my $gene = {};
        $gene->{name} = $result->{PRIMARY_NAME};
        if($result->{GSF_STATUS} =~ /injected/i){
            $gene->{gsf_status} = 'G[I]';
        }elsif($result->{GSF_STATUS} =~ /assigned/i){
            $gene->{gsf_status} = 'G[A]';
        }
        
        if( $result->{SNG_STATUS}  =~ /injected/i){
            $gene->{sng_status} = 'S[I]';
        }elsif($result->{SNG_STATUS} =~ /assigned/i){
            $gene->{sng_status} = 'S[A]';
        }
        
        if( $result->{MRC_STATUS}  =~ /injected/i){
            $gene->{mrc_status} = 'M[I]';
        }elsif($result->{MRC_STATUS} =~ /assigned/i){
            $gene->{mrc_status} = 'M[A]';
        }
        
        if( $result->{ICS_STATUS}  =~ /injected/i){
            $gene->{ics_status} = 'I[I]';
        }elsif($result->{ICS_STATUS} =~ /assigned/i){
            $gene->{ics_status} = 'I[A]';
        }
        
        if( $result->{CNR_STATUS}  =~ /injected/i){
            $gene->{cnr_status} = 'C[I]';
        }elsif($result->{CNR_STATUS} =~ /assigned/i){
            $gene->{cnr_status} = 'C[A]';
        }
    }
    
    my $genes_and_cells_query_old = qq[
        select
        distinct
        gnm_gene.PRIMARY_NAME, gene_info.SNG_STATUS, gene_info.mrc_status, gene_info.ICS_STATUS, gene_info.GSF_STATUS, gene_info.CNR_STATUS,
        well_summary.es_cell_line cell_line,
        epd_well.well_id epd_well_id, epd_well.well_name epd_well_name,
        fp_well.well_name fp_well_name, 
        epd_well_data2.data_type  cell_center, epd_well_data2.data_value cell_center_status,
        ( select data_value from well_data where well_data.well_id = epd_well.well_id and well_data.data_type like 'cell_sng_assign_date' ) sng_assign_date,
        ( select data_value from well_data where well_data.well_id = epd_well.well_id and well_data.data_type like 'cell_mrc_assign_date' ) mrc_assign_date,
        ( select data_value from well_data where well_data.well_id = epd_well.well_id and well_data.data_type like 'cell_ics_assign_date' ) ics_assign_date,
        ( select data_value from well_data where well_data.well_id = epd_well.well_id and well_data.data_type like 'cell_gsf_assign_date' ) gsf_assign_date,
        ( select data_value from well_data where well_data.well_id = epd_well.well_id and well_data.data_type like 'cell_cnr_assign_date' ) cnr_assign_date
        from
        mig.gnm_gene,
        gene_info,
        well_summary,
        well epd_well,
        well fp_well,
        well_data epd_well_data2
        where
        gnm_gene.id = well_summary.gene_id
        and gene_info.gene_id = well_summary.gene_id
        and fp_well.parent_well_id = epd_well.well_id
        and well_summary.epd_well_id = epd_well.well_id
        and epd_well.well_id = epd_well_data2.well_id
        and ( epd_well_data2.data_type like 'cell_%_status' )
        and ( epd_well_data2.data_value = 'assigned' or epd_well_data2.data_value = 'injected' )
    ];

    my $genes_and_cells_query = qq[
       select
        distinct
        mgi_gene.marker_symbol PRIMARY_NAME,
        gene_info.SNG_STATUS, gene_info.mrc_status,
        gene_info.ICS_STATUS, gene_info.GSF_STATUS, gene_info.CNR_STATUS,
        well_summary_by_di.es_cell_line cell_line,
        well_summary_by_di.epd_well_id, well_summary_by_di.epd_well_name,
        fp_well.well_name fp_well_name,
        well_data.data_type  cell_center, well_data.data_value cell_center_status,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_sng_assign_date' ) sng_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_mrc_assign_date' ) mrc_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_ics_assign_date' ) ics_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_gsf_assign_date' ) gsf_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_cnr_assign_date' ) cnr_assign_date
        from
        mgi_gene,
        gene_info,
        project,
        well_summary_by_di,
        well fp_well,
        well_data
        where
        mgi_gene.marker_symbol = gene_info.mgi_symbol
        and mgi_gene.mgi_gene_id = project.mgi_gene_id
        and well_summary_by_di.project_id = project.project_id
        and well_summary_by_di.epd_well_id = well_data.well_id
        and fp_well.parent_well_id = well_summary_by_di.EPD_WELL_ID
        and ( well_data.data_type like 'cell_%_status' )
        and (well_data.data_value = 'assigned' or well_data.data_value = 'injected')   
    ];

    my $sth = $c->model('HTGTDB')->storage->dbh->prepare($genes_and_cells_query);
    $sth->execute();
    
    while(my $result = $sth->fetchrow_hashref){
         
        my $name = $result->{PRIMARY_NAME};
        my $epd_well_name = $result->{EPD_WELL_NAME};
        my $fp_well_name = $result->{FP_WELL_NAME};
        
        my $center = $result->{CELL_CENTER};
        my $center_status = $result->{CELL_CENTER_STATUS};
        my $sng_assign_date = $result->{SNG_ASSIGN_DATE};
        my $cnr_assign_date = $result->{CNR_ASSIGN_DATE};
        my $gsf_assign_date = $result->{GSF_ASSIGN_DATE};
        my $mrc_assign_date = $result->{MRC_ASSIGN_DATE};
        my $ics_assign_date = $result->{ICS_ASSIGN_DATE};
        
        my $cell_string = "[ $epd_well_name  ${fp_well_name}  ";
        
        # The simple fact that you're in this loop means this epd well was either assigned or injected
        if($center_status =~ /assigned/i){
            $cell_string .= " ASN ";
        }elsif($center_status =~ /injected/i){
            $cell_string .= " INJ ";
        }
        
        # The the data-KEY will tell you whether which center it went to.
        # IF it went to sanger, bolt on the sanger assign-date, etc.
        # -- if it went to TWO places, we will see this cell again, with a second well-data row for assigned/injected.
        my $center_indicator = '';
        if($center =~ /sng/i){
            $center_indicator = 'SNG';
            $cell_string .= " SNG $sng_assign_date ]   ";
        }elsif($center =~ /gsf/i){
            $center_indicator = 'GSF';
            $cell_string .= " GSF $gsf_assign_date ]   ";
        }elsif($center =~ /ics/i){
            $center_indicator = 'ICS';
            $cell_string .= " ICS $ics_assign_date ]   ";
        }elsif($center =~ /cnr/i){
            $center_indicator = 'CNR';
            $cell_string .= " CNR $cnr_assign_date ]   ";
        }elsif($center =~ /mrc/i){
            $center_indicator = 'MRC';
            $cell_string .= " MRC $mrc_assign_date ]   ";
        }
        
        if(exists ($genes_ref->{$name})){
            
            my $gene = $genes_ref->{$name};
            $gene->{cell_string} .= $cell_string;
            $gene->{$center_indicator} = 1;
        
        }else{
            my $gene = {};
            $gene->{name} = $name;
            $gene->{$center_indicator} = 1;
            
            if($sng_assign_date){
               $gene->{assign_date} = $sng_assign_date;
            }elsif($gsf_assign_date){
               $gene->{assign_date} = $gsf_assign_date;
            }elsif($ics_assign_date){
               $gene->{assign_date} = $ics_assign_date;
            }elsif($cnr_assign_date){
               $gene->{assign_date} = $cnr_assign_date;
            }elsif($mrc_assign_date){
               $gene->{assign_date} = $mrc_assign_date;
            }
            
            if($result->{GSF_STATUS} =~ /injected/i){
                $gene->{gsf_status} = 'G[I]';
            }elsif($result->{GSF_STATUS} =~ /assigned/i){
                $gene->{gsf_status} = 'G[A]';
            }
            
            if( $result->{SNG_STATUS}  =~ /injected/i){
                $gene->{sng_status} = 'S[I]';
            }elsif($result->{SNG_STATUS} =~ /assigned/i){
                $gene->{sng_status} = 'S[A]';
            }
            
            if( $result->{MRC_STATUS}  =~ /injected/i){
                $gene->{mrc_status} = 'M[I]';
            }elsif($result->{MRC_STATUS} =~ /assigned/i){
                $gene->{mrc_status} = 'M[A]';
            }
            
            if( $result->{ICS_STATUS}  =~ /injected/i){
                $gene->{ics_status} = 'I[I]';
            }elsif($result->{ICS_STATUS} =~ /assigned/i){
                $gene->{ics_status} = 'I[A]';
            }
            
            if( $result->{CNR_STATUS}  =~ /injected/i){
                $gene->{cnr_status} = 'C[I]';
            }elsif($result->{CNR_STATUS} =~ /assigned/i){
                $gene->{cnr_status} = 'C[A]';
            }
            
            $gene->{cell_string} = $cell_string;
            $gene->{cell_line} = $result->{CELL_LINE};
            $genes_ref->{$name} = $gene;
        }
    }
    
    my $return_ref;
    
    foreach my $gene_name (keys %$genes_ref){
        my $count = 0;
        if($genes_ref->{$gene_name}->{SNG}){ $count++ };
        if($genes_ref->{$gene_name}->{CNR}){ $count++ };
        if($genes_ref->{$gene_name}->{MRC}){ $count++ };
        if($genes_ref->{$gene_name}->{GSF}){ $count++ };
        if($genes_ref->{$gene_name}->{ICS}){ $count++ };
        if($count > 1){
            $return_ref->{$gene_name} = $genes_ref->{$gene_name};
        }
    }
    
    return $return_ref;
}

sub get_assigned_genes_and_clones {
    my ( $c, $at_least_sanger, $at_least_others ) = @_;

    my $genes_ref;
    
    $c->log->debug("starting query");
    
    my $assign_genes_query;
    
    $assign_genes_query = qq [
            select mgi_gene.marker_symbol, well.well_name EPD_WELL_NAME, date_well_data.data_value ASSIGN_DATE, 'sng' centre, well_data.data_value CELL_CENTRE_STATUS,fp_well.well_name FP_WELL_NAME, well_summary_by_di.es_cell_line cell_line
            from mgi_gene, project, well_summary_by_di, well, well_data, well_data date_well_data, well fp_well
            where 
            mgi_gene.mgi_gene_id = project.mgi_gene_id
            and project.project_id = well_summary_by_di.project_id
            and well_summary_by_di.epd_well_id = well.well_id and
            well.well_id = well_data.well_id
            and well_data.data_type = 'cell_sng_status'
            and date_well_data.well_id = well.well_id
            and date_well_data.data_type = 'cell_sng_assign_date'
            and fp_well.parent_well_id = well.well_id
            and (fp_well.well_name like 'FP%' or fp_well.well_name like 'HFP%')
            union
            select mgi_gene.marker_symbol, well.well_name EPD_WELL_NAME, date_well_data.data_value ASSIGN_DATE, 'mrc' centre, well_data.data_value CELL_CENTRE_STATUS,fp_well.well_name FP_WELL_NAME, well_summary_by_di.es_cell_line cell_line
            from mgi_gene, project, well_summary_by_di, well, well_data, well_data date_well_data, well fp_well
            where 
            mgi_gene.mgi_gene_id = project.mgi_gene_id
            and project.project_id = well_summary_by_di.project_id
            and well_summary_by_di.epd_well_id = well.well_id and
            well.well_id = well_data.well_id
            and well_data.data_type = 'cell_mrc_status'
            and date_well_data.well_id = well.well_id
            and date_well_data.data_type = 'cell_mrc_assign_date'
            and fp_well.parent_well_id = well.well_id
            and (fp_well.well_name like 'FP%' or fp_well.well_name like 'HFP%')
            union
            select mgi_gene.marker_symbol, well.well_name EPD_WELL_NAME, date_well_data.data_value ASSIGN_DATE, 'ics' centre, well_data.data_value CELL_CENTRE_STATUS,fp_well.well_name FP_WELL_NAME, well_summary_by_di.es_cell_line cell_line
            from mgi_gene, project, well_summary_by_di, well, well_data, well_data date_well_data, well fp_well
            where 
            mgi_gene.mgi_gene_id = project.mgi_gene_id
            and project.project_id = well_summary_by_di.project_id
            and well_summary_by_di.epd_well_id = well.well_id and
            well.well_id = well_data.well_id
            and well_data.data_type = 'cell_ics_status'
            and date_well_data.well_id = well.well_id
            and date_well_data.data_type = 'cell_ics_assign_date'
            and fp_well.parent_well_id = well.well_id
            and (fp_well.well_name like 'FP%' or fp_well.well_name like 'HFP%')
            union
            select mgi_gene.marker_symbol, well.well_name EPD_WELL_NAME, date_well_data.data_value ASSIGN_DATE, 'cnr' centre, well_data.data_value CELL_CENTRE_STATUS,fp_well.well_name FP_WELL_NAME, well_summary_by_di.es_cell_line cell_line
            from mgi_gene, project, well_summary_by_di, well, well_data, well_data date_well_data, well fp_well
            where 
            mgi_gene.mgi_gene_id = project.mgi_gene_id
            and project.project_id = well_summary_by_di.project_id
            and well_summary_by_di.epd_well_id = well.well_id and
            well.well_id = well_data.well_id
            and well_data.data_type = 'cell_cnr_status'
            and date_well_data.well_id = well.well_id
            and date_well_data.data_type = 'cell_cnr_assign_date'
            and fp_well.parent_well_id = well.well_id
            and (fp_well.well_name like 'FP%' or fp_well.well_name like 'HFP%')
            union
            select mgi_gene.marker_symbol,
            well.well_name EPD_WELL_NAME, date_well_data.data_value ASSIGN_DATE, 'gsf' centre, well_data.data_value CELL_CENTRE_STATUS, fp_well.well_name FP_WELL_NAME, well_summary_by_di.es_cell_line cell_line
            from mgi_gene, project, well_summary_by_di, well, well_data, well_data date_well_data, well fp_well
            where 
            mgi_gene.mgi_gene_id = project.mgi_gene_id
            and project.project_id = well_summary_by_di.project_id
            and well_summary_by_di.epd_well_id = well.well_id and
            well.well_id = well_data.well_id
            and well_data.data_type = 'cell_gsf_status'
            and date_well_data.well_id = well.well_id
            and date_well_data.data_type = 'cell_gsf_assign_date'
            and fp_well.parent_well_id = well.well_id
            and (fp_well.well_name like 'FP%' or fp_well.well_name like 'HFP%')
        ];
    
    my $sth = $c->model('HTGTDB')->storage->dbh->prepare($assign_genes_query);
    
    $c->log->debug('starting query');
    
    $sth->execute();
  
    while(my $result = $sth->fetchrow_hashref){
        my $gene;
        
        if(exists $genes_ref->{$result->{MARKER_SYMBOL}}){
            $gene = $genes_ref->{$result->{MARKER_SYMBOL}};
        }else{
            $gene ={};
            $gene->{name} = $result->{MARKER_SYMBOL};
            $gene->{cell_line} = $result->{CELL_LINE};
        }
        
        my $epd_well_name = $result->{EPD_WELL_NAME};
        my $fp_well_name = $result->{FP_WELL_NAME};
        my $center = $result->{CENTRE};
        my $center_status = $result->{CELL_CENTRE_STATUS};
        my $assign_date = $result->{ASSIGN_DATE};
        
        # compile the cell detail
        my $cell_string = "[ $epd_well_name  ${fp_well_name}  ";
        
        if($center_status =~ /assigned/i){
            $cell_string .= " ASN ";
        }elsif($center_status =~ /injected/i){
            $cell_string .= " INJ ";
        }
        
        if($center =~ /sng/i){
            $cell_string .= " SNG $assign_date ]   <br> ";
        }elsif($center =~ /gsf/i){
            $cell_string .= " GSF $assign_date ]   <br>";
        }elsif($center =~ /ics/i){
            $cell_string .= " ICS $assign_date ]   <br>";
        }elsif($center =~ /cnr/i){
            $cell_string .= " CNR $assign_date ]   <br>";
        }elsif($center =~ /mrc/i){
            $cell_string .= " MRC $assign_date ]   <br>";
        }
        
        $gene->{cell_string} .= $cell_string;
        $gene->{assign_date} = $assign_date;
        
        $c->log->debug("Gene cell string now ".$gene->{cell_string});
        
        if($result->{CELL_CENTRE_STATUS} =~ /injected/i && $result->{CENTRE} =~ /gsf/i ){
            $gene->{gsf_status} = 'G[I]';
          
        }elsif($result->{CELL_CENTRE_STATUS} =~ /assigned/i && $result->{CENTRE} =~ /gsf/i){
            $gene->{gsf_status} = 'G[A]';  
        }
        
        if( $result->{CELL_CENTRE_STATUS}  =~ /injected/i && $result->{CENTRE} =~ /sng/i ){
            $gene->{sng_status} = 'S[I]';
          
        }elsif($result->{CELL_CENTRE_STATUS} =~ /assigned/i && $result->{CENTRE} =~ /sng/i){
            $gene->{sng_status} = 'S[A]';
        }
        
        if( $result->{CELL_CENTRE_STATUS}  =~ /injected/i && $result->{CENTRE} =~ /mrc/i ){
            $gene->{mrc_status} = 'M[I]';
           
        }elsif($result->{CELL_CENTRE_STATUS} =~ /assigned/i && $result->{CENTRE} =~ /mrc/i){
            $gene->{mrc_status} = 'M[A]';
        }
        
        if( $result->{CELL_CENTRE_STATUS}  =~ /injected/i && $result->{CENTRE} =~ /ics/i){
            $gene->{ics_status} = 'I[I]';
        }elsif($result->{CELL_CENTRE_STATUS} =~ /assigned/i && $result->{CENTRE} =~ /ics/i){
            $gene->{ics_status} = 'I[A]';
        }
        
        if( $result->{CELL_CENTRE_STATUS}  =~ /injected/i && $result->{CENTRE} =~ /cnr/i){
            $gene->{cnr_status} = 'C[I]';
        }elsif($result->{CELL_CENTRE_STATUS} =~ /assigned/i && $result->{CENTRE} =~ /cnr/i){
            $gene->{cnr_status} = 'C[A]';
        }
        
        $genes_ref->{$gene->{name}} = $gene; 
    }      
    
    # Now that we've compiled all the clones, sweep the gene-list again
    # and remove the genes that were not asked for.
    my $returned_genes_ref;
    
    foreach my $gene_name (keys %$genes_ref){
        
        if($at_least_sanger){
            next unless $genes_ref->{$gene_name}->{sng_status};
        }
        
        
        if($at_least_others){
            next unless (
                $genes_ref->{$gene_name}->{mrc_status} ||
                $genes_ref->{$gene_name}->{ics_status} ||
                $genes_ref->{$gene_name}->{cnr_status} ||
                $genes_ref->{$gene_name}->{gsf_status}
            );
        }
        
        $returned_genes_ref->{$gene_name} = $genes_ref->{$gene_name};
    }
    
    return $returned_genes_ref;
    #return $genes_ref;
}

sub get_clones_by_gene {
    my ($c, $gene_symbol) = @_;
    
    my $returned_genes = {};
   
    my $sql = qq [
        select distinct
        mgi_gene.mgi_gene_id GENE_ID,
        mgi_gene.marker_symbol PRIMARY_NAME,
        well_summary_by_di.es_cell_line cell_line,
        well_summary_by_di.epd_well_id,
        well_summary_by_di.epd_well_name,
        fp_well.well_name fp_well_name, fp_well.well_id fp_well_id,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type = 'pass_level' ) pass_level,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type = 'distribute' ) distribute,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type = 'targeted_trap' ) targeted_trap,        
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_sng_assign_date' ) sng_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_mrc_assign_date' ) mrc_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_ics_assign_date' ) ics_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_gsf_assign_date' ) gsf_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_cnr_assign_date' ) cnr_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_sng_status' ) sng_assign_status,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_mrc_status' ) mrc_assign_status,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_ics_status' ) ics_assign_status,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_gsf_status' ) gsf_assign_status,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_cnr_status' ) cnr_assign_status,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'assignment_comment' ) assignment_comment
       from
       mgi_gene,
       project,
       well_summary_by_di,
       well fp_well
       where mgi_gene.mgi_gene_id = project.mgi_gene_id
       and well_summary_by_di.project_id = project.project_id
       and fp_well.parent_well_id = well_summary_by_di.epd_well_id
       and mgi_gene.marker_symbol = ?
    ];
    
    $c->log->debug("SQL : $sql");
    
    my $sth =  $c->model('HTGTDB')->storage->dbh->prepare($sql);
    $c->log->debug("After preparing SQL");
    if($gene_symbol){
        $sth->execute($gene_symbol);
        $c->log->debug("After executing SQL");
        while(my $result = $sth->fetchrow_hashref()){
            my $date;
            if($result->{SNG_ASSIGN_DATE}){
                $date = $result->{SNG_ASSIGN_DATE};
            }elsif($result->{MRC_ASSIGN_DATE}){
                $date = $result->{MRC_ASSIGN_DATE};
            }elsif($result->{ICS_ASSIGN_DATE}){
                $date = $result->{ICS_ASSIGN_DATE};
            }elsif($result->{CNR_ASSIGN_DATE}){
                $date = $result->{CNR_ASSIGN_DATE};
            }elsif($result->{GSF_ASSIGN_DATE}){
                $date = $result->{GSF_ASSIGN_DATE};
            }
            
            ## add 5' pass level, 3' pass leve;, loxp pass level here
            my $epd_well_id = $result->{EPD_WELL_ID};
            my $well = $c->model('HTGTDB::WELL')->find( { well_id=>$epd_well_id });
            my $five_arm_pass_level = $well->five_arm_pass_level;
            my $three_arm_pass_level = $well->three_arm_pass_level;
            my $loxP_pass_level = $well->loxP_pass_level;
            
            my $epd_well = {
                name      => $result->{EPD_WELL_NAME},
                id        => $result->{EPD_WELL_ID},
                fp_well_name => $result->{FP_WELL_NAME},
                fp_well_id => $result->{FP_WELL_ID},
                gene_id   => $result->{GENE_ID},
                strain => $result->{CELL_LINE},
                comment   => $result->{ASSIGNMENT_COMMENT},
                pass_level => $result->{PASS_LEVEL},
                distribute => $result->{DISTRIBUTE},
                five_prime_arm => $five_arm_pass_level,
                loxp => $loxP_pass_level,
                three_prime_arm => $three_arm_pass_level,
                targeted_trap => $result->{TARGETED_TRAP},
                cell_sng_status => $result->{SNG_ASSIGN_STATUS},
                cell_mrc_status => $result->{MRC_ASSIGN_STATUS},
                cell_ics_status => $result->{ICS_ASSIGN_STATUS},
                cell_cnr_status => $result->{CNR_ASSIGN_STATUS},
                cell_gsf_status => $result->{GSF_ASSIGN_STATUS},
                date => $date
            };
            
            push @{$returned_genes->{$result->{PRIMARY_NAME}}}, $epd_well;
        }
    }

    return $returned_genes;
}

sub get_clones_by_epd {
    my ($c, $epd_well_name) = @_;
    
    my $returned_clones ;
    
    my $sql = qq [
        select distinct
        mgi_gene.mgi_gene_id GENE_ID,
        mgi_gene.marker_symbol PRIMARY_NAME,
        well_summary_by_di.es_cell_line cell_line,
        well_summary_by_di.epd_well_id,
        well_summary_by_di.epd_well_name,
        fp_well.well_name fp_well_name,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type = 'pass_level' ) pass_level,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type = 'distribute' ) distribute,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type = 'targeted_trap' ) targeted_trap,        
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_sng_assign_date' ) sng_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_mrc_assign_date' ) mrc_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_ics_assign_date' ) ics_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_gsf_assign_date' ) gsf_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_cnr_assign_date' ) cnr_assign_date,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_sng_status' ) sng_assign_status,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_mrc_status' ) mrc_assign_status,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_ics_status' ) ics_assign_status,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_gsf_status' ) gsf_assign_status,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'cell_cnr_status' ) cnr_assign_status,
        ( select data_value from well_data where well_data.well_id = well_summary_by_di.epd_well_id and well_data.data_type like 'assignment_comment' ) assignment_comment
        from
        mgi_gene,
        project,
        well_summary_by_di,
        well fp_well
        where
        mgi_gene.mgi_gene_id = project.mgi_gene_id
        and well_summary_by_di.project_id = project.project_id
        and fp_well.parent_well_id = well_summary_by_di.epd_well_id
        and well_summary_by_di.epd_well_name = ?
    ];
    
    $c->log->debug("SQL : $sql");
    
    my $sth =  $c->model('HTGTDB')->storage->dbh->prepare($sql);
    $c->log->debug("After preparing SQL");
    if($epd_well_name){
        $sth->execute($epd_well_name);
        $c->log->debug("After executing SQL");
        my $date;
        while(my $result = $sth->fetchrow_hashref()){
            if($result->{SNG_ASSIGN_DATE}){
                $date = $result->{SNG_ASSIGN_DATE};
            }elsif($result->{MRC_ASSIGN_DATE}){
                $date = $result->{MRC_ASSIGN_DATE};
            }elsif($result->{ICS_ASSIGN_DATE}){
                $date = $result->{ICS_ASSIGN_DATE};
            }elsif($result->{CNR_ASSIGN_DATE}){
                $date = $result->{CNR_ASSIGN_DATE};
            }elsif($result->{GSF_ASSIGN_DATE}){
                $date = $result->{GSF_ASSIGN_DATE};
            }
            
             ## add 5' pass level, 3' pass leve;, loxp pass level here
            my $epd_well_id = $result->{EPD_WELL_ID};
            my $well = $c->model('HTGTDB::WELL')->find( { well_id=>$epd_well_id } );
            my $five_arm_pass_level = $well->five_arm_pass_level;
            my $three_arm_pass_level = $well->three_arm_pass_level;
            my $loxP_pass_level = $well->loxP_pass_level;
            
            my $epd_well = {
                gene_name      => $result->{PRIMARY_NAME},
                name      => $result->{EPD_WELL_NAME},
                id        => $result->{EPD_WELL_ID},
                fp_well_name => $result->{FP_WELL_NAME},
                fp_well_id => $result->{FP_WELL_ID},
                gene_id   => $result->{GENE_ID},
                strain => $result->{CELL_LINE},
                comment   => $result->{ASSIGNMENT_COMMENT},
                pass_level => $result->{PASS_LEVEL},
                distribute => $result->{DISTRIBUTE},
                five_prime_arm => $five_arm_pass_level,
                loxp => $loxP_pass_level,
                three_prime_arm => $three_arm_pass_level,
                targeted_trap => $result->{TARGETED_TRAP},
                cell_sng_status => $result->{SNG_ASSIGN_STATUS},
                cell_mrc_status => $result->{MRC_ASSIGN_STATUS},
                cell_ics_status => $result->{ICS_ASSIGN_STATUS},
                cell_cnr_status => $result->{CNR_ASSIGN_STATUS},
                cell_gsf_status => $result->{GSF_ASSIGN_STATUS},
                date => $date
            };
            push @{$returned_clones}, $epd_well;
        }
    }

    return $returned_clones;
}
1;
