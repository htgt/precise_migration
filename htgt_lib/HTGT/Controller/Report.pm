package HTGT::Controller::Report;

use strict;
use warnings;
use base 'Catalyst::Controller';
use DateTime;
use List::MoreUtils qw(uniq);
use HTGT::Controller::QC;
use HTGT::Controller::Report::PgCloneRecovery;
use HTGT::Controller::Report::Gene_report_methods;
use HTGT::Controller::Gene;
use HTGT::Controller::Report::AssignedGenesAndClones qw(get_unassigned_genes get_genes_or_cells_in_conflict get_assigned_genes_and_clones get_clones_by_gene get_clones_by_epd);
use HTGT::Utils::Cache;
use HTGT::Utils::DBI;
#use HTGT::Utils::Report::EPDSummary;
use HTGT::Utils::Report::KompSummary;
use HTGT::Utils::Report::Recovery;
use HTGT::Utils::Report::AlternateCloneRecoveryCounts;
use HTGT::Utils::Report::AlternateCloneRecoveryStatus;
use HTGT::Utils::Report::AlleleOverallPass;
use HTGT::Utils::Report::SequencingArchiveLabels;
use HTGT::Utils::Report::PIQData;
use HTGT::Utils::Recovery::GeneHistory 'get_gene_recovery_history';
use HTGT::Utils::GeneIDs 'get_gene_ids';
use JSON;
use Path::Class;
use XML::Writer;
use Try::Tiny;
use Data::Dumper;

=head1 NAME

HTGT::Controller::Report - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for Reports.

=head1 METHODS

=head2 index

Redirects to '/report/summary_by_gene'.

=cut

sub index : Private {
    my ( $self, $c ) = @_;
}

=head2 pg_pass_analysis

A private method for counting the number of PGs per plate that pass - based on manual vs automatic.

=cut

sub manual_auto_pg_analysis : Local {
    my ( $self, $c ) = @_;
    
    my $dbh = $c->model('HTGTDB')->storage->dbh;
    
    my $sql = "
            select distinct
            ws.pgdgr_plate_name,
            ws.pgdgr_well_name,
            ws.pg_pass_level,
            ws.design_instance_id,
            d.design_id,
            exon.primary_name

            from
            well_summary ws,
            design d,
            design_instance di,
            mig.gnm_exon exon

            where ws.pgdgr_plate_name is not null
            and ws.pg_pass_level is not null
            
            and di.design_instance_id = ws.design_instance_id
            and d.design_id = di.design_id
            and d.start_exon_id = exon.id
            
            order by pgdgr_plate_name, pgdgr_well_name
            ";

    my $sth = $dbh->prepare( $sql );
    $sth->execute();

    my $Data = $sth->fetchall_arrayref();

    my %PLATE    = ();
    my %CONFLICT = ();

    for my $row ( @$Data ) {

        my $plate     = $row->[0];
        my $well      = $row->[1];
        my $pass      = $row->[2];
        my $exon_type = $row->[5];

        if ( ! exists $PLATE{$plate}{$well} ) {
            $PLATE{$plate}{$well} = "$exon_type $pass";
        } else {
            $CONFLICT{$plate}{$well} = $PLATE{$plate}{$well} . " $exon_type $pass";
            delete $PLATE{$plate}{$well};
        }
    }

    # Conflicts - they exist in well_summary
    #for my $plate ( keys %CONFLICT ) { for my $well ( keys %{ $CONFLICT{$plate} } ) { } }

    my %PCT = ();
    for my $plate ( keys %PLATE ) {
        $PCT{$plate}{ENSPOS} = 0;
        $PCT{$plate}{ENSSUM} = 0;
        $PCT{$plate}{OTTPOS} = 0;
        $PCT{$plate}{OTTSUM} = 0;
        
        for my $well ( keys %{ $PLATE{$plate} } ) {
            my ( $exon_id, $pass ) = split /\s+/, $PLATE{$plate}{$well};
            if ( $exon_id =~ /ENSMUS/i ) {
                $PCT{$plate}{ENSSUM}++;
                if ( $pass =~ /pass/i ) {
                    $PCT{$plate}{ENSPOS}++;                
                }
            }
            if ( $exon_id =~ /OTTMUS/i ) {
                $PCT{$plate}{OTTSUM}++;
                if ( $pass =~ /pass/i ) {
                    $PCT{$plate}{OTTPOS}++;                
                }
            }
        }
        
    }
    
    # Counts for the total number of passes
    my $ens_sum_sum  = 0;
    my $ens_pass_sum = 0;
    my $ott_sum_sum  = 0;
    my $ott_pass_sum = 0;
    
    my %COUNTS = ();
    for my $plate ( keys %PCT ) {
        my $pct_ens = 0;
        my $pct_ott = 0;
        if ( $PCT{$plate}{ENSSUM} > 0 ) { 
             # % per plate            
             $pct_ens = ( $PCT{$plate}{ENSPOS}/ $PCT{$plate}{ENSSUM} ) * 100;
             # Increment the sums
             $ens_sum_sum  += $PCT{$plate}{ENSSUM};
             $ens_pass_sum += $PCT{$plate}{ENSPOS};
        }
        if ( $PCT{$plate}{OTTSUM} > 0 ) { 
             # % per plate
             $pct_ott = ( $PCT{$plate}{OTTPOS}/ $PCT{$plate}{OTTSUM} ) * 100;
             # Increment the sums             
             $ott_sum_sum  += $PCT{$plate}{OTTSUM};
             $ott_pass_sum += $PCT{$plate}{OTTPOS};     
        }
        # Format the output
        $pct_ens = sprintf("%3d", $pct_ens);
        $pct_ott = sprintf("%3d", $pct_ott);
        @{ $COUNTS{$plate} } = ($pct_ens, $PCT{$plate}{ENSSUM}, $pct_ott, $PCT{$plate}{OTTSUM} );
    }
    
    $c->stash->{ens_pct_success} = ($ens_pass_sum/$ens_sum_sum)*100;
    $c->stash->{ott_pct_success} = ($ott_pass_sum/$ott_sum_sum)*100;;
    $c->stash->{counts_hash} = \%COUNTS;
    
}

=head2 gene_search

Custom search routine to look up genes via the MGI_GENE and MGI_SANGER tables, 
then link them to the projects table.

=cut

sub gene_search : Local {
    my ( $self, $c ) = @_;
    
    unless ( $c->check_user_roles( q(edit) ) ) {
        $c->response->redirect( $c->uri_for( '/access_denied' ) );
        return 0;
    }

    # Strip whitespace from the end/beginning of the search term
    my $search_term = $c->req->params->{query};
    $search_term =~ s/\s+$//;
    $search_term =~ s/^\s+//;

    ### gene_search: $search_term
    my $mgi_gene_rs = $c->model('HTGTDB::MGIGene')->search(
        {
            -or => [
                marker_symbol    => { 'like', $search_term . '%' },
                mgi_accession_id => $search_term,
                ensembl_gene_id  => $search_term,
                vega_gene_id     => $search_term
            ]
        },
        { order_by => { -asc => 'me.marker_symbol' } }
    );

    # See if this gives us any results, if not expand it to the longer 'marker_name'
    if ( $mgi_gene_rs->count == 0 ) {
        ### search on marker_symbol returned no results, trying marker_name
        $mgi_gene_rs = $c->model('HTGTDB::MGIGene')->search(
            { 'me.marker_name' => { 'like', '%' . $search_term . '%' } },
            { order_by => { -asc => 'me.marker_symbol' } }
        );

    }

    # If that doesn't give any results, move the search out to the mgi_sanger table...
    if ( $mgi_gene_rs->count == 0 ) {
        ### search on marker_name returned no results, trying sanger_gene_id
        $mgi_gene_rs = $c->model('HTGTDB::MGIGene')->search(
            { 'mgi_sanger_genes.sanger_gene_id' => $search_term },
            { order_by => { -asc => 'me.marker_symbol' }, join => [ 'mgi_sanger_genes' ] }
        );
    }
    
    # How about a project id?
    if ( $mgi_gene_rs->count == 0 ) {
        ### search on sanger_gene_id returned no results
        # As this is a numeric field - the search blows up if we try to search for text...
        # So if there are any non-numeric characters, skip this search.
        if ( $search_term =~ /\D/ ) {
            ### search term not numeric, skipping project_id search
            # These are not the droids you are looking for, move along...
        } else {
            ### searching on project_id
            $mgi_gene_rs = $c->model('HTGTDB::MGIGene')->search(
                { 'projects.project_id' => $search_term },
                {
                    order_by => [ { -asc => 'me.marker_symbol'} , { -desc => 'status.order_by' } ],
                    join     => [ { 'projects' => 'status' } ]
                }
            );
        }
    }
    
    # Finally, if that doesn't give any results, move the search out to the well_summary_by_di table...
    my $clone_search = 'no';
    my @project_ids;
    if ( $mgi_gene_rs->count == 0 ) {
        ### project_id search returned no results, trying well_summary_by_di
        my $modified_search_term = $search_term;
        my $search_filter;
        if ( $search_term =~ /EPD/ ) {
            $modified_search_term =~ /([HD]?EPD)(0*)([1-9]+)(.*)/i;
            $modified_search_term = $1 . '%0' . $3 . $4;
            $search_filter = 'where epd_well_name like ?';
        } elsif ( $search_term =~ /PGS|PGR/ ) {
            $modified_search_term =~ /(\D+)(0*)([1-9]+)(.*)/i;
            $modified_search_term = $1 . '0%' . $3 . $4;
            $search_filter = 'where pgdgr_plate_name like ?';
        }
        ### $search_filter
        ### $modified_search_term
        
        if ( $search_filter ne "" ) {
            
            my $dbh = $c->model('HTGTDB')->storage->dbh;
            my $query = 'select distinct project_id from well_summary_by_di ' . $search_filter;

            my $sth = $dbh->prepare($query);
            $sth->execute( $modified_search_term );

            while ( my $result = $sth->fetchrow_arrayref() ) { push( @project_ids, $result->[0] ); }

            ### search well_summary_by_di found projects: @project_ids

            if ( scalar(@project_ids) > 0 ) {
                ### searching mgi_gene on project_id
                $mgi_gene_rs = $c->model('HTGTDB::MGIGene')->search(
                    { 'projects.project_id' => \@project_ids },
                    {
                        order_by => [ { -asc => 'me.marker_symbol'} , { -desc => 'status.order_by' } ],
                        join     => [ { 'projects' => 'status' } ]
                            
                    }
                );
                $clone_search = 'yes';
                
            }
            
        }

    }

    # This is an 'if all else fails' for getting the TRAP data.
    if ( $mgi_gene_rs->count == 0 ) {
        ### in the all else fails branch
        # Search on trap well name and MUST return and object for the mgi_gene.

        ### trying search on gene_trap_well_name
        $mgi_gene_rs = $c->model('HTGTDB::MGIGene')->search(
            { -and => [ 
                'gene_trap_well.gene_trap_well_name' => { 'like', $search_term . '%' },
                ]
                ,'gene_trap_well.gene_trap_well_name' => { 'not like', 'EUCX%' },
            },
            
            {
                order_by => [ { -asc => 'me.marker_symbol'} , { -desc => 'status.order_by' } ],
                join => [ { 'projects' => ['status', { 'gene_trap_links' => 'gene_trap_well' } ] } ],
            }
        );
    }

    if ( !$c->req->params->{called_elswhere} ) {

        # If we only have a single search result and we're not being used as part of
        # an ajax call - redirect straight to the gene_report page...

        if ( $mgi_gene_rs->count == 1 ) {
            ### found 1 result, redirecting to gene_report
            return $c->response->redirect( $c->uri_for( '/report/gene_report', { mgi_accession_id => $mgi_gene_rs->first->mgi_accession_id } ) );
        }

    }
    else {
        $c->stash->{called_elswhere} = $c->req->params->{called_elswhere};
    }

    if ( $c->req->params->{centre} ) { $c->stash->{centre} = 1; }

    my $search_results = {};

    if ( defined $mgi_gene_rs and $mgi_gene_rs->count != 0 ) {
        ### weird paging
        $mgi_gene_rs = $mgi_gene_rs->search(
            {},
            {
                rows => 25,
                page => $c->req->params->{page} ? $c->req->params->{page} : 1
            }
        );

        ### searching projects
        my $project_rs = $c->model('HTGTDB::Project')->search(
          {},
          {
            order_by  => { -desc => 'status.order_by' },
            join      => ['status', 'ws_by_di_entries' ],
            prefetch  => ['status', 'ws_by_di_entries', 'mgi_gene' ]
          }
        );
        
        if ( $clone_search eq 'yes' && scalar(@project_ids) > 0 ) {
            ### searching on project_ids
            $project_rs = $project_rs->search( { 'me.project_id' => \@project_ids } );
        } else {
            ### searching on mgi_gene_id
            $project_rs = $project_rs->search( { 'me.mgi_gene_id' => [ $mgi_gene_rs->get_column('me.mgi_gene_id')->all() ] } );
        }
        
        
        my $data_page_obj = $mgi_gene_rs->pager();
        use Data::Pageset;
        $c->stash->{page_info} = Data::Pageset->new(
            {
                'total_entries'    => $data_page_obj->total_entries,
                'entries_per_page' => $data_page_obj->entries_per_page,
                'current_page'     => $data_page_obj->current_page,
                'pages_per_set'    => 5,
                'mode'             => 'slide'
            }
        );

        ### about to start iterating over mgi_gene_rs
        while ( my $mgi_gene = $mgi_gene_rs->next ) {
            ### got result: $mgi_gene->marker_symbol
            $search_results->{ $mgi_gene->marker_symbol }->{gene} = $mgi_gene;
        }

        ### about to start iterating over project_rs
        while ( my $project = $project_rs->next ) {
          unless ( $search_results->{ $project->mgi_gene->marker_symbol }->{projects} ) {
            $search_results->{ $project->mgi_gene->marker_symbol }->{projects} = [];
          }
          
          push( @{ $search_results->{ $project->mgi_gene->marker_symbol }->{projects} }, $project );
        }
        
    }
    
    $c->stash->{search_results} = $search_results;
    $c->stash->{search_term} = $search_term;
    $c->stash->{template}  = 'report/gene_search.tt';
}

=head2 gene_report

Report page displaying the status of a gene going through the pipeline and any 
distributable products indicated via the Project table.  This method is really a wrapper 
around 'project_gene_report'.

=head2 project_gene_report

The real 'gene' report page function.  This retrieves the information for a 
given project/product in our pipeline and displays it appropriately.

=cut

sub gene_report : Local {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles( q(edit) ) ) {
        $c->response->redirect( $c->uri_for( '/access_denied' ) );
        return 0;
    }

    ##
    ## Try and cope with all the different ways of coming to the page...
    ##

    # Project ID    
    if ( $c->req->params->{project_id} ) { 
        
        # IF TRAP 
        my $project = $c->model('HTGTDB::Project')->find( { project_id => $c->req->params->{project_id} } );
        if ( $project->is_trap == 1 && $project->is_publicly_reported == 1 ) {
            project_trap_report($self, $c);
        }
        # ELSE DO THIS - carry on as normal
        else {
            $self->project_gene_report($c); 
        }
    }
    
    # EPD Well Name or ID
    elsif ( $c->req->params->{epd_well_name} or $c->req->params->{epd_well_id} ) {

        my $well_summ_by_di_rs;
        if ( $c->req->params->{epd_well_name} )  { 
            $well_summ_by_di_rs = $c->model('HTGTDB::WellSummaryByDI')->search( { epd_well_name => $c->req->params->{epd_well_name} } ); 
        }
        elsif ( $c->req->params->{epd_well_id} ) { 
            $well_summ_by_di_rs = $c->model('HTGTDB::WellSummaryByDI')->search( { epd_well_id => $c->req->params->{epd_well_id} } ); 
        }

        my $project_rs = $well_summ_by_di_rs->related_resultset('project')->search( {},{ distinct => 1 } );

        # Do we have multiple projects?
        if ( $project_rs->count > 1 ) {

            my @projects;
            while ( my $project = $project_rs->next ) { push( @projects, $project ); }
            $c->stash->{projects}    = \@projects;
            $c->stash->{mgi_gene}    = $projects[0]->mgi_gene;
            
            # get all the gene ids from both mgi_gene & mgi website
            $c->stash->{mgi_sanger_genes} = $self->get_gene_identifiers($c,$projects[0]->mgi_gene->mgi_gene_id);
        
        }
        elsif ( $project_rs->count == 1 ) {
            $c->req->params->{project_id} = $project_rs->first->project_id;
            $self->project_gene_report($c);
        }
        else {
            my $mgi_gene = $c->model('HTGTDB::MGIGene')->find( { mgi_accession_id => $c->req->params->{mgi_accession_id} }, { key => 'mgi_accession_id' } );
            $c->stash->{mgi_gene} = $mgi_gene;
        }
    }

    # MGI Gene Accession No.
    elsif ( $c->req->params->{mgi_accession_id} ) {

        my $project_rs = $c->model('HTGTDB::Project')->search(
            { 'mgi_gene.mgi_accession_id' => $c->req->params->{mgi_accession_id} },
            {
                join     => [ 'mgi_gene', 'status' ],
                prefetch => 'mgi_gene',
                order_by => { -desc => 'status.order_by' }
            }
        );

        # Do we have multiple projects?
        if ( $project_rs->count > 1 ) {

            my @projects;
            while ( my $project = $project_rs->next ) { push( @projects, $project ); }
            $c->stash->{projects}    = \@projects;
            $c->stash->{mgi_gene}    = $projects[0]->mgi_gene;
   
             # add mgi_sanger_genes
            # get all the gene ids from both mgi_gene & mgi website
            $c->stash->{mgi_sanger_genes} = $self->get_gene_identifiers($c,$projects[0]->mgi_gene->mgi_gene_id);
        
        }
        elsif ( $project_rs->count == 1 ) {

            $c->req->params->{project_id} = $project_rs->first->project_id;
            $self->project_gene_report($c);

        }
        else {

            my $mgi_gene = $c->model('HTGTDB::MGIGene')->find( { mgi_accession_id => $c->req->params->{mgi_accession_id} }, { key => 'mgi_accession_id' } );
            $c->stash->{mgi_gene} = $mgi_gene;

        }

    }

    # MIG (GnmGene) ID
    elsif ( $c->req->params->{gene_id} ) {

        my $project_rs = $c->model('HTGTDB::Project')->search(
            { mig_gene_ids => $c->req->params->{gene_id} },
            {
                join     => 'status',
                prefetch => 'mgi_gene',
                order_by => { -desc => 'status.order_by' }
            }
        );

        $c->stash->{gnm_gene_id} = $c->req->params->{gene_id};
      
        
        # Do we have multiple projects?
        if ( $project_rs->count > 1 ) {

            my @projects;
            while ( my $project = $project_rs->next ) { push( @projects, $project ); }
            $c->stash->{projects} = \@projects;
            $c->stash->{mgi_gene} = $projects[0]->mgi_gene;
             # add mgi_sanger_genes
            # get all the gene ids from both mgi_gene & mgi website
            $c->stash->{mgi_sanger_genes} = $self->get_gene_identifiers($c,$projects[0]->mgi_gene->mgi_gene_id);

        }
        elsif ( $project_rs->count == 1 ) {

            $c->req->params->{project_id} = $project_rs->first->project_id;
            $self->project_gene_report($c);

        }
        else {

            $c->flash->{error_msg} = 'Sorry, we have no data to display for this gene.';
            $c->response->redirect( $c->uri_for('/welcome') );
            return 1;

        }

    }

    # MIG (GnmGene) Name...
    elsif ( $c->req->params->{gene_name} ) {

        $c->response->redirect( $c->uri_for( '/report/gene_search', { query => $c->req->params->{gene_name} } ) );
        return 1;

    }

    # Bug out if there are no parameters...
    else {

        $c->flash->{error_msg} = 'Sorry, your gene search parameters were empty.';
        $c->response->redirect( $c->uri_for('/welcome') );
        return 1;

    }

}

sub project_gene_report : Local {
    my ( $self, $c ) = @_;
    
    unless ( $c->check_user_roles( q(edit) ) ) {
        $c->response->redirect( $c->uri_for( '/access_denied' ) );
        return 0;
    }

    ##
    ## Get the project
    ##

    my $project = $c->model('HTGTDB::Project')->find( { project_id => $c->req->params->{project_id} }, { prefetch => [ 'mgi_gene', 'status' ] } );
    # add mgi_sanger_genes
    # get all the gene ids from both mgi_gene & mgi website
    $c->stash->{mgi_sanger_genes} = $self->get_gene_identifiers($c,$project->mgi_gene->mgi_gene_id);

    $c->stash->{project}     = $project;
    $c->stash->{mgi_gene}    = $project->mgi_gene;

    # Toggle 'reset gene status to redesign' button
    $c->stash->{show_redesign_toggle} = $self->show_redesign_toggle( $c, $project );
    
    ##
    ## Stash the recovery history
    ##

    $c->stash->{recovery_history} = get_gene_recovery_history( $c->model( 'HTGTDB' )->schema, $project->mgi_gene->mgi_gene_id );
    
    ##
    ## Stash the project status info
    ##

    HTGT::Controller::Report::Project::get_project_status_info( $self, $c );

    ##
    ## Get the gene comments etc if the user has the 'design' privilege
    ##

    if ($c->check_user_roles("design")) {   
        HTGT::Controller::Gene::get_gene_comments( $self, $c );
        HTGT::Controller::Gene::get_gene_designs( $self, $c );
    } 

    ##
    ## Get the constructs (or designs) defined by the project
    ##

    ## MODIFY HERE TO TRUDGE OFF AND GET THE 

    if (   ( $project->targeting_vector_id and $project->targvec_distribute eq 'yes' )
        or ( $project->targeting_vector_id and ( (defined $project->epd_distribute and $project->epd_distribute > 0 ))
        or ( $project->targeting_vector_id and ( defined $project->targeted_trap and $project->targeted_trap > 0) )) )
    {
        HTGT::Controller::Report::Project::get_display_features( $self, $c );
        HTGT::Controller::Report::Project::get_vector_seq_features( $self, $c );
        HTGT::Controller::Report::Project::get_es_cell_info( $self, $c );
    }
    elsif ( $project->design_id ) {
        HTGT::Controller::Report::Project::get_display_features( $self, $c );
        HTGT::Controller::Report::Project::get_design_info( $self, $c );
    }
    
    # Stash a timestamp - this is needed for some of the tablekit tables etc...
    $c->stash->{timestamp} = DateTime->now;

}


## TODO: add to the perlpod @ top of methods

sub project_trap_report : Local {
    my ( $self, $c ) = @_;
            
    my $project = $c->model('HTGTDB::Project')->find( 
        { project_id => $c->req->params->{project_id} },
        { prefetch => [ 'mgi_gene', 'status', { 'gene_trap_links' => 'gene_trap_well' } ] }
    );

    $c->stash->{project} = $project;
}

# THIS NEEDS TO CHANGE SO THAT TRAPS W/O PROJECTS ARE REPORTED PROPERLY
sub gene_trap_well_page : Local {
    my ( $self, $c ) = @_;
    my $trap_well_identity = $c->req->params->{gene_trap_well};
    
    # If a name is passed, save some pain and just get the id
    my $trap_well_id;
    if ( $trap_well_identity =~ /EUC/ ){
    	my $trap_well = $c->model('HTGTDB::GeneTrapWell')->find( 
    	    { gene_trap_well_name => $trap_well_identity }, 
    	);
    	if ( ! defined $trap_well ) {
    	$c->stash->{fail} = 1;
    	$c->stash->{user_text} = $trap_well_identity;
    	next;
	    } else {   
    	    $trap_well_id = $trap_well->gene_trap_well_id;
	    }
    } else {
        $trap_well_id = $trap_well_identity;
    }
    
    # Get the wells associated with the id we pass.
    my @gene_trap_wells = $c->model('HTGTDB::GeneTrapWell')->search( 
	    { 'me.gene_trap_well_id' => $trap_well_id }, 
	    # This will prevent anything that doesn't have a project or gene from being returned.
	    #{   prefetch => [ { 'project_links' => { 'projects' => 'mgi_gene' } } ], }
	);
	
	
	if ( scalar @gene_trap_wells < 1 ) {
	    $c->stash->{fail}      = 1;
	    $c->stash->{user_text} = $trap_well_identity;
    } else {
        
        # Establish if all the genes in the list are the same or not.
        # I do the same in the template however not at the start - I also don't
        # want to pass much stuff.
        if ( $gene_trap_wells[0]->is_paired ) {
            $c->stash->{warn} = 0;
        } else {
            my @genes = ();
            my %SPL = ( '5' => 1, '3'=> 1);
            for my $w ( @gene_trap_wells ) {
                for my $links ( $w->project_links ) { # CAUSING PROBLEMS
                    delete $SPL{$links->splink_orientation};
                    for my $project ( $links->project ) {
                        if ( defined $project->mgi_gene ) { 
                            push @genes, $project->mgi_gene->ensembl_gene_id 
                        }
                    }
                }
            }
            my %SEEN = ();
            @genes = grep { ! $SEEN{$_}++ } @genes;   
            $c->stash->{warn} = 1 if scalar @genes > 1;
            my @spl = keys %SPL;
	        $c->stash->{splinks} = \@spl;
        }
	    $c->stash->{traps}   = \@gene_trap_wells;
    }
}

=head2 project_reports

Report page for displaying project information on gene targeted constructs

=head2 _project_report_table

Helper function for 'project_reports' that actually does the searching...

=cut

sub project_reports : Local {
    my ( $self, $c ) = @_;
    
    unless ( $c->check_user_roles( q(edit) ) ) {
        $c->response->redirect( $c->uri_for( '/access_denied' ) );
        return 0;
    }

    my @project_statuses = $c->model('HTGTDB::ProjectStatus')->search( { project_status_id => { '!=', '1' } }, { order_by => { -asc => 'order_by' } } );
    $c->stash->{project_statuses} = \@project_statuses;

}

sub _project_report_table : Local {
    my ( $self, $c ) = @_;
    
    # Pre-define the query
    my $project_rs = $c->model('HTGTDB::Project')->search(
        { is_trap => undef },
        {
            join     => ['mgi_gene', 'status'],
            prefetch => ['mgi_gene', 'status'],
            order_by => [ { -asc  => 'mgi_gene.marker_symbol' },
                          { -desc => 'status.order_by' } ]
        }
    );
    
    ##
    ## Deal with the users parameters
    ##
    
    my $params = {};
    if ( $c->req->params->{query} ) {
      $params = jsonToObj( $c->req->params->{query} );
    } else {
      $params = $c->req->params;
    }
    
    # Project sponsor
    if ( defined $params->{is_eucomm} and $params->{is_eucomm} eq 'on' )                 { $project_rs = $project_rs->search( { 'is_eucomm'         => 1 } ); }
    if ( defined $params->{is_komp_csd} and $params->{is_komp_csd} eq 'on' )             { $project_rs = $project_rs->search( { 'is_komp_csd'       => 1 } ); }
    if ( defined $params->{is_norcomm} and $params->{is_norcomm} eq 'on' )               { $project_rs = $project_rs->search( { 'is_norcomm'        => 1 } ); }
    if ( defined $params->{is_eutracc} and $params->{is_eutracc} eq 'on' )               { $project_rs = $project_rs->search( { 'is_eutracc'        => 1 } ); }
    if ( defined $params->{is_mgp} and $params->{is_mgp} eq 'on' )                       { $project_rs = $project_rs->search( { 'is_mgp'            => 1 } ); }
    if ( defined $params->{is_komp_regeneron} and $params->{is_komp_regeneron} eq 'on' ) { $project_rs = $project_rs->search( { 'is_komp_regeneron' => 1 } ); }
    if ( defined $params->{is_eucomm_tools} and $params->{is_eucomm_tools} eq 'on' )     { $project_rs = $project_rs->search( { 'is_eucomm_tools'   => 1 } ); }
    if ( defined $params->{is_eucomm_tools_cre} and $params->{is_eucomm_tools_cre} eq 'on' )     { $project_rs = $project_rs->search( { 'is_eucomm_tools_cre'   => 1 } ); }
    if ( defined $params->{is_switch} and $params->{is_switch} eq 'on' )                 { $project_rs = $project_rs->search( { 'is_switch'         => 1 } ); }
    if ( defined $params->{is_tpp} and $params->{is_tpp} eq 'on' )                 { $project_rs = $project_rs->search( { 'is_tpp'         => 1 } ); }
    if ( defined $params->{is_mgp_bespoke} and $params->{is_mgp_bespoke} eq 'on' )                 { $project_rs = $project_rs->search( { 'is_mgp_bespoke'         => 1 } ); }
    
    # Project status
    if ( defined $params->{project_status_id} && $params->{project_status_id} ne "" && $params->{project_status_id} ne "-" ) {
        if ( $params->{better_project_status_id} eq 'on' ) {
            my $project_status = $c->model('HTGTDB::ProjectStatus')->find({ project_status_id => $params->{project_status_id} });
            $project_rs = $project_rs->search( { 'status.order_by' => { '>=', $project_status->order_by } } );
        } else {
            $project_rs = $project_rs->search( { 'me.project_status_id' => $params->{project_status_id} } );
        }
    }
    
    # Latest for gene?
    if ( defined $params->{is_latest_for_gene} and $params->{is_latest_for_gene} eq 'yes' ) { $project_rs = $project_rs->search( { 'is_latest_for_gene' => 1 } ); }
    
    # Gene filtering
    if ( defined $params->{marker_symbol} and $params->{marker_symbol} ne "" )       { $project_rs = $project_rs->search( { 'mgi_gene.marker_symbol'    => $params->{marker_symbol} } ); }
    if ( defined $params->{mgi_accession_id} and $params->{mgi_accession_id} ne "" ) { $project_rs = $project_rs->search( { 'mgi_gene.mgi_accession_id' => $params->{mgi_accession_id} } ); }

    if ( defined $params->{ensembl_gene_id} and $params->{ensembl_gene_id} ne "" ) {
        $project_rs = $project_rs->search(
            {
                -or => [
                    'mgi_gene.ensembl_gene_id'        => $params->{ensembl_gene_id},
                    'mgi_sanger_genes.sanger_gene_id' => $params->{ensembl_gene_id},
                ]
            },
            {
                join     => [ 'status', { 'mgi_gene' => 'mgi_sanger_genes' } ],
                distinct => 'project_id'
            }
        );
    }

    if ( defined $params->{vega_gene_id} and $params->{vega_gene_id} ne "" ) {
        $project_rs = $project_rs->search(
            {
                -or => [
                    'mgi_gene.vega_gene_id'        => $params->{vega_gene_id},
                    'mgi_sanger_genes.sanger_gene_id' => $params->{vega_gene_id},
                ]
            },
            {
                join     => [ 'status', { 'mgi_gene' => 'mgi_sanger_genes' } ],
                distinct => 'project_id'
            }
        );
    }
    
    ##
    ## See if we need to page our results...
    ##
    
    if ( $c->req->params->{view} and $c->req->params->{view} eq 'csvdl' ) {
        $project_rs = $project_rs->search(
            {},
            {
                columns => [
                    'me.is_eucomm',
                    'me.is_komp_csd',
                    'me.is_norcomm',
                    'me.is_eutracc',
                    'me.is_mgp',
                    'me.is_komp_regeneron',
                    'me.is_eucomm_tools',
                    'me.is_eucomm_tools_cre',
                    'me.is_switch',
                    'me.is_tpp',
                    'me.is_mgp_bespoke',
                    'mgi_gene.marker_symbol',
                    'status.name',
                    'me.design_id',
                    'me.cassette',
                    'me.backbone'
                ]
            }
        );
    } else {
        $project_rs = $project_rs->search( {}, { rows => 75, page => $c->req->params->{page} } );
        my $data_page_obj = $project_rs->pager();

        use Data::Pageset;
        $c->stash->{page_info} = Data::Pageset->new(
            {
                'total_entries'    => $data_page_obj->total_entries(),
                'entries_per_page' => $data_page_obj->entries_per_page(),
                'current_page'     => $data_page_obj->current_page(),
                'pages_per_set'    => 5,
                'mode'             => 'slide'
            }
        );
        $c->stash->{project_count} = $data_page_obj->total_entries();
    }
    
    # Stash the results
    $c->stash->{projects} = [ $project_rs->all() ];
}

=head2 eucomm_main

The main '/welcome' page for the Eucomm version of HTGT. 

=cut

sub eucomm_main : Local {
    my ( $self, $c ) = @_;
    $self->summary_by_gene($c);
    
    ##
    ## Get a gene count for mice...
    ##
    
    my $dbh = $c->model('KermitsDB')->storage->dbh;

    my $query = q[
    (
            select distinct emi_clone.gene_symbol
            from emi_clone
            join emi_event on emi_event.clone_id = emi_clone.id
            join emi_attempt on emi_attempt.event_id = emi_event.id

            where emi_clone.pipeline_id = 1
            and emi_event.centre_id != 1
            and ( emi_attempt.chimeras_with_glt_from_genotyp > 0
                  or  emi_attempt.number_het_offspring > 0
            )
            and emi_attempt.is_active = 1
            and emma = 1
         )   

      union (
            select distinct emi_clone.gene_symbol
            from emi_clone
            join emi_event on emi_event.clone_id     = emi_clone.id
            join emi_attempt on emi_attempt.event_id = emi_event.id

            where emi_clone.pipeline_id = 1
            and emi_event.centre_id   = 1        
            and emi_attempt.number_het_offspring >= 2
            and emi_attempt.is_active = 1
            and emma = 1
     )

    ];
    
    my $sth = $dbh->prepare($query);
    $sth->execute();
    
    $c->stash->{mice_count} = scalar @{$sth->fetchall_arrayref()};
    $c->stash->{template} = 'report/eucomm_main.tt';
}

=head2 pipeline_status_explanations

Method linking to the static status explanations page.

=cut

sub pipeline_status_explanations : Local {
    my ( $self, $c ) = @_;
    my @statuses = $c->model('HTGTDB::ProjectStatus')->search({},{ order_by => { -desc => 'me.order_by' } });
    $c->stash->{statuses} = \@statuses;
    $c->stash->{template} = 'report/pipeline_status_explanations.tt';
}


=head2 summary_by_gene

Summary report that shows the total number of genes for each project 
at each given status.

=cut

sub summary_by_gene : Local {
    my ( $self, $c ) = @_;

    # Using DBI as it makes group_by queries easier...
    my $dbh = $c->model('HTGTDB')->storage->dbh;

    my $query = q[
        select 
          ps.project_status_id project_status_id,
          ps.name status,
          count( distinct p_eucomm.mgi_gene_id ) eucomm,
          count( distinct p_komp.mgi_gene_id ) komp,
          count( distinct p_mgp.mgi_gene_id ) mgp,
          count( distinct p_norcomm.mgi_gene_id ) norcomm,
          count( distinct p_regeneron.mgi_gene_id ) regeneron,
          count( distinct p_eutracc.mgi_gene_id ) eutracc,
          count( distinct p_eucomm_tools.mgi_gene_id ) eucomm_tools,
          count( distinct p_eucomm_tools_cre.mgi_gene_id ) eucomm_tools_cre,
          count( distinct p_tpp.mgi_gene_id ) tpp,
          count( distinct p_mgp_bespoke.mgi_gene_id ) mgp_bespoke,
          count( distinct p_switch.mgi_gene_id ) is_switch
        from 
          project p
          left join project_status ps on ( p.project_status_id = ps.project_status_id )
          left join project p_eucomm on ( p.project_id = p_eucomm.project_id and p.is_eucomm = 1 )
          left join project p_komp on ( p.project_id = p_komp.project_id and p.is_komp_csd = 1 )
          left join project p_mgp on ( p.project_id = p_mgp.project_id and p.is_mgp = 1 )
          left join project p_norcomm on ( p.project_id = p_norcomm.project_id and p.is_norcomm = 1 )
          left join project p_regeneron on ( p.project_id = p_regeneron.project_id and p.is_komp_regeneron = 1 )
          left join project p_eutracc on ( p.project_id = p_eutracc.project_id and p.is_eutracc = 1 )
          left join project p_eucomm_tools on (p.project_id = p_eucomm_tools.project_id and p.is_eucomm_tools = 1)
          left join project p_eucomm_tools_cre on (p.project_id = p_eucomm_tools_cre.project_id and p.is_eucomm_tools_cre = 1)
          left join project p_tpp on (p.project_id = p_tpp.project_id and p.is_tpp = 1)
          left join project p_mgp_bespoke on (p.project_id = p_mgp_bespoke.project_id and p.is_mgp_bespoke = 1)
          left join project p_switch on (p.project_id = p_switch.project_id and p.is_switch = 1)
        where
              ps.project_status_id != 1
          and p.is_latest_for_gene = 1
        group by ps.name, ps.project_status_id, ps.order_by
        order by ps.order_by desc
    ];

    my $sth = $dbh->prepare($query);
    $sth->execute();
    my $project_counts = $sth->fetchall_hashref('PROJECT_STATUS_ID');
    $c->stash->{project_counts} = $project_counts;

    # Get a list of ALL of the available statuses...
    my @status_list = $c->model('HTGTDB::ProjectStatus')->search(
        {
          order_by => { '<', '125' },
          -and => [ order_by => { '!=', '5' } ]
        },
        { order_by => { -desc => 'order_by' } }
    );
    $c->stash->{status_list} = \@status_list;
    
    my $total_mouse_counts = {};
    my $total_es_cell_counts = {};
    my $total_vector_counts = {};
    my $total_design_counts = {};
    
    foreach my $status_obj (@status_list){
        if(($status_obj->order_by >= 50) || ($status_obj->code eq 'RR')){
            $total_design_counts->{EUCOMM}       += $project_counts->{$status_obj->project_status_id}->{EUCOMM}  || 0;
            $total_design_counts->{KOMP}         += $project_counts->{$status_obj->project_status_id}->{KOMP}    || 0;
            $total_design_counts->{NORCOMM}      += $project_counts->{$status_obj->project_status_id}->{NORCOMM} || 0;
            $total_design_counts->{EUTRACC}      += $project_counts->{$status_obj->project_status_id}->{EUTRACC} || 0;
            $total_design_counts->{EUCOMM_TOOLS} += $project_counts->{$status_obj->project_status_id}->{EUCOMM_TOOLS} || 0;
            $total_design_counts->{EUCOMM_TOOLS_CRE} += $project_counts->{$status_obj->project_status_id}->{EUCOMM_TOOLS_CRE} || 0;
            $total_design_counts->{IS_SWITCH}       += $project_counts->{$status_obj->project_status_id}->{IS_SWITCH} || 0;            
            $total_design_counts->{TPP}       += $project_counts->{$status_obj->project_status_id}->{TPP} || 0;            
            $total_design_counts->{MGP_BESPOKE}       += $project_counts->{$status_obj->project_status_id}->{MGP_BESPOKE} || 0;            
        }
        if($status_obj->order_by >= 75){
            $total_vector_counts->{EUCOMM}       += $project_counts->{$status_obj->project_status_id}->{EUCOMM}  || 0;
            $total_vector_counts->{KOMP}         += $project_counts->{$status_obj->project_status_id}->{KOMP}    || 0;
            $total_vector_counts->{NORCOMM}      += $project_counts->{$status_obj->project_status_id}->{NORCOMM} || 0;
            $total_vector_counts->{EUTRACC}      += $project_counts->{$status_obj->project_status_id}->{EUTRACC} || 0;
            $total_vector_counts->{EUCOMM_TOOLS} += $project_counts->{$status_obj->project_status_id}->{EUCOMM_TOOLS} || 0;
            $total_vector_counts->{EUCOMM_TOOLS_CRE} += $project_counts->{$status_obj->project_status_id}->{EUCOMM_TOOLS_CRE} || 0;
            $total_vector_counts->{IS_SWITCH}       += $project_counts->{$status_obj->project_status_id}->{IS_SWITCH} || 0;              
            $total_vector_counts->{TPP}       += $project_counts->{$status_obj->project_status_id}->{TPP} || 0;            
            $total_vector_counts->{MGP_BESPOKE}       += $project_counts->{$status_obj->project_status_id}->{MGP_BESPOKE} || 0;            
        }
        if($status_obj->order_by >= 95){
            $total_es_cell_counts->{EUCOMM}       += $project_counts->{$status_obj->project_status_id}->{EUCOMM}  || 0;
            $total_es_cell_counts->{KOMP}         += $project_counts->{$status_obj->project_status_id}->{KOMP}    || 0;
            $total_es_cell_counts->{NORCOMM}      += $project_counts->{$status_obj->project_status_id}->{NORCOMM} || 0;
            $total_es_cell_counts->{EUTRACC}      += $project_counts->{$status_obj->project_status_id}->{EUTRACC} || 0;
            $total_es_cell_counts->{EUCOMM_TOOLS} += $project_counts->{$status_obj->project_status_id}->{EUCOMM_TOOLS} || 0;
            $total_es_cell_counts->{EUCOMM_TOOLS_CRE} += $project_counts->{$status_obj->project_status_id}->{EUCOMM_TOOLS_CRE} || 0;
            $total_es_cell_counts->{IS_SWITCH}       += $project_counts->{$status_obj->project_status_id}->{IS_SWITCH} || 0;              
            $total_es_cell_counts->{TPP}       += $project_counts->{$status_obj->project_status_id}->{TPP} || 0;            
            $total_es_cell_counts->{MGP_BESPOKE}       += $project_counts->{$status_obj->project_status_id}->{MGP_BESPOKE} || 0;            
        }
        if($status_obj->order_by >= 115){
            $total_mouse_counts->{EUCOMM}       += $project_counts->{$status_obj->project_status_id}->{EUCOMM}  || 0;
            $total_mouse_counts->{KOMP}         += $project_counts->{$status_obj->project_status_id}->{KOMP}    || 0;
            $total_mouse_counts->{NORCOMM}      += $project_counts->{$status_obj->project_status_id}->{NORCOMM} || 0;
            $total_mouse_counts->{EUTRACC}      += $project_counts->{$status_obj->project_status_id}->{EUTRACC} || 0;
            $total_mouse_counts->{EUCOMM_TOOLS} += $project_counts->{$status_obj->project_status_id}->{EUCOMM_TOOLS} || 0;
            $total_mouse_counts->{EUCOMM_TOOLS_CRE} += $project_counts->{$status_obj->project_status_id}->{EUCOMM_TOOLS_CRE} || 0;
            $total_mouse_counts->{IS_SWITCH}       += $project_counts->{$status_obj->project_status_id}->{IS_SWITCH} || 0;  
            $total_mouse_counts->{TPP}       += $project_counts->{$status_obj->project_status_id}->{TPP} || 0;            
            $total_mouse_counts->{MGP_BESPOKE}       += $project_counts->{$status_obj->project_status_id}->{MGP_BESPOKE} || 0;            
        }
    }

    $c->stash->{total_es_cell_counts} = $total_es_cell_counts;
    $c->stash->{total_vector_counts}  = $total_vector_counts;
    $c->stash->{total_design_counts}  = $total_design_counts;
    $c->stash->{total_mouse_counts}   = $total_mouse_counts;  
}

=head2 ep_summary

Huge report that shows the status of all genes that have gone into electroporation.

=cut

my $CSV_DIR = dir( '/software/team87/brave_new_world/data/generated' );
    
sub ep_summary : Local {
    my ( $self, $c ) = @_;

    my $file = $CSV_DIR->file( 'ep_summary.csv' );
    try {
        my $fh = $file->openr;
        $c->response->content_type('text/comma-separated-values');
        $c->response->header( 'Content-Disposition', 'attachment; filename="EP_summary.csv"' );
        $c->response->body( $fh );
    }
    catch {        
        $c->log->error( "open $file: $_" );
        $c->flash( error_msg => "EP Summary Report is temporarily unavailable, please try again later" );
        return $c->response->redirect( $c->uri_for( '/welcome' ) );
    };
}

=head2 epd_plate_summary

Shows status of epd plates

=cut

sub epd_plate_summary : Local {
    my ( $self, $c ) = @_;

    my $file = $CSV_DIR->file( 'epd_summary.csv' );

    try {
        my $fh = $file->openr;
        $c->response->content_type('text/comma-separated-values');        
        $c->response->header( 'Content-Disposition', 'attachment; filename="EPD_plate_summary.csv"' );
        $c->response->body( $fh );
    }
    catch {        
        $c->log->error( "open $file: $_" );
        $c->flash( error_msg => "EPD Plate Summary is temporarily unavailable, please try again later" );
        return $c->response->redirect( $c->uri_for( '/welcome' ) );
    };
}

=head2

Show summary of Komp projects

=cut

sub komp_cond_targ_trap_counts : Local {
    my ( $self, $c ) = @_;
    

    $c->stash->{columns} = get_or_update_cached( $c, 'Komp_summary_columns',
                                                 sub { get_komp_summary_columns() } );
 

    $c->stash->{rows} =  get_or_update_cached( $c, 'Komp_summary_data',
                                               sub {get_komp_summary_data( $c->model('HTGTDB') ) } );    
}

=head2 _update_unassigned_es_cell_status

Updates the status of the cell - which center it belongs to and (interest/assigned/injected)

=cut

sub _update_unassigned_es_cell_status : Local {
    my ( $self, $c ) = @_;
    unless ( $c->check_user_roles('eucomm_edit') ) {
        $c->flash->{error_msg} = "You are not authorised to use this function";
        $c->response->redirect( $c->uri_for('/') );
        return 0;
    }

    my $status = $c->req->params->{value};
    $status = 'NULL' if $status eq '-';
    my $field = $c->req->params->{field};
    my $ids   = $c->req->params->{id};

    $c->log->debug("The status being assigned is: $status to $ids");

    my $dt   = DateTime->now;
    my $date = $dt->day . '-' . $dt->month_abbr . '-' . $dt->year;

    my ( $well_id, $gene_id ) = split /_/, $ids;

    # A hack to work with the assigned cell page - I can't face going through the existing code to get a gene_id.
    if ( !defined $gene_id or $gene_id eq '' ) {
        my $ws_row = $c->model('HTGTDB::WellSummary')->find(
            { epd_well_id => $well_id },
            {
              key => 'unique_epd_well_id'    # Tells DBIx which unique key to search on - defined in the HTGTDB DBIx model
            }
        );
        $gene_id = $ws_row->gene_id;
    }

    #my $model   = $c->model(q(HTGTDB))->storage->dbh;

    if ( $field =~ /assignment_comment/i ) {

        #Update the comment field - this has to be a new data_type.
        #The datatype is called assignment_comment
        my $cell_data = $c->model('HTGTDB::WellData')->update_or_create(
            {
              edit_user  => $c->user->id,
              well_id    => $well_id,
              data_type  => 'assignment_comment',
              data_value => $status
            }
        );
    }
    else {

        #Before doing this, run a find_or_create function:

        if ( $status !~ /NULL/i ) {
            my $project       = substr $field, 0, 3;
            my $cell_update   = 'cell_' . $project . '_status';
            my $assigned_date = 'cell_' . $project . '_assign_date';

            #This will check 1) exists, if exists update 2) else create with value (dictated by HTGTDB mod)
            my $cell_data = $c->model('HTGTDB::WellData')->update_or_create(
                {
                  edit_user  => $c->user->id,
                  well_id    => $well_id,
                  data_type  => $cell_update,
                  data_value => $status,
                }
            );

            my $cell_date = $c->model('HTGTDB::WellData')->update_or_create(
                {
                  edit_user  => $c->user->id,
                  well_id    => $well_id,
                  data_type  => $assigned_date,
                  data_value => $date,
                }
            );

            #Update the gene - woot.
            #my $gene_data = $c->model('HTGTDB::GeneInfo')->find( { gene_id => $gene_id } )->update( { $field => $status, } );
        }

        else {
            my $project       = substr $field, 0, 3;
            my $assigned_date = 'cell_' . $project . '_assign_date';
            my $cell_update   = 'cell_' . $project . '_status';
            #my $gene_data     = $c->model('HTGTDB::GeneInfo')->find( { gene_id => $gene_id } )->update( { $field => undef } );
            my $cell_data     = $c->model('HTGTDB::WellData')->update_or_create( { well_id => $well_id, data_type => $cell_update, } )->delete;
            my $cell_date     = $c->model('HTGTDB::WellData')->update_or_create( { well_id => $well_id, data_type => $assigned_date, } )->delete;
        }

    }

    $c->res->body( $c->req->params->{value} );

}

=head2 komp_es_cells

Report page to display all distributable KOMP ES Cells.

=cut

sub komp_es_cells : Local {
    my ( $self, $c ) = @_;

    my $rs = $c->model('HTGTDB::WellSummary')->search(
        {
            epd_distribute          => 'yes',
            'gene_info.arq_sources' => { 'like' => '%komp%' }
        },
        {
            join => { gene => 'gene_info' },
            prefetch => [ { gene => 'gene_info' }, { design_instance => { design => 'start_exon' } } ],
            order_by => { -asc => 'epd_well_name' }
        }
    );

    my %es_cells;
    my @es_cell_keys;

    while ( my $cell = $rs->next ) {
        push( @es_cell_keys, $cell->epd_well_name );

        my $mgi_id;
        eval {
            $mgi_id = $c->model('HTGTDB::GnmGeneName')->search( { gene_id => $cell->gene_id, source => 'MGI_ID' } )->first->name;
            unless ( $mgi_id =~ /^MGI/ ) { $mgi_id = 'MGI:' . $mgi_id; }
        };

        my $allele;
        eval {
            $allele = $c->model('HTGTDB::WellData')->find(
                {
                    well_id   => $cell->epd_well_id,
                    data_type => 'synthetic_allele_id'
                },
                { key => 'well_id_data_type' }
            )->data_value;
        };

        $es_cells{ $cell->epd_well_name } = {
            es_cell_line => $cell->es_cell_line,
            symbol       => $cell->gene->gene_info->first->mgi_symbol,
            mgi_id       => $mgi_id,
            ensembl      => $cell->gene->gene_info->first->ensembl_id,
            otter        => $cell->gene->gene_info->first->otter_id,
            target       => $cell->design_instance->design->start_exon->primary_name,
            design       => $cell->design_instance->design_id,
            bac          => $cell->bac,
            allele       => $allele,
            cassette     => $cell->cassette,
            backbone     => $cell->backbone,
        };
    }

    $c->stash->{es_cells}     = \%es_cells;
    $c->stash->{es_cell_keys} = \@es_cell_keys;
}

sub microinjections : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'report/microinjection.tt';
}

sub allele_overall_pass : Local {
    my ( $self, $c ) = @_;

    my $report = HTGT::Utils::Report::AlleleOverallPass->new( $c->model( 'IDCCMart' ) );

    $c->stash->{template} = 'report/generic_iterator';
    $c->stash->{report}   = $report;    
}

sub sequencing_archive_labels : Local {
    my ( $self, $c ) = @_;

    my $report = HTGT::Utils::Report::SequencingArchiveLabels->new( schema => $c->model( 'HTGTDB' )->schema );

    $c->stash->{template} = 'report/generic_iterator';
    $c->stash->{report}   = $report;
}   

sub assigned_genes_and_cells : Local {
    my ( $self, $c ) = @_;
   
    $c->stash->{template} = 'report/assigned_genes_and_cells.tt';
}

=head2 _assigned_genes_and_cells_table

Produces enough data to offer the user a GENE CENTRIC view that also lists the assigned clones
for that gene on a single line.

Options allow user to filter the list by genes (& assigned clones) assigned ONLY to eucomm, komp,
assigned (at least) to sanger or (at least) to the other four eucomm mouse-production centers.

=cut 

sub _assigned_genes_and_cells_table : Local {
    my ( $self, $c ) = @_;
    unless ( $c->check_user_roles('eucomm') || $c->check_user_roles('eucomm_edit') || $c->check_user_roles('edit') ) {
        $c->flash->{error_msg} = "You are not authorised to use this page, you must log-in first.";
        $c->response->redirect( $c->uri_for('/') );
        return 0;
    }
    my $at_least_sanger = $c->req->params->{at_least_sanger};
    my $at_least_others = $c->req->params->{at_least_others};

    my $genes_ref = get_assigned_genes_and_clones( $c, $at_least_sanger, $at_least_others );

    my @gene_list = sort { $a->{name} cmp $b->{name} } values %$genes_ref;

    my $count = scalar(@gene_list);
    $c->log->debug("size of gene list: $count");
    $c->stash->{list_type} = ' assigned - either by gene or by clone';
    $c->stash->{genes}     = \@gene_list;
    $c->stash->{count}     = $count;
    $c->stash->{timestamp} = DateTime->now;
}

=head2 _clones_by_gene

Returns a list of clones for the input gene-symbol.

The intent is that the list can be edited for assign statuses etc.

=cut

sub _clones_by_gene : Local {
    my ( $self, $c ) = @_;
   
    my $gene_symbol = $c->req->params->{gene_symbol};
    $c->log->debug("Fetching clones for $gene_symbol");
    my $returned_genes = {};
    if ($gene_symbol) {
        $returned_genes = get_clones_by_gene( $c, $gene_symbol );
    }

    $c->stash->{gene} = $gene_symbol;
    my @tmp = ();
    if ( defined $returned_genes->{$gene_symbol} ) {
        @tmp = sort { $a->{name} cmp $b->{name} } @{ $returned_genes->{$gene_symbol} };
    }
   
    $c->stash->{count}     = scalar(@tmp);
    $c->stash->{epd_wells} = \@tmp;
    $c->stash->{timestamp} = DateTime->now;
}

sub _clones_by_epd : Local {
    my ( $self, $c ) = @_;
    unless ( $c->check_user_roles('eucomm') || $c->check_user_roles('eucomm_edit') || $c->check_user_roles('edit') ) {
        $c->flash->{error_msg} = "You are not authorised to use this page, you must log-in first.";
        $c->response->redirect( $c->uri_for('/') );
        return 0;
    }
    my $epd_well_name = $c->req->params->{epd_well_name};
    $c->log->debug("Fetching clones for $epd_well_name");
    my $returned_clones = [];
    if ($epd_well_name) {
        $returned_clones = get_clones_by_epd( $c, $epd_well_name );
    }

    $c->log->debug( "Got array of cells: " . Dumper($returned_clones) );
    my $clone = $returned_clones->[0];
    if ($clone) {
        $c->stash->{gene} = $clone->{gene_name};
    }
    $c->stash->{template}  = "report/_clones_by_gene.tt";
    $c->stash->{count}     = scalar( @{$returned_clones} );
    $c->stash->{epd_wells} = $returned_clones;
    $c->stash->{timestamp} = DateTime->now;
}

=head2

Produces a list of genes where each gene has distributable clones, but none
of the clones have been assigned to any center.

=cut

sub _unassigned_genes_table : Local {
    my ( $self, $c ) = @_;

    $c->log->debug("starting fetch for unassigned genes");
    my $genes_ref = get_unassigned_genes($c);
    my @gene_list = sort { $a->{name} cmp $b->{name} } values %$genes_ref;

    my $count = scalar(@gene_list);
    $c->log->debug("after sort: $count");
    $c->stash->{genes}     = \@gene_list;
    $c->stash->{count}     = $count;
    $c->stash->{timestamp} = DateTime->now;
    
    if ($c->req->params->{view}||'' eq 'csvdl') {
        $c->stash->{template}  = 'report/_unassigned_genes_table.csvtt';        
    } else {
        $c->stash->{template}  = 'report/_unassigned_genes_table.tt';
    }
}

=head2 genes_or_cells_in_conflict

Produces a list of gene (and clones) where either the gene has been assigned
to two parties, or the gene owns clones assigned to two parties

=cut

sub _genes_or_cells_in_conflict_table : Local {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles('eucomm') || $c->check_user_roles('eucomm_edit') || $c->check_user_roles('edit') ) {
        $c->flash->{error_msg} = "You are not authorised to use this page, you must log-in first.";
        $c->response->redirect( $c->uri_for('/') );
        return 0;
    }

    $c->log->debug("Starting conflict fetch");
    my $genes_ref = get_genes_or_cells_in_conflict($c);
    $c->log->debug( "size of retrieved gene ref: " . scalar( keys %$genes_ref ) );
    my @gene_list = sort { $a->{name} cmp $b->{name} } values %$genes_ref;

    my $count = scalar(@gene_list);
    $c->log->debug("after sort: $count");
    $c->stash->{list_type} = ' With conflicting gene or clone assignments. ';
    $c->stash->{genes}     = \@gene_list;
    $c->stash->{count}     = $count;
    $c->stash->{timestamp} = DateTime->now;
    $c->stash->{template}  = 'report/_assigned_genes_and_cells_table.tt';
}

=head2 get_projects

Bulk download report for Kevin Dawson (Komp) that lists all of the projects in our system.

Data is run out primarily from MGI_Gene, Project and ProjectStatus.

=cut

sub get_projects : Local {
  my ( $self, $c ) = @_;
  
  # note - status_change_date instead of datetime - means that only significant changes are communicated
  # to MGI
  
  my $sql  = qq [
    select 
      mgi_gene.MGI_ACCESSION_ID gene_id, 
      project_id allele_id, 
      project_status.name pipeline_status,
      coalesce( status_change_date, project.edit_date ) datetime,
      mgi_gene.MARKER_SYMBOL, 
      is_komp_csd komp, 
      is_eucomm eucomm, 
      is_norcomm norcomm,
      is_eucomm_tools eucomm_tools,
      is_eucomm_tools_cre eucomm_tools_cre,
      is_switch switch,
      is_tpp tpp,
      is_mgp_bespoke mgp_bespoke,
      design_plate_name design_plate_name, 
      design_well_name design_well_name,
      intvec_plate_name intvec_plate_name, 
      intvec_well_name intvec_well_name,
      targvec_plate_name, 
      targvec_well_name, 
      targvec_pass_level, 
      cassette, 
      backbone, 
      total_colonies, 
      colonies_picked, 
      epd_distribute,
      is_latest_for_gene,
      phenotype_url,
      distribution_centre_url
    from 
      mgi_gene, project, project_status
    where 
      mgi_gene.MGI_GENE_ID = project.mgi_gene_id
      and project_status.project_status_id = project.project_status_id
      order by to_number(design_plate_name), design_well_name, pipeline_status
  ];

  my $data = get_or_update_cached( $c, 'get_projects', sub { HTGT::Utils::DBI::process_statement( $c, $c->model('HTGTDB')->storage->dbh, $sql ) } );
  
  $c->stash->{columns} = $data->{columns};
  $c->stash->{rows}    = $data->{rows};
  
  if    ( $c->req->params->{view} =~ /csv/ ) { $c->stash->{template} = 'report/generic_dbi.csvtt'; }
  elsif ( $c->req->params->{view} =~ /tab/ ) { $c->stash->{template} = 'report/generic_dbi.tabtt'; }
}

=head2 get_all_targeting_vectors

Bulk download report for Kevin Dawson (Komp) that lists all of the targeting vectors in our system.

Data is run out primarily from MGI_Gene, Projects and Well_Summary_By_DI.

=cut

sub get_all_targeting_vectors : Local {
  my ( $self, $c ) = @_;
  my $sql = q[
    select
      distinct
      p.project_id,
      p.is_eucomm EUCOMM, 
      p.is_komp_csd KOMP,
      p.is_mgp MGP,
      p.is_norcomm NORCOMM,
      p.is_eucomm_tools EUCOMM_TOOLS,
      p.is_eucomm_tools_cre EUCOMM_TOOLS_CRE,
      p.is_tpp TPP,
      p.is_mgp_bespoke MGP_BESPOKE
      p.is_switch SWITCH,
      g.mgi_accession_id MGI,
      p.design_plate_name || p.design_well_name DESIGN,
      p.design_id,
      p.design_instance_id,
      ws.pcs_plate_name PCS_PLATE,
      ws.pcs_well_name PCS_WELL,
      pc_clone.data_value PC_CLONE,
      ws.pc_pass_level PCS_QC_RESULT,
      ws.pc_qctest_result_id PCS_QC_RESULT_ID,
      ws.pcs_distribute PCS_DISTRIBUTE,
      pcs_com.data_value "PCS_COMMENTS",
      ws.pgdgr_plate_name PGS_PLATE,
      ws.pgdgr_well_name PGS_WELL,
      ws.pgdgr_well_id PGS_WELL_ID,
      p.cassette,
      p.backbone,
      pg_clone.data_value PG_CLONE,
      ws.pg_pass_level PGS_QC_RESULT,
      ws.pg_qctest_result_id PGS_QC_RESULT_ID,
      ws.pgdgr_distribute PGS_DISTRIBUTE,
      pgs_com.data_value "PGS_COMMENTS",
      g.marker_symbol,
      g.ensembl_gene_id,
      g.vega_gene_id
    from
      well_summary_by_di ws
      join project p on p.project_id = ws.project_id
      join mgi_gene g on g.mgi_gene_id = p.mgi_gene_id
      left join well_data pc_clone on pc_clone.well_id = ws.pcs_well_id and pc_clone.data_type = 'clone_name'
      left join well_data pg_clone on pg_clone.well_id = ws.pgdgr_well_id and pg_clone.data_type = 'clone_name'
      left join well_data pcs_com on pcs_com.well_id = ws.pcs_well_id and pcs_com.data_type = 'COMMENTS'
      left join well_data pgs_com on pgs_com.well_id = ws.pgdgr_well_id and pgs_com.data_type = 'COMMENTS'
    order by ws.pgdgr_plate_name, ws.pgdgr_well_name
  ];
  
  my $data = get_or_update_cached( $c, 'get_all_targeting_vectors', sub { HTGT::Utils::DBI::process_statement( $c, $c->model('HTGTDB')->storage->dbh, $sql ) } );
  
  $c->stash->{columns} = $data->{columns};
  $c->stash->{rows}    = $data->{rows};
  
  if    ( $c->req->params->{view} =~ /csv/ ) { $c->stash->{template} = 'report/generic_dbi.csvtt'; }
  elsif ( $c->req->params->{view} =~ /tab/ ) { $c->stash->{template} = 'report/generic_dbi.tabtt'; }
}

=head2 get_all_alleles

Bulk download report for Kevin Dawson (Komp) that lists all of the alleles in our system 
from the perspective of freezer plates.

Data is run out primarily from MGI_Gene, Projects and Well_Summary_By_DI.

=cut

sub get_all_alleles : Local {
  my ( $self, $c ) = @_;
  my $sql = q[
    select
      distinct
      p.project_id,
      p.is_eucomm EUCOMM, 
      p.is_komp_csd KOMP,
      p.is_mgp MGP,
      p.is_norcomm NORCOMM,
      p.is_eucomm_tools EUCOMM_TOOLS,
      p.is_eucomm_tools_cre EUCOMM_TOOLS_CRE,
      p.is_tpp TPP,
      p.is_mgp_bespoke MGP_BESPOKE,
      p.is_switch SWITCH,
      g.mgi_accession_id MGI,
      p.design_plate_name || p.design_well_name DESIGN,
      p.design_id,
      p.design_instance_id,
      ws.pcs_plate_name PCS_PLATE,
      ws.pcs_well_name PCS_WELL,
      pc_clone.data_value PC_CLONE,
      ws.pc_pass_level PCS_QC_RESULT,
      ws.pc_qctest_result_id PCS_QC_RESULT_ID,
      ws.pcs_distribute PCS_DISTRIBUTE,
      pcs_com.data_value "PCS_COMMENTS",
      ws.pgdgr_plate_name PGS_PLATE,
      ws.pgdgr_well_name PGS_WELL,
      ws.pgdgr_well_id PGS_WELL_ID,
      p.cassette,
      p.backbone,
      pg_clone.data_value PG_CLONE,
      ws.pg_pass_level PGS_QC_RESULT,
      ws.pg_qctest_result_id PGS_QC_RESULT_ID,
      ws.pgdgr_distribute PGS_DISTRIBUTE,
      pgs_com.data_value "PGS_COMMENTS",
      ws.epd_well_name EPD,
      (
        case
          when regexp_like(ws.es_cell_line, 'AB2.2') then 'AB2.2'
          when regexp_like(ws.es_cell_line, 'C2') then 'C2'
          when regexp_like(ws.es_cell_line, 'JM8.F6') then 'JM8.F6'
          when regexp_like(ws.es_cell_line, 'JM8.N3') then 'JM8.N3'
          when regexp_like(ws.es_cell_line, 'JM8.N4') then 'JM8.N4'
          when regexp_like(ws.es_cell_line, 'JM8.N19') then 'JM8.N19'
          when regexp_like(ws.es_cell_line, 'JM8A') then 'JM8A (Agouti)'
          when regexp_like(ws.es_cell_line, 'JM8B') then 'JM8B (Agouti)'
          when regexp_like(ws.es_cell_line, 'JM8') then 'JM8'
          else ws.es_cell_line
        end
      ) ES_CELL_LINE,
      substr( regexp_substr(ws.es_cell_line,'[p|P]\d+'), 2, length( regexp_substr(ws.es_cell_line,'[p|P]\d+') ) ) CELL_LINE_PASSAGE,
      ws.epd_pass_level EPD_QC_RESULT,
      ws.epd_qctest_result_id EPD_QC_RESULT_ID,
      ws.epd_distribute,
      ws.targeted_trap,
      epd_com.data_value "EPD_COMMENTS",
      fp.well_name FP,
      g.marker_symbol,
      g.ensembl_gene_id,
      g.vega_gene_id
    from 
      well_summary_by_di ws
      join project p on p.project_id = ws.project_id
      join mgi_gene g on g.mgi_gene_id = p.mgi_gene_id
      join well fp on fp.parent_well_id = ws.epd_well_id and ( fp.well_name not like 'REPD%' and fp.well_name not like 'RHEPD%' )
      left join well_data pc_clone on pc_clone.well_id = ws.pcs_well_id and pc_clone.data_type = 'clone_name'
      left join well_data pg_clone on pg_clone.well_id = ws.pgdgr_well_id and pg_clone.data_type = 'clone_name'
      left join well_data pcs_com on pcs_com.well_id = ws.pcs_well_id and pcs_com.data_type = 'COMMENTS'
      left join well_data pgs_com on pgs_com.well_id = ws.pgdgr_well_id and pgs_com.data_type = 'COMMENTS'
      left join well_data epd_com on epd_com.well_id = ws.epd_well_id and epd_com.data_type = 'COMMENTS'
    order by fp.well_name
  ];
  
  my $data = get_or_update_cached( $c, 'get_all_alleles', sub { HTGT::Utils::DBI::process_statement( $c, $c->model('HTGTDB')->storage->dbh, $sql ) } );
  
  $c->stash->{columns} = $data->{columns};
  $c->stash->{rows}    = $data->{rows};
  
  if    ( $c->req->params->{view} =~ /csv/ ) { $c->stash->{template} = 'report/generic_dbi.csvtt'; }
  elsif ( $c->req->params->{view} =~ /tab/ ) { $c->stash->{template} = 'report/generic_dbi.tabtt'; }
}

=head2 get_mig_microinjection_info

XML feed for MIG to supply them with the information they need on a specific 
ES Cell (EPD) clone in order to insert it into their system

=cut

sub get_mig_microinjection_info : Local {
  my ( $self, $c ) = @_;
  
  my $response_text;
  my $epd_id  = $c->req->params->{EPD_ID};
  my $xml     = new XML::Writer( OUTPUT => \$response_text );
  
  $xml->startTag(
    'mig_mir_info',
    'xmlns:xsi'                     => 'http://www.w3.org/2001/XMLSchema-instance',
    'xsi:noNamespaceSchemaLocation' => 'http://migsrvdev.internal.sanger.ac.uk:8080/MouseGeneticsCentral/docs/mig-mir-info.xsd'
  );

  if ( ! $epd_id ) {
    $xml->dataElement('message','EPD_ID must be provided to this request');
  }
  else {

    $xml->dataElement('epd_id',$epd_id);

    my $well_summary_rs = $c->model('HTGTDB::WellSummaryByDI')->search( { epd_well_name => $epd_id } );
    
    if ( $well_summary_rs->count == 0 ) {
      $xml->dataElement('message','No EPD well found for input EPD_ID');
    }
    else {
      if ( $well_summary_rs->count > 1 ) {
        $xml->dataElement('message','More than one summary row found for input EPD_ID');
      }

      my $ws_row = $well_summary_rs->first;

      if ( ! $ws_row->project_id ) {
        $xml->dataElement('message','Cant find project for EPD_ID');
      }
      else {

        $ws_row = $c->model('HTGTDB::WellSummaryByDI')->search(
          { epd_well_name => $epd_id },
          {
            prefetch => [
              { 'project' => 'mgi_gene' },
              { 'design_instance' => { 'design' => [ 'start_exon', 'end_exon' ] } }
            ]
          }
        )->first;

        # find the user_qc_result
        my $user_qc_result = $c->model('HTGTDB::Well')->find({well_id => $ws_row->epd_well_id})->user_qc_result;
        my $five_prime_lrpcr;
        my $three_prime_lrpcr;
        
        if ($user_qc_result){
            $five_prime_lrpcr = $user_qc_result->five_lrpcr;
            $three_prime_lrpcr = $user_qc_result->three_lrpcr;
        }
        
        $xml->dataElement( 'gene_symbol', $ws_row->project->mgi_gene->marker_symbol );
        $xml->dataElement( 'mgi_accession_id', $ws_row->project->mgi_gene->mgi_accession_id);

        # Extra processing for the design type
        my $design_type = $ws_row->design_instance->design->design_type;
        if    ( $design_type =~ /KO/i )  { $design_type = 'Conditional Knockout'; }
        elsif ( $design_type =~ /Del/i ) { $design_type = 'Deletion'; }
        $xml->dataElement( 'design_type', $design_type );

        
        # Extra processing for the ES Cell Line
        # - this is to stop MIG's XML reader from erroring out when they
        #   get a cell line name that isn't in their lookup table... 
        #   Why oh why can't they write a regular expression?!?
        my ($es_cell_line) = $ws_row->es_cell_line =~ m/^([^\s(]+)/;
        $xml->dataElement( 'es_cell_line', $es_cell_line );

        # Extra processing for coat colour...
        # - If the cell-line has the word 'Agouti' in it somehwere, it's brown
        # - If it is has 'JM8A' it's brown and black
        # - else black
        my @colours;
        if    ( $ws_row->es_cell_line =~ /agouti/i ) { push( @colours, 'agouti' ); }
        elsif ( $ws_row->es_cell_line =~ /JM8A/i )   { push( @colours, 'black' ); push( @colours, 'agouti' ); }
        else                                         { push( @colours, 'black' ); }
        foreach my $colour ( @colours ) { $xml->dataElement( 'coat_colour', $colour ); }

        # KOMP or EUCOMM
        my $project_source;
        if ( $ws_row->project->is_komp_csd )  { $project_source = 'KOMP'; }
        elsif ( $ws_row->project->is_eucomm ) { $project_source = 'EUCOMM'; }
        $xml->dataElement( 'provider',        'Bill Skarnes' );
        $xml->dataElement( 'project_funding', $project_source );

        $xml->startTag('allele');

          $xml->dataElement( 'official_allele_name', $ws_row->allele_name );
          if ( $ws_row->allele_name =~ /^(.*)<sup>(.*)<\/sup>$/i ){
            $xml->dataElement( 'gene_symbol',        $1 );
            $xml->dataElement( 'allele_superscript', $2 );
          }

          $xml->dataElement( 'cassette_code',           $ws_row->cassette );
          $xml->dataElement( 'cassette_uri',            'http://www.sanger.ac.uk/htgt/report/allele_page?project_id='.$ws_row->project_id );
          $xml->dataElement( 'allele_description_uri',  'http://www.sanger.ac.uk/htgt/report/gene_report?project_id='.$ws_row->project_id );

          my $critical_exons;
          my $start_exon = $ws_row->design_instance->design->start_exon->primary_name;
          my $end_exon   = $ws_row->design_instance->design->end_exon->primary_name;
          if ($start_exon eq $end_exon) { $critical_exons = $start_exon; }
          else                          { $critical_exons = $start_exon."-".$end_exon; }
          $xml->dataElement( 'critical_exons', $critical_exons );

          my $gene_id = '';
          
          my @mig_genes = $ws_row->design_instance->design->start_exon->transcript->gene_build_gene->genes;
          #I can't think of what to do if the gbg is linked to TWO mig-genes
          my $mig_gene = $mig_genes[0];
          
          #An alternative method of looking up a mig gene - less reliable than the one above.
          #my $mig_gene = $c->model('HTGTDB::GnmGene')->find({ primary_name=> $ws_row->project->mgi_gene->marker_symbol });
          
          if($mig_gene){
            $gene_id = $mig_gene->id;
          }
          
          $xml->dataElement( 'gene_id', $gene_id );

          $xml->startTag('user_qc');
          # add user_qc_result tag
             $xml->dataElement( 'five_prime_lrpcr', $five_prime_lrpcr );
             $xml->dataElement( 'three_prime_lrpcr', $three_prime_lrpcr );
          $xml->endTag('user_qc');
        $xml->endTag('allele');

      }
    }

  }

  $xml->endTag('mig_mir_info');
  
  $c->res->body($response_text);
  $c->res->content_type('text/xml');
}

sub distribute_counts_by_design_plate : Local {
    my ( $self, $c ) = @_;
    unless ( $c->check_user_roles('edit') ) {
        $c->flash->{error_msg} = "You are not authorised to use this page, you must log-in first.";
        $c->response->redirect( $c->uri_for('/') );
        return 0;
    }

    my ( $return_ref ) = HTGTDB::WellSummary->get_distribute_counts_by_design_plate($c);

    my @return_list = sort { $b->{name} <=> $a->{name} } values(%$return_ref);

    $c->stash->{plates} = \@return_list;
}

=head2 get_gene_identifiers

given a mgi_gene id, get a list of the gene identifiers

=cut

sub get_gene_identifiers : Private {
    my ( $self, $c, $mgi_gene_id ) = @_;
    
    # get  mgi_gene
    my $mgi_gene = $c->model('HTGTDB::MGIGene')->find( { mgi_gene_id => $mgi_gene_id } );
    
    # get ensembl gene id & vega gene id from mgi_gene table
    my $ensembl_gene_id = $mgi_gene->ensembl_gene_id;
    my $vega_gene_id = $mgi_gene->vega_gene_id;
   
    # holder for all gene identifiers
    my @gene_identifiers;
    
    if ($ensembl_gene_id ne ""){
       push @gene_identifiers, $ensembl_gene_id;
    }
    if ($vega_gene_id ne "") {
       push @gene_identifiers, $vega_gene_id;
    }
    
    # get gene id from mgi website (if unavailable falls back to mgi_sanger table)
    push @gene_identifiers, get_gene_ids($mgi_gene);
    @gene_identifiers = uniq @gene_identifiers;
    return \@gene_identifiers;
}

sub gene_traps : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'report/gene_traps/gene_trap.tt';
}

sub gene_trap_data : Local {
    my ( $self, $c ) = @_;
        my $dbh = $c->model('HTGTDB')->storage->dbh;
        
        my $query = "
                    select distinct
                        gene.ensembl_gene_id,
                        gtw.gene_trap_well_name,
                        pgt.splink_orientation,
                        gtw.five_prime_align_quality,
                        gtw.three_prime_align_quality,
                        gene.marker_symbol
                    
                    from mgi_gene gene
                    join project p on p.mgi_gene_id = gene.mgi_gene_id
                    join project_gene_trap_well pgt on p.project_id = pgt.project_id
                    join gene_trap_well gtw on gtw.gene_trap_well_id = pgt.gene_trap_well_id
                    
                    where ensembl_gene_id is not null
                    and p.is_trap = 1
                    and gtw.gene_trap_well_name not like 'EUCX%'
                    order by 1
                    ";
        
        $query = $dbh->prepare( $query );
        $query->execute();
        
        my %DATA = ();
        
        while ( my $row = $query->fetchrow_arrayref() ) {
            my $gene = $row->[0];
            my $marker = $row->[5];
            my $gene_trap_well_name = $row->[1];

            $DATA{$gene}{MARKER} = $marker;

            if ( defined $row->[2] ) {
                my $splink_orientation = $row->[2];
                my $alignment_confidence;
                
                if ( $splink_orientation == 3 ) {
                    $alignment_confidence = $row->[4];
                } else {
                    $alignment_confidence = $row->[3];
                }
                
                if ( $alignment_confidence < 0.5 ) {
                    push @{ $DATA{ $gene }{ LOW } }, $gene_trap_well_name;
                } elsif ( $alignment_confidence >= 0.5 && $alignment_confidence <= 0.79 ) {
                    push @{ $DATA{ $gene }{ MEDIUM } }, $gene_trap_well_name;                    
                } else { 
                    push @{ $DATA{ $gene }{ HIGH } }, $gene_trap_well_name;                    
                }
                
            } else {
                # Dealing with a paired hit i.e. a null value.
                my $alignment_confidence = $row->[3];
                if ( $alignment_confidence < 0.5 ) {
                    push @{ $DATA{ $gene }{ LOW } }, $gene_trap_well_name;
                } elsif ( $alignment_confidence >= 0.5 && $alignment_confidence <= 0.79 ) {
                    push @{ $DATA{ $gene }{ MEDIUM } }, $gene_trap_well_name;                    
                } else { 
                    push @{ $DATA{ $gene }{ HIGH } }, $gene_trap_well_name;                    
                }                
            }
        }
        $c->stash->{gene_traps} = \%DATA;
        
        if ( $c->req->params->{view} =~ /csv/ ) {
            $c->stash->{template} = 'report/gene_traps/gene_trap_data.csvtt';
        } else {       
            $c->stash->{template} = 'report/gene_traps/gene_trap_data.tt';
        }
}

sub gene_trap_das_clusters : Local {
    my ( $self, $c ) = @_;
    my @data = (
        "1, EUCE00127a10, 0 ",
        "1, EUCE00131b09 ,0 ",
        "1, EUCE00140c09, 1 ",
        "1, EUCE00143b11, 0 ",
        "1, EUCE00145f01, 1 ",
        "1, EUCE0015h09, 1  ",
        "1, EUCE0016a08, 0  ",
        "1, EUCE0020h10, 0  ",
        "1, EUCE0021b10, 1  ",
        "1, EUCE0030d06, 1  ",
        "1, EUCE0030d10, 0  ",
        "1, EUCE0032a03, 1  ",
        "1, EUCE0035b07, 1  ",
        "1, EUCE0055h09, 1  ",
        "1, EUCE0071e03, 0  ",
        "1, EUCE0094b11, 0  ",
        "1, EUCE0151e04, 1  ",
        "1, EUCE0152h07, 1  ",
        "1, EUCE0158f08, 0  ",
        "1, EUCE0178d08, 0  ",
        "1, EUCE0188f06, 0  ",
        "1, EUCE0192h10, 0  ",
        "1, EUCE0208h09, 0  ",
        "1, EUCE0212h01, 0  ",
        "1, EUCE0215f09, 1  ",
        "1, EUCE0222e04, 0  ",
        "1, EUCE0230a02, 1  ",
        "1, EUCE0232g09, 0  ",
        "1, EUCE0236g09, 0  ",
        "1, EUCE0251a08 ,0  ",
        "1, EUCE0263f07 ,1  ",
        "1, EUCE0270g11 ,1  ",
        "1, EUCE0277d07 ,0  ",
        "1, EUCE0280b03 ,1  ",
        "1, EUCE0283f01 ,1  ",
        "1, EUCE308h10 ,0   ",
        "1, EUCE311g11 ,1   ",
        "1, EUCE311h12 ,0   ",
        "1, EUCE318b03 ,1   ",
        "1, EUCG0014e04 ,0  ",
        "2, EUCE00102f11, 0 ",
        "2, EUCE0193h06 ,0  ",
        "2, EUCE0214a11 ,1  ",
        "2, EUCE0231b03 ,0  ",
        "2, EUCE321f01 ,0   ",
        "4, EUCE0092e04, 0  ",
        "4, EUCE0229e09, 1  ",
        "4, EUCE313h11 ,1   ",
    );
    
    my %TRAPS = ();
    for my $cell ( @data ) {
        chomp $cell;
        my ( $clx, $name, $isPaired ) = split ',', $cell;
        $clx      =~ s/\s+//g;
        $name     =~ s/\s+//g;
        $isPaired =~ s/\s+//g;
        push @{ $TRAPS{$clx}{name} },$name;
        push @{ $TRAPS{$clx}{ispaired} },$isPaired;
    }
    
    $c->stash->{TRAPS} = \%TRAPS;
    
}

sub allele_page : Local {
    my ( $self, $c ) = @_;

    my $project = $c->model('HTGTDB::Project')->find( { project_id => $c->req->params->{project_id} }, { prefetch => [ 'mgi_gene', 'status' ] } );
    $c->stash->{draw_allele_map} = 'true';
    $c->stash->{project}     = $project;
    if (   ( $project->targeting_vector_id and $project->targvec_distribute eq 'yes' )
        or ( $project->targeting_vector_id and ( defined $project->epd_distribute and $project->epd_distribute > 0 ) ) )
    {
        HTGT::Controller::Report::Project::get_display_features( $self, $c );
        HTGT::Controller::Report::Project::get_vector_seq_features( $self, $c );
    }
    $c->forward('HTGT::View::NakedTT');
}

sub vector_page : Local {
    my ( $self, $c ) = @_;

    my $project = $c->model('HTGTDB::Project')->find( { project_id => $c->req->params->{project_id} }, { prefetch => [ 'mgi_gene', 'status' ] } );
    $c->stash->{project}     = $project;
    if (   ( $project->targeting_vector_id and $project->targvec_distribute eq 'yes' )
        or ( $project->targeting_vector_id and ( defined $project->epd_distribute and $project->epd_distribute > 0 ) ) )
    {
        HTGT::Controller::Report::Project::get_display_features( $self, $c );
        HTGT::Controller::Report::Project::get_vector_seq_features( $self, $c );
    }
    $c->forward('HTGT::View::NakedTT');
}

sub recovery_for_ep_no_screen_high_colonies : Local {
    my ( $self, $c ) = @_;
    my $include_only_wells_with_ep = $c->req->params->{only_wells_with_ep};
    
    my $return_rows = get_recovery_data_for_ep_no_screen_high_colonies($c, $include_only_wells_with_ep);
    $c->stash->{template} = 'report/recovery_for_ep.tt';
    $c->stash->{rows} = $return_rows;
}

sub recovery_for_ep_no_screen_low_colonies : Local {
    my ( $self, $c ) = @_;
    my $include_only_wells_with_ep = $c->req->params->{only_wells_with_ep};
    
    my $return_rows = get_recovery_data_for_ep_no_screen_low_colonies($c, $include_only_wells_with_ep);
    $c->stash->{template} = 'report/recovery_for_ep.tt';
    $c->stash->{rows} = $return_rows;
}

sub recovery_for_ep_no_screen_zero_colonies : Local {
    my ( $self, $c ) = @_;
    my $include_only_wells_with_ep = $c->req->params->{only_wells_with_ep};
    
    my $return_rows = get_recovery_data_for_ep_no_screen_zero_colonies($c, $include_only_wells_with_ep);
    $c->stash->{template} = 'report/recovery_for_ep.tt';
    $c->stash->{rows} = $return_rows;
}

sub recovery_for_ep_no_positives : Local {
    my ( $self, $c ) = @_;
    my $include_only_wells_with_ep = $c->req->params->{only_wells_with_ep};
    
    my $return_rows = get_recovery_data_for_epd_screened_with_no_positives($c, $include_only_wells_with_ep);
    $c->stash->{template} = 'report/recovery_for_ep.tt';
    $c->stash->{rows} = $return_rows;
}

sub alternate_clone_recovery : Local {
    my ( $self, $c ) = @_;
    
    if ( $c->req->param( 'no_alternates' ) ) {
        return $c->response->redirect( $c->uri_for( '/static/recovery_reports/alternate_clone_recovery_no_alternates.csv' ) );
    }
    elsif ( $c->req->param( 'in_recovery' ) ) {
        return $c->response->redirect( $c->uri_for( '/static/recovery_reports/alternate_clone_recovery_in_recovery.csv' ) );
    } 
    elsif ( $c->req->param( 'without_promoter' ) ) {
        return $c->response->redirect( $c->uri_for( '/static/recovery_reports/alternate_clone_recovery_promoterless.csv' ) );
    }
    else {
        return $c->response->redirect( $c->uri_for( '/static/recovery_reports/alternate_clone_recovery_promoter.csv' ) );
    }    
}

sub alternate_clone_recovery_status : Local {
    my ( $self, $c ) = @_;
    
    my $data = get_or_update_cached(
        $c,
        'alternate_clone_recovery_status',
        sub { get_alternate_clone_recovery_status( $c->model('HTGTDB') ) }
    );
    
    $c->stash->{template} = 'report/alternate_clone_recovery';
    $c->stash->{title}    = 'Alternate Clone Recovery Status';
    $c->stash->{rows}     = $data;
    $c->stash->{columns}  = \@HTGT::Utils::Report::AlternateCloneRecoveryStatus::COLUMNS; 
    $c->stash->{csv_uri}  = $c->uri_for( $c->action, { view => 'csvdl' } );
}

sub recovery_genes_by_stage_and_project : Local {
    my ( $self, $c ) = @_;
    my $is_eucomm = $c->req->param( 'is_eucomm' );
    my $is_komp_csd = $c->req->param( 'is_komp_csd' );
    my $status_code = $c->req->param( 'status_code' );
    my $stage = $c->req->param( 'stage' );
    my $opts = {};
    $opts->{stage} = $stage;
    if($is_eucomm){
        $opts->{is_eucomm} = $is_eucomm;
    }
    if($is_komp_csd){
        $opts->{is_komp_csd} = $is_komp_csd;
    }
    if($status_code){
        $opts->{status_code} = $status_code;
    }
    $opts->{dbh} = $c->model('HTGTDB')->storage->dbh;
    $c->log->debug('opts->dbh: '.$opts->{dbh});
    
    my $return_data = read_gene_recovery_table($opts);
    $c->stash->{columns} = $return_data->{columns};
    $c->stash->{rows}    = $return_data->{rows};
    if    ( $c->req->params->{view} =~ /csv/ ) { $c->stash->{template} = 'report/generic_dbi.csvtt'; }
}

sub recovery_projects_by_program_stage_and_status : Local {
    my ($self, $c) = @_;
    
    my $base_recovery_report_by_program_and_status_sql = qq[
        select distinct
        mgi_gene.marker_symbol, 
        gene_recovery.rdr_plates, 
        gene_recovery.rdr_attempts, 
        gene_recovery.gwr_plates, 
        gene_recovery.gwr_attempts,
        gene_recovery.acr_plates, 
        gene_recovery.acr_attempts, 
        project_status.order_by, project_status.name, project.design_plate_name, project.design_well_name, project.targvec_plate_name, project.targvec_well_name
        from 
        mgi_gene, gene_recovery, project, project_status
        where 
            mgi_gene.mgi_gene_id = gene_recovery.mgi_gene_id
            and project.mgi_gene_id = mgi_gene.mgi_gene_id
            and project.project_status_id = project_status.project_status_id
            and project.is_latest_for_gene = 1
        
    ];

    my $is_eucomm = $c->req->param( 'is_eucomm' );
    my $is_komp_csd = $c->req->param( 'is_komp_csd' );
    my $stage = $c->req->param( 'stage' );
    my $status_code = $c->req->param( 'status_code' );
    
    die "MUST have valid status code provided for recovery query" unless $status_code;
    die "stage must be acr, gwr or rdr " unless ($stage eq 'acr' || $stage eq 'gwr' || $stage eq 'rdr' );
    
    my $stage_sql;
    my $addon_sql;
    if($stage eq 'acr'){
        $stage_sql = ' and acr_attempts > 0 ';
    }
    if($stage eq 'gwr'){
        $stage_sql = ' and gwr_attempts > 0 ';
    }
    if($stage eq 'rdr'){
        $stage_sql = ' and rdr_attempts > 0 ';
    }
    if ($is_eucomm){
        
        $addon_sql = qq[
            and is_eucomm = 1 
            and project_status.code = '$status_code'
        ].qq[
            $stage_sql
        ].qq[
            order by marker_symbol, project_status.order_by 
        ];
        
    }elsif ($is_komp_csd){
        
        $addon_sql = qq[
            and is_komp_csd = 1 
            and project_status.code = '$status_code'
        ].qq[
            $stage_sql
        ].qq[
            order by marker_symbol, project_status.order_by 
        ];
        
    }else{
        die "not recognisable eucomm or komp";
    }
    
    my $sql = $base_recovery_report_by_program_and_status_sql . $addon_sql;
    $c->log->debug($sql);
    #my $sth = $c->model('HTGTDB')->storage->dbh->prepare($sql);
    my $data = HTGT::Utils::DBI::process_statement( $c, $c->model('HTGTDB')->storage->dbh, $sql );
  
    $c->stash->{columns} = $data->{columns};
    $c->stash->{rows}    = $data->{rows};
  
    if    ( $c->req->params->{view} =~ /csv/ ) { $c->stash->{template} = 'report/generic_dbi.csvtt'; }
}

sub show_redesign_toggle {
    my ( $self, $c, $project ) = @_;

    my $redesign_pipeline;
    if ( $project->is_komp_csd ) {
        $redesign_pipeline = 'is_komp_csd';
    }
    elsif ( $project->is_eucomm ) {
        $redesign_pipeline = 'is_eucomm';
    }
    else {
        # Can only redesign in EUCOMM and KOMP_CSD pipelines
        return 0;
    }

    # Is there already a redesign requested project in the relevant pipeline?
    my $redesign_requested = $project->mgi_gene->projects_rs->search(
        {
            $redesign_pipeline  => 1,
            'status.name'       => 'Redesign Requested'
        },
        {
            join => 'status'
        }
    );

    if ( $redesign_requested->count > 0 ) {
        # Can't have more than one redesign requested project per pipeline
        return 0;
    }

    # This may be a candidate for a redesign request
    return 1;
}        

sub piq_data :Local {
    my ( $self, $c ) = @_;

    $c->stash( piq_data => HTGT::Utils::Report::PIQData::get_piq_data( $c->model( 'HTGTDB' )->schema ) );
}

=head1 AUTHORS

Darren Oakley <do2@sanger.ac.uk>, 
Vivek Iyer <vvi@sanger.ac.uk>,
Dan Klose <dk3@sanger.ac.uk>,
David Keith Jackson <dj3@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

