package HTGT::Controller::NewQC;

use Moose;
use Path::Class;
use Bio::SeqIO;
use IO::String;
use HTGT::Constants qw( %PLATE_TYPES );
use HTGT::QC::Config;
use HTGT::QC::Run;
use HTGT::QC::Util::Alignment qw( alignment_match );
use HTGT::QC::Util::CigarParser;
use HTGT::QC::Util::ListFailedRuns;
use HTGT::QC::Util::ListLatestRuns;
use HTGT::QC::Util::SubmitQCFarmJob::ESCell;
use HTGT::QC::Util::SubmitQCFarmJob::Vector;
use HTGT::QC::Util::SubmitQCFarmJob::ESCellPreScreen;
use HTGT::QC::Util::KillQCFarmJobs;
use HTGT::QC::Util::ListTraceProjects;
use HTGT::Utils::QCTestResults qw( fetch_test_results_for_run );
use HTGT::Utils::Plate::Create qw( create_plate );
use Lingua::EN::Inflect qw( PL_N PL_V );
use List::MoreUtils qw( uniq firstval any );
use Try::Tiny;
use HTGT::QC::Util::CreateSuggestedQcPlateMap qw( create_suggested_plate_map get_sequencing_project_plate_names );
use IPC::Run ();
use Const::Fast;
use namespace::autoclean;
use JSON;

BEGIN { extends 'Catalyst::Controller'; }

const my $LOG_DIR => '/nfs/team87/update_escell_qc';

sub auto :Private {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles( 'edit' ) ) {
        $c->flash->{ error_msg } = "Please log in to acccess the QC system";
        $c->response->redirect( $c->uri_for( '/' ) );
        return;
    }
}

sub _list_profiles :Private {
    my ( $self, $c ) = @_;

    my @profiles = $c->model( 'HTGTDB::QCRun' )->search(
        {},
        {
            columns  => [ 'profile' ],
            distinct => 1,
            order_by => [ 'profile' ]
        }
    )->all;

    return [ map $_->profile, @profiles ];
}

sub _list_all_profiles :Private {
    my ( $self, $c ) = @_;

    [ sort HTGT::QC::Config->new->profiles ];
}

sub list :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $params = $self->_validated_list_params( $c );

    my %search;
    unless ( $c->req->param( 'show_all' ) ) {
        if ( $params->{sequencing_project} ) {
            $search{ 'me.sequencing_project' } = $params->{sequencing_project};
        }
        if ( $params->{template_plate} ) {
            $search{ 'template_plate.name' } = $params->{template_plate};
        }
        if ( $params->{profile} and $params->{profile} ne '-' ) {
            $search{ 'me.profile' } = $params->{profile};
        }
    }

    my $rs = $c->model( 'HTGTDB::QCRun' )->search(
        \%search,
        {
            join     => 'template_plate',
            order_by => { -desc => 'qc_run_date' },
            page     => $params->{page},
            rows     => $params->{page_size}
        }
    );

    my $pager = $rs->pager;
    if ( $pager->current_page != $pager->first_page ) {
        $params->{page} = $pager->current_page - 1;
        $c->stash( prev_page_uri => $c->uri_for( $c->action, $params ) );
    }
    if ( $pager->current_page != $pager->last_page ) {
        $params->{page} = $pager->current_page + 1;
        $c->stash( next_page_uri => $c->uri_for( $c->action, $params ) );
    }

    $c->stash( profiles => $self->_list_profiles($c) );
    $c->stash( qc_run_rs => $rs );
}

sub _validated_list_params :Private {
    my ( $self, $c ) = @_;

    my %params = (
        page         => 1,
        page_size    => 50,
    );

    if ( my $page = $c->req->param( 'page' ) ) {
        my ( $num ) = $page =~ m/(\d+)/;
        if ( $num and $num > 0 ) {
            $params{page} = $num;
        }
    }

    if ( my $page_size = $c->req->param( 'page_size' ) ) {
        my ( $num ) = $page_size =~ m/(\d+)/;
        if ( $num and $num > 0 ) {
            $params{page_size} = $num;
        }
    }

    for my $param_name ( qw( profile sequencing_project template_plate ) ) {
        my $param_val = $c->req->param( $param_name );
        if ( defined $param_val ) {
            $param_val =~ s/^\s+//;
            $param_val =~ s/\s+$//;
            $params{$param_name} = $param_val;
        }
    }

    return \%params;
}

sub view_run :Local :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    my ( $qc_run, $results ) = fetch_test_results_for_run( $c->model( 'HTGTDB' )->schema, $qc_run_id );
    unless ( $qc_run ) {
        $c->stash( error_msg => "QC run $qc_run_id not found" );
        return $c->go( 'list' );
    }

    for my $r ( @{ $results } ) {
        $r->{well_name}     = uc $r->{well_name};
        $r->{well_name_384} = uc $r->{well_name_384};
    }

    $c->stash( qc_run => $qc_run, results => $results );

    #
    #see if there are any fasta files available
    #

    my $config = HTGT::QC::Config->new;
    my $run_dir = $config->basedir->subdir( $qc_run_id );
    my $fasta_file = $run_dir->file( 'reads.fasta' );

    #the if is redundant, but it makes my intention clearer
    my $fasta_exists = ( -e $fasta_file ) ? 1 : 0;

    #if the reads.fasta doesn't exist check if this is an es cell run, as the reads
    #have different filenames for es cell runs.
    unless ( $fasta_exists ) {
        #get the sequencing projects from the db and see if any of them have reads on disk
        my $run_data = $c->model('HTGTDB')->schema->resultset( 'QCRun' )->find( { qc_run_id => $qc_run_id } );
        my $seq_projs = $self->_find_es_fasta_files( $run_dir, [ split ",", $run_data->sequencing_project ] );


        #if we got something other than undef back then there are fasta files available
        if ( $seq_projs ) {
            $c->stash( fasta_files => $seq_projs );
            $fasta_exists = 1;
        }
    }

    $c->stash( fasta_exists => $fasta_exists );

    if ( $c->req->param( 'view' ) eq 'csvdl' ) {
        my @primers = $qc_run->primers;
        my @columns = ( qw(
                              plate_name
                              well_name_384
                              well_name
                              marker_symbol
                              design_id
                              expected_design_id
                              pass
                              score
                              num_reads
                              num_valid_primers
                              valid_primers_score
                      ),
                        map( { $_.'_pass',
                               $_.'_critical_regions',
                               $_.'_target_align_length',
                               $_.'_read_length',
                               $_.'_score' } @primers ),
                        map( { $_.'_features' } @primers )
                    );

        $c->stash(
            template     => 'newqc/view_run.csvtt',
            csv_filename => substr( $qc_run_id, 0, 8 ) . '.csv',
            columns      => \@columns
        );
    }
}

#this is used to let a user download a reads.fasta file.
#es cell runs have multiple so we allow a user to specify which one (optionally).
sub get_fasta_reads :Local :Args() {
    my ( $self, $c, $qc_run_id, $sequencing_project ) = @_;

    #we do it like this as sequencing project is optional
    unless ( defined $qc_run_id ) {
        $c->stash( error_msg => "No $qc_run_id specified" );
        return;
    }

    #es cell runs have multiple fasta files, so allow selection of them individually.
    my $filename = ( defined $sequencing_project ? "$sequencing_project." : '' ) . 'reads.fasta';

    my $config = HTGT::QC::Config->new;
    my $fasta_file = $config->basedir->subdir( $qc_run_id )->file( $filename );

    #check if the file exists
    unless ( -e $fasta_file ) {
        #$c->res->redirect( $c->req->referer );
        $c->stash( error_msg => "The fasta file is no longer available." );
        return;
    }

    my $reads = $fasta_file->slurp();

    $c->res->header( 'Content-Disposition', qq(attachment; filename="$filename") );

    $c->res->content_type( 'text/x-fasta' );
    $c->res->body( $reads );
}

#should perhaps make a fetch_qc_file function to stop all this duplication
sub get_fasta_eng_seq :Local :Args(2) {
    my ( $self, $c, $qc_run_id, $enq_seq_id ) = @_;

    my $config = HTGT::QC::Config->new;
    my $filename = $enq_seq_id . ".fasta";
    my $eng_seq_file = $config->basedir->subdir( $qc_run_id )->subdir( 'eng_seqs' )->file( $filename );

    unless ( -e $eng_seq_file ) {
        $c->stash( error_msg => "The eng seq file '$eng_seq_file' is no longer available." );
        $c->stash( template => 'newqc/get_fasta_reads' );
        return;
    }

    my $reads = $eng_seq_file->slurp();

    $c->res->header( 'Content-Disposition', qq(attachment; filename="$filename") );

    $c->res->content_type( 'text/x-fasta' );
    $c->res->body( $reads );
}

#es cells have multiple reads.fasta files which can get pretty annoying,
#so this will return any ones that are present given the sequencing projects.
sub _find_es_fasta_files :Private {
    my ( $self, $run_dir, $sequencing_projects ) = @_;

    #attempt to identify if this is an es cell run with files in the format SEQ_PROJ.reads.fasta
    #and return the sequencing projects that have reads (not the filenames)
    my @reads = grep { -e $run_dir->file( "$_.reads.fasta" ) } @{ $sequencing_projects };

    return \@reads if @reads; #we return undef if we didn't find any, NOT an empty arrayref.
}

#this is a gigantic function that extracts various pieces of information
#from a qc run directory. its pretty slow. just scroll on past it.
#i have left everything in one function as there's so much of it and its all very
#specific; it just checks if various files exists then reads them.
#this way we dont clutter up this file.
sub view_run_files :Local :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    my $config = HTGT::QC::Config->new;
    if ( $c->request->param( 'prescreen' ) || $c->req->param( 'view' ) eq 'csvdl' ) {
        $config->is_prescreen(1); #either of these parameters means its a prescreen.
    }
    
    my $run_dir = $config->basedir->subdir( $qc_run_id );

    $c->stash( qc_run_id => $qc_run_id );

    #make sure this run has a folder (in case it has been deleted)
    unless ( -e $run_dir ) {
        $c->stash( error_msg => "$run_dir does not exist, please check the run id is correct." );
        return;
    }

    #
    #check if this was a pre-screen run
    #

    #if this is a pre screen run we will display a different page.
    if ( $config->is_prescreen ) {
        $c->stash( { template => 'newqc/es_cell_prescreen', qc_run_id => $qc_run_id } );

        my @prescreen_files = $run_dir->subdir( 'prescreen' )->children();

        #store all the yaml data from each project
        my %projects;
        for my $file ( @prescreen_files ) {
            #hash key is the sequencing project. we strip .prescreen.yaml
            $projects{ substr $file->basename, 0, -15 } = YAML::Any::LoadFile( $file );
        }

        #allow the user to download a csv file. i should have used the csv module. woops
        if( $c->req->param( 'view' ) eq 'csvdl' ) {
            #make header
            my @columns = qw(
                Plate_Name
                Well_Name
                Primer
                Score
                Match_Length
                Chromosome
                Gene
                Chromosome_Start
                Chromosome_End
                Query_Start
                Query_End
                Sequence
            );

            my @results;

            #add all the data, with the projects in alphabetical order.
            #each doesnt allow sorting so we have to use keys.
            #'project' refers to a sequencing project here.
            for my $project_name ( sort keys %projects ) {
                my $project = $projects{ $project_name };
                for my $design_id ( sort keys %{ $project } ) {
                    my $cigar = $project->{ $design_id }; # this is HEPD0855_2_A_1a03.p1kLR
                    #columns should be identical to the non csv view (except for blast)
                    push @results, [ 
                        $cigar->{ plate },
                        $cigar->{ well },
                        $cigar->{ query_primer },
                        $cigar->{ score },
                        $cigar->{ length },
                        $cigar->{ chromosome },
                        join( "; ", @{ $cigar->{ genes } } ),
                        $cigar->{ target_start },
                        $cigar->{ target_end },
                        $cigar->{ query_start },
                        $cigar->{ query_end },
                        $cigar->{ sequence },
                    ];
                }

            }

            #change to the csv template and store all our data.
            $c->stash(
                template     => 'newqc/view_run.csvtt',
                csv_filename => substr( $qc_run_id, 0, 8 ) . '.csv',
                columns      => \@columns,
                results      => \@results,
            );

            return;
        }
        
        #if they didnt request a csv then just give them the regular webpage
        $c->stash( projects => \%projects );

        return;
    }

    #
    #load params.yaml to get initial information about the run
    #if we dont have it then exit as there's not much we can provide.
    #
    my $run;
    try {
        $run = YAML::Any::LoadFile( $run_dir->file( 'params.yaml' ) );
    }
    catch {
        #our version doesnt have basename for dirs so we cant use it.
        my $listing = join "<br/>", $run_dir->children();
        $c->stash( error_msg => "Couldn't find params.yaml file. Directory listing:<br/>$listing" );
    };

    return unless $run; 

    my $sequencing_projects = $run->{ sequencing_projects };
    $c->stash( {
        sequencing_projects => $sequencing_projects,
        template_plate      => $run->{ template_plate },
    } );

    #
    #attempt to find fasta files (if any)
    #
    my $fasta_exists = ( -e $run_dir->file( 'reads.fasta' ) ) ? 1 : 0;

    unless ( $fasta_exists ) {
        #see if any of the sequencing projects have reads on disk
        my $fasta_files = $self->_find_es_fasta_files( $run_dir, $sequencing_projects );

        #if we got something other than undef back then there are fasta files available
        if ( $fasta_files ) {
            $c->stash( fasta_files => $fasta_files );
            $fasta_exists = 1;
        }
    }

    $c->stash( fasta_exists => $fasta_exists );

    #
    #get the marker symbol and design name from the database,
    #based on the information in the template.yaml file
    #we also provide a list of associated eng seqs so we can create download urls.
    #
    my $template_file = $run_dir->file( 'template.yaml' );

    if ( -e $template_file ) {
        my $template_data = YAML::Any::LoadFile( $template_file );

        my $well_params = $template_data->{ wells };

        my ( %gene_names, %eng_seq_files );
        for my $p ( values %{ $well_params } ) {
            my ( $design_id ) = split "#", $p->{ eng_seq_id }; #only take first element from split
            my $design = $c->model( 'HTGTDB' )->resultset( 'Design' )->find(
                { design_id => $design_id },
                {
                    join => { 'projects' => 'mgi_gene' },
                    distinct => 1, #sometimes there's more than one project with the same gene
                }
            );

            my $name = $design->design_name || $design_id; #use design id as a backup name

            #add all the design names to our hash. duplicates will have the same so we can ignore them
            $gene_names{ $design->projects->first->mgi_gene->marker_symbol } = $name;

            #the id has hashes in it so we need to uri encode it.
            $eng_seq_files{ $name } = $p->{ eng_seq_id };
        }

        $c->stash( { genes => \%gene_names, eng_seq_files => \%eng_seq_files } );
    }

    #
    #we process alignments separately with an ajax call to get_alignment_data
    #as it adds 7~ seconds to the (already slow) load time
    #

    #
    #finally get profile information
    #
    my $profile = $config->profile( $run->{ profile } );
    $c->stash( {
        profile_name            => $profile->profile_name,
        primers                 => join( ", ", $profile->primers ),
        pass_condition          => $profile->pass_condition,
        vector_stage            => $profile->vector_stage,
        pre_filter_min_score    => $profile->pre_filter_min_score,
        post_filter_min_primers => $profile->post_filter_min_primers
    } );
}

#this fetches pertinent data from the alignment.yaml file(s).
#it returns json as is intended to be called by ajax
sub get_alignment_data :Local {
    my ( $self, $c ) = @_;

    my $qc_run_id = $c->request->param( 'qc_run_id' );

    my $json;
    if ( defined $qc_run_id ) {
        my $config = HTGT::QC::Config->new;
        my $run_dir = $config->basedir->subdir( $qc_run_id );

        #this was duplicated so i put it in a sub.
        #it just builds the hash that we want to convert to json
        my $get_alignments_hash = sub {
            my $aligns = shift;

            my %seqs;
            for my $row ( @{ $aligns } ) {
                my $primer_str = $row->{ query_primer } . " (" . $row->{ score } . ")";
                push @{ $seqs{ $row->{ target_id } }{ $row->{ query_well } } }, $primer_str;
            }

            return \%seqs;
        };

        #parse the alignments file into a hash and convert to a string of json
        my $alignments_file = $run_dir->file( 'alignments.yaml' );
        if ( -e $alignments_file ) {
            my $aligns = YAML::Any::LoadFile( $alignments_file );

            $json = encode_json( $get_alignments_hash->( $aligns ) );
        }
        elsif ( -e $run_dir ) { #make sure the run_dir exists just in case
            #we're assuming its an es cell run, so we'll see if there's any alignment files
            my @files = grep { $_ =~ /.*alignments.yaml$/ } $run_dir->children();

            #if we found any alignment files, process them all into our hash
            if ( @files ) {
                #merge all the yaml arrayrefs into a single ref
                my $aligns;
                push @{ $aligns }, @{ YAML::Any::LoadFile( $_ ) } for ( @files );

                #now make that into a nice json string
                $json = encode_json( $get_alignments_hash->( $aligns ) );
            }
        }
    }

    $c->res->content_type( 'application/json' );
    $c->res->body( $json );
}

sub view_file_alignment :Local :Args(4) {
    my ( $self, $c, $qc_run_id, $plate_well, $eng_seq, $desired_primer ) = @_;

    my $config = HTGT::QC::Config->new;
    my $run_dir = $config->basedir->subdir( $qc_run_id );

    #
    #To help with regexes:
    # An es cell $plate_well looks like this: HEPD0858_1_B_1A03
    # regular ones are like:                  HTGR04037_Z_1D07
    #

    #attempt to identify if this is an es cell run by checking for
    #a reads.fasta file with an es cell filename.
    my ( $plate, $well ) = $plate_well =~ /^(.*?_\d_[A-Za-z])_\d(\w{3})$/;
    my $is_es_cell_run = -e $run_dir->file( "$plate.reads.fasta" );

    #es cell has multiple analysis dirs so get the corresponding one
    my $analysis_dir = ( ( $is_es_cell_run ) ? "$plate." : "" ) . "analysis";

    #if its an es cell run post-filter and analysis have differently named sub folder.
    #we need to remove the trailing character for post-filter because they all get grouped.
    #analysis sub folders have the full $plate_well we get provided.
    my ( $post_filter_name ) = ( $is_es_cell_run ) ? ($plate =~ /(.*?_\d)_[A-Za-z]/)[0].$well : $plate_well;

    #append .yaml so we can use this var as the filename
    $eng_seq .= ".yaml";

    my $post_filter_folder = $run_dir->subdir( 'post-filter' )->subdir( $post_filter_name );
    my $analysis_folder = $run_dir->subdir( $analysis_dir )->subdir( $plate_well );

    my @warnings;
    push @warnings, "Warning: Post-filter folder doesn't exist." unless -e $post_filter_folder;
    push @warnings, "Warning: Analysis folder doesn't exist." unless -e $analysis_folder;

    #attempt to find the file that has been requested.
    #first check the post filter folder, if its not there we'll resort to the analysis
    #directory (and give a warning to notify the user.).
    my $file;
    if ( -e $post_filter_folder and -e $post_filter_folder->file( $eng_seq ) ) {
        $file = $post_filter_folder->file( $eng_seq );

        if ( $is_es_cell_run ) {
            #get the middle letter as thats how es cell primers are named e.g. B_R2R
            #this is ONLY for post_filter, analysis has the original name.
            $desired_primer = ($plate =~ /.*?_\d_([A-Za-z])$/)[0] . "_$desired_primer";

        }
    }
    elsif ( -e $analysis_folder and -e $analysis_folder->file( $eng_seq )  ) {
        #want to notify on page that it didnt pass post-filter
        push @warnings, "Warning: '$plate_well' didn't pass post filter.";
        $file = $analysis_folder->file( $eng_seq );
    }
    else { #the file doesn't exist.
        $c->stash( error_msg => "Couldn't find '$plate_well/$eng_seq' in post-filter or analysis." );
        return;
    }

    #file definitely exists so lets process the alignment info (if any) for this primer
    my $content = YAML::Any::LoadFile( $file );

    if ( exists $content->{ primers }{ $desired_primer } ) {
        for my $name ( keys %{ $content->{ primers }{ $desired_primer }{ alignment } } ) {
            my $row = $content->{ primers }{ $desired_primer }{ alignment }{ $name };

            #we store the text inside the hash or we'd have to make a new one and copy
            #everything over.
            $row->{ alignment_str } = HTGT::QC::Util::Alignment::format_alignment( %{ $row } );
        }

        $c->stash( alignments => $content->{ primers }{ $desired_primer }{ alignment } );
        $c->stash( features => $content->{ primers }{ $desired_primer }{ features } );
    }
    else { #this means the file exists but the requested primer isn't in it.
        push @warnings, "Warning: Couldn't find primer '$desired_primer' in file.";
    }

    $c->stash( { status_msg => join "</br>", @warnings } );
}

sub view_run_summary :Local :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    my ( $qc_run, $results ) = fetch_test_results_for_run( $c->model( 'HTGTDB' )->schema, $qc_run_id );
    unless ( $qc_run ) {
        $c->stash( error_msg => "QC run $qc_run_id not found" );
        return $c->go( 'list' );
    }

    my $template_well_rs = $c->model( 'HTGTDB' )->resultset( 'Well' )->search(
        {
            'me.plate_id' => $qc_run->template_plate_id,
        },
        {
            prefetch => [ 'plate', { 'design_instance' => { 'projects' => 'mgi_gene' } } ]
        }
    );

    my @summary;

    my %seen_design;

    while ( my $template_well = $template_well_rs->next ) {
        next unless $template_well->design_instance_id
            and not $seen_design{ $template_well->design_instance->design_id }++;
        my $project = $template_well->design_instance->projects_rs->first;
        my %s = (
            design_id         => $project->design_id,
            design_plate_name => $project->design_plate_name,
            design_well_name  => $project->design_well_name,
            marker_symbol     => $project->mgi_gene->marker_symbol,
        );
        my @results = reverse sort {
            ( $a->{pass} || 0 ) <=> ( $b->{pass} || 0 )
                || ( $a->{num_valid_primers} || 0 ) <=> ( $b->{num_valid_primers} || 0 )
                    || ( $a->{valid_primers_score} || 0 ) <=> ( $b->{valid_primers_score} || 0 )
                        || ( $a->{score} || 0 ) <=> ( $b->{score} || 0 )
                            || ( $a->{num_reads} || 0 ) <=> ( $b->{num_reads} || 0 )
                        }
            grep { $_->{design_id} and $_->{design_id} == $project->design_id }
                @{ $results };

        if ( my $best = shift @results ) {
            $s{plate_name}    = $best->{plate_name};
            $s{well_name}     = uc $best->{well_name};
            $s{well_name_384} = uc $best->{well_name_384};
            $s{valid_primers} = join( q{,}, @{ $best->{valid_primers} } );
            $s{pass}          = $best->{pass};
        }
        push @summary, \%s;
    }

    $c->stash(
        template     => 'newqc/view_run_summary',
        columns      => [ qw( design_id marker_symbol plate_name well_name_384 well_name pass valid_primers ) ],
        results      => \@summary,
        qc_run       => $qc_run
    );

    if ( $c->req->param( 'view' ) eq 'csvdl' ) {
        $c->stash( csv_filename => substr( $qc_run_id, 0, 8 ) . '_summary.csv' );
    }
}

sub view_result :Local :Args(3) {
    my ( $self, $c, $qc_run_id, $plate_name, $well_name ) = @_;

    my $qc_run = $c->model( 'HTGTDB::QCRun' )->find( { qc_run_id => $qc_run_id } );
    unless ( $qc_run ) {
        $c->stash( error_msg => "QC run $qc_run_id not found" );
        return $c->go( 'list' );
    }

    my @seq_reads = $qc_run->get_seq_reads( $plate_name, $well_name );

    my @qc_results = $qc_run->get_test_results_for_well( $plate_name, $well_name );

    #if we didnt get any seq reads attempt to get them from the qc_results
    unless ( @seq_reads ) {
        # get to seq reads by going from qc test result -> alignment -> seq read
        for my $qc_result ( @qc_results ) {
            my @alignments = $qc_result->alignments;
            push @seq_reads, map { $_->seq_read } @alignments;
        }

        #if we STILL dont have any seq_reads then display an error as something has gone horribly wrong
        unless ( @seq_reads ) {
            $c->stash( error_msg => "No sequence reads for well ${plate_name}_${well_name}" );
            return $c->go( 'view_run', [], [ $qc_run_id ] );
        }
    }

    $c->stash(
        qc_run     => $qc_run,
        plate_name => $plate_name,
        well_name  => $well_name,
        results    => \@qc_results,
        seq_reads  => [ sort { $a->primer_name cmp $b->primer_name } @seq_reads ]
    );
}

sub synvec :Local :Args(1) {
    my ( $self, $c, $qc_synvec_id ) = @_;

    my $synvec = $c->model( 'HTGTDB::QCSynvec' )->find( { qc_synvec_id => $qc_synvec_id } );

    unless ( $synvec ) {
        $c->stash( error_msg => "Failed to retrieve synthetic vector" );
        return $c->go( 'list' );
    }

    my $bio_seq = $synvec->bio_seq;

    my $params = $self->_validated_download_seq_params( $c );

    my $filename = $bio_seq->display_id . $params->{suffix};

    my $formatted_seq;
    Bio::SeqIO->new( -fh => IO::String->new( $formatted_seq ), -format => $params->{format} )->write_seq( $bio_seq );

    $c->response->content_type( 'application/octet-stream' ); # XXX Is this an appropriate content type?
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
}

sub seq_reads :Local :Args(3) {
    my ( $self, $c, $qc_run_id, $plate_name, $well_name) = @_;

    my $qc_run = $c->model( 'HTGTDB::QCRun' )->find( { qc_run_id => $qc_run_id } );
    unless ( $qc_run ) {
        $c->stash( error_msg => "QC run $qc_run_id not found" );
        return $c->go( 'list' );
    }

    my @seq_reads = $qc_run->seq_reads_rs->search(
        {
            'me.qc_seq_read_id' => { like => $plate_name . $well_name . '%' }
        }
    );

    if(!@seq_reads){
        #Grab all the reads for the entire plate and grep out the reads with a match to the input well
        @seq_reads = $qc_run->seq_reads_rs->search(
            {
                'me.qc_seq_read_id' => { like => $plate_name . '%' }
            }
        );
        @seq_reads = grep {$_->qc_seq_read_id =~ /$well_name/i} @seq_reads;
    }

    if(!@seq_reads){
        # get to seq reads by going from qc test result -> alignment -> seq read
        my @qc_results = $qc_run->search_related(
            test_results => {
                plate_name => $plate_name,
                well_name  => $well_name
            }
        );
        for my $qc_result ( @qc_results ) {
            my @alignments = $qc_result->alignments;
            push @seq_reads, map{ $_->seq_read } @alignments;
        }
    }

    unless ( @seq_reads ) {
        $c->stash( error_msg => "No sequence reads for well ${plate_name}_${well_name}" );
        return $c->go( 'view_run', [], [ $qc_run_id ] );
    }

    my $params = $self->_validated_download_seq_params( $c );

    my $filename = 'seq_reads_' . $plate_name . $well_name . $params->{suffix};

    my $formatted_seq;
    my $seq_io = Bio::SeqIO->new( -fh => IO::String->new( $formatted_seq ), -format => $params->{format} );

    for my $seq_read ( @seq_reads ) {
        $seq_io->write_seq( $seq_read->bio_seq );
    }

    $c->response->content_type( 'application/octet-stream' ); # XXX Is this an appropriate content type?
    $c->response->header( 'Content-Disposition' => "attachment; filename=$filename" );
    $c->response->body( $formatted_seq );
}

sub _validated_download_seq_params {
    my ( $self, $c ) = @_;

    my %params = (
        format => 'genbank',
    );

    const my %SUFFIX_FOR => ( genbank => '.gbk', fasta => '.fasta' );

    if ( my $format = $c->req->param( 'format' ) ) {
        $format =~ s/^\s+//;
        $format =~ s/\s+$//;
        $format = lc( $format );
        if ( $SUFFIX_FOR{$format} ) {
            $params{format} = $format;
        }
    }

    $params{suffix} = $SUFFIX_FOR{ $params{format} };

    return \%params;
}

sub view_alignment :Local :Args(2) {
    my ( $self, $c, $qc_test_result_id, $qc_seq_read_id ) = @_;

    my $test_result = $c->model( 'HTGTDB::QCTestResult' )->find(
        {
            qc_test_result_id => $qc_test_result_id
        },
        {
            prefetch => [ 'synvec' ]
        }
    );

    unless ( $test_result ) {
        $c->stash( error_msg => 'Failed to retrieve test result' );
        return $c->go( 'list' );
    }


    my $alignment = $c->model( 'HTGTDB::QCTestResultAlignment' )->search_rs(
        {
            'test_result_alignment_maps.qc_test_result_id' => $qc_test_result_id,
            'me.qc_seq_read_id'                            => $qc_seq_read_id
        },
        {
            join     => [ 'test_result_alignment_maps' ],
            prefetch => 'seq_read'
        }
    )->first;

    unless ( $alignment ) {
        $c->stash( error_msg => "Failed to retrieve alignment" );
        return $c->go( 'list' );
    }

    my $target = $test_result->synvec->bio_seq;
    my $query  = $alignment->seq_read->bio_seq;
    my $cigar  = HTGT::QC::Util::CigarParser->new(strict_mode => 0)->parse_cigar( $alignment->cigar );

    my $match = alignment_match( $query, $target, $cigar, $cigar->{target_start}, $cigar->{target_end} );

    my $target_strand = $alignment->target_strand == 1 ? '+' : '-';

    my $alignment_str = HTGT::QC::Util::Alignment::format_alignment(
        %{$match},
        target_id  => "Target ($target_strand)",
        query_id   => 'Sequence Read',
        line_len   => 72,
        header_len => 12
    );

    $c->stash( target => $target->display_id, query => $query->display_id, alignment_str => $alignment_str, alignment => $alignment, test_result => $test_result );
}

sub update_plates :Local :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    my $qc_run = $c->model( 'HTGTDB::QCRun' )->find( { qc_run_id => $qc_run_id } );
    unless ( $qc_run ){
        $c->stash( error_msg => "Failed to retrieve QC run $qc_run_id" );
        $c->go( 'list' );
    }

    $c->stash( qc_run => $qc_run );

    return unless $c->request->method eq 'POST';

    my $plate_map = $self->_validated_update_plates_params( $c, $qc_run );

    return unless $plate_map;

    while (my ( $orig_plate_name, $plate_name ) = each %{$plate_map} ){
        my $update_id = $orig_plate_name . ':' . $plate_name . ':' . $qc_run_id . ':' . $c->user->id;

        $self->_submit_es_cell_qc_update( $c, $orig_plate_name, $plate_name, $qc_run_id );
    }

    $c->stash( status_msg => 'Updating ' . PL_N('plate', scalar values %{$plate_map}) . ': ' . join( q{,}, sort values %{$plate_map} ) );
    $c->go('list');
}

sub create_plates :Local :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    my $qc_run = $c->model( 'HTGTDB::QCRun' )->find( { qc_run_id => $qc_run_id } );
    unless ( $qc_run ) {
        $c->stash( error_msg => "Failed to retrieve QC run $qc_run_id" );
        $c->go( 'list' );
    }

    $c->stash( qc_run => $qc_run, plate_types => [ sort keys %PLATE_TYPES ] );

    return unless $c->request->method eq 'POST';

    my $params = $self->_validated_create_plates_params( $c, $qc_run );

    return unless $params;

    my $created;
    try {
        $created = $c->model( 'HTGTDB' )->schema->txn_do(
            sub {
                $self->_do_create_plates( $c, $qc_run, $params->{plate_map}, $PLATE_TYPES{ $params->{plate_type} } );
            }
        );
    }
    catch {
        $c->log->error( $_ );
        $c->stash( error_msg => $_ );
    };

    if ( $created ) {
        my @plate_links = map { sprintf '<a href="%s">%s</a>', $c->uri_for( '/plate/view', { plate_name => $_->name } ), $_->name }
            sort { $a->name cmp $b->name } @{$created};
        $c->stash( status_msg => 'Created ' . PL_N('plate', scalar @plate_links) . ': ' . join( q{, }, @plate_links ) );
        $c->go( 'list' );
    }
}

sub _do_create_plates {
    my ( $self, $c, $qc_run, $plate_map, $plate_type ) = @_;

    my %template_wells = map { uc( substr( $_->well_name, -3 ) ) => $_ }
        grep { defined $_->design_instance_id } $qc_run->template_plate->wells;

    my $results = fetch_test_results_for_run( $c->model( 'HTGTDB' )->schema, $qc_run->qc_run_id );

    my @created;

    while ( my ( $orig_plate_name, $plate_name ) = each %{$plate_map} ) {
        my %results_by_well;
        for my $r ( @{ $results } ) {
            next unless $r->{plate_name} eq $orig_plate_name;
            push @{ $results_by_well{ uc( substr( $r->{well_name}, -3 ) ) } }, $r;
        }
        push @created, $self->_do_create_plate( $c, $qc_run, $orig_plate_name, $plate_name, $plate_type, \%results_by_well, \%template_wells );
    }

    return \@created;
}

sub _do_create_plate {
    my ( $self, $c, $qc_run, $orig_plate_name, $plate_name, $plate_type, $results_by_well, $template_wells ) = @_;

    $c->log->debug( "Creating plate $plate_name" );

    my $plate = $c->model( 'HTGTDB::Plate' )->create(
        {
            name         => $plate_name,
            created_user => $c->user->id,
            created_date => \'current_timestamp',
            edited_user  => $c->user->id,
            edited_date  => \'current_timestamp',
            type         => $plate_type
        }
    );

    my %seen_parent_plate;

    for my $well_name ( keys %{ $results_by_well } ) {
        my $qc_test_run_id_for_well = join( '/', $qc_run->qc_run_id, $orig_plate_name, $well_name );
        my $well = $self->_create_well_on_plate( $c, $plate, $well_name, $results_by_well->{$well_name}, $template_wells, $qc_test_run_id_for_well );
        my $parent_well = $well->parent_well;
        if ( $parent_well and not $seen_parent_plate{ $parent_well->plate_id }++ ) {
            $plate->create_related(
                parent_plate_plates => {
                    parent_plate_id => $parent_well->plate_id
                }
            );
        }
    }

    return $plate;
}

sub _create_well_on_plate {
    my ( $self, $c, $plate, $well_name, $results, $template_wells, $qc_test_result_id ) = @_;

    my $plate_name = $plate->name;

    my $best_result = $results->[0];
    my $design_id = $best_result->{design_id};

    if ( ! defined $design_id ) {
        $c->log->debug( "Creating empty well $plate_name\[$well_name\]" );
        my $well = $plate->create_related(
            wells => {
                well_name          => uc($well_name),
                design_instance_id => undef,
                parent_well_id     => undef,
                edit_date          => \'current_timestamp',
                edit_user          => $c->user->id
            }
        );
        return $well;
    }

    # First try for a template well in the same location on the template plate
    my $template_well = $template_wells->{$well_name};
    unless ( $template_well and $template_well->design_instance and $template_well->design_instance->design_id == $design_id ) {
        # Fallback to considering any well on the template plate
        $template_well = firstval { $_->design_instance->design_id == $design_id } values %{ $template_wells }
            or die "Failed to retrieve template well for design $design_id\n";
    }

    my $parent_well = $template_well->parent_well;
    while ( $parent_well->plate->type eq 'VTP' ) {
        $parent_well = $parent_well->parent_well;
    }

    die "$template_well has no non-template parent_well\n"
        unless defined $parent_well;

    $c->log->debug( "Creating well $plate_name\[$well_name\]" );
    my $well = $plate->create_related(
        wells => {
            well_name          => uc($well_name),
            design_instance_id => $template_well->design_instance_id,
            parent_well_id     => $parent_well->well_id,
            edit_date          => \'current_timestamp',
            edit_user          => $c->user->id
        }
    );
    $well->create_related(
        well_data => {
            data_type  => 'pass_level',
            data_value => ( $best_result->{pass} ? 'pass' : 'fail' ),
            edit_date  => \'current_timestamp',
            edit_user  => $c->user->id
        }
    );
    $well->create_related(
        well_data => {
            data_type  => 'new_qc_test_result_id',
            data_value => $qc_test_result_id,
            edit_date  => \'current_timestamp',
            edit_user  => $c->user->id
        }
    );
    if ( $best_result->{num_valid_primers} > 0 ) {
        $well->create_related(
            well_data => {
                data_type => 'valid_primers',
                data_value => join( q{,}, @{ $best_result->{valid_primers} } ),
                edit_date  => \'current_timestamp',
                edit_user  => $c->user->id
            }
        );
    }
    if ( @{ $results } > 1 ) {
        $well->create_related(
            well_data => {
                data_type  => 'mixed_reads',
                data_value => 'yes',
                edit_date  => \'current_timestamp',
                edit_user  => $c->user->id
            }
        );
    }

    # Populate well_data inherited from the template well
    my %template_well_data = map { $_->data_type => $_->data_value } $template_well->well_data;
    for my $data_type ( qw( cassette backbone ) ) {
        if ( defined $template_well_data{$data_type} ) {
            $well->create_related(
                well_data => {
                    data_type  => $data_type,
                    data_value => $template_well_data{$data_type},
                    edit_date  => \'current_timestamp',
                    edit_user  => $c->user->id
                }
            );
        }
    }

    return $well;
}

sub _validated_create_plates_params {
    my ( $self, $c, $qc_run ) = @_;

    my %plate_map = map { $_ => $_ } $qc_run->plates;

    my @errors;

    # Check that plate type is valid
    my $plate_type = $c->request->param( 'plate_type' ) || '';
    $plate_type =~ s/^\s+//;
    $plate_type =~ s/\s+$//;
    unless ( exists $PLATE_TYPES{$plate_type} ) {
        push @errors, "Plate type '$plate_type' is not a valid plate type";
    }

    # Extract any plate renames from the request parameters

    my $params = $c->request->parameters;
    for my $p ( keys %{$params} ) {
        my ( $plate_name ) = $p =~ /^rename_plate_(.+)$/;
        if ( $plate_name ) {
            if ( $plate_map{$plate_name} ) {
                ( my $rename_to = $params->{$p} ) =~ s/\s+//;
                $plate_map{$plate_name} = uc( $rename_to );
            }
            else {
                push @errors, "Plate $plate_name is not part of this QC run";
            }
        }
    }

    my @to_create = values %plate_map;

    # Check that there are no duplicates in the list of plates we're asked to create
    if ( @to_create != uniq @to_create ) {
        push @errors, "The names of the plates to be created must be distinct";
    }

    # Check that none of the plates we're asked to make already exist
    my @existing_plates = $c->model( 'HTGTDB::Plate' )->search(
        {
            name => \@to_create
        },
        {
            columns => [ 'name' ],
            distinct => 1
        }
    );

    if ( ( my $count = @existing_plates ) > 0 ) {
        push @errors, PL_N( "Plate", $count ) . ' ' . join( q{, }, @existing_plates ) . ' already ' . PL_V( "exists", $count );
    }

    if ( @errors ) {
        $c->stash( error_msg => join( '<br />', @errors ) );
        return;
    }

    return +{
        plate_type => $plate_type,
        plate_map  => \%plate_map
    };
}

sub _validated_update_plates_params {
    my ( $self, $c, $qc_run ) = @_;

    my %plate_map = map{ $_ => $_ } $qc_run->plates;

    my @errors;

    #Extract any plate renames from the request parameters

    my $params = $c->request->parameters;
    for my $p ( keys %{$params} ){
        my ( $plate_name ) = $p =~ /^rename_plate_(.+)$/;
        if ( $plate_name ){
            if ( $plate_map{$plate_name} ){
                ( my $rename_to = $params->{$p} ) =~ s/\s+//;
                $plate_map{$plate_name} = uc( $rename_to );
            }
            else{
                push @errors, "Plate $plate_name is not part of this QC run";
            }
        }
    }

    my @to_update = values %plate_map;

    if ( @to_update != uniq @to_update ){
        push @errors, "The names of the plates to be updated must be distinct";
    }

    my @existing_plates = $c->model( 'HTGTDB::Plate' )->search(
        {
            name => \@to_update
        },
        {
            columns   => [ 'name' ],
            distrinct => 1
        }
    );

    if( ( my $missing = @existing_plates - @to_update ) > 0 ) {
        push @errors, "$missing of the plates do not exist";
    }

    if ( @errors ){
        $c->stash( error_msg => join( '<br />', @errors ) );
        return;
    }

    return \%plate_map;
}

sub suggest_sequencing_projects :Local {
    my ($self, $c) = @_;

    my $search_string = $c->request->param( 'sequencing_project' );

    my $projects = [];
    if ( defined $search_string and length $search_string > 5 ) {
        $projects = $c->model('BadgerRepository')->search( $search_string );
    }
    my $html_set = '<ul>' . join( '', map "<li>$_</li>", @{ $projects } ) . '</ul>';

    $c->res->body($html_set);
}

sub suggest_template_plates :Local {
    my ( $self, $c ) = @_;

    my $search_string = $c->request->param( 'template_plate' );

    my $html_set = $self->_suggest_plates( $c, $search_string, 'VTP' );

    $c->res->body( $html_set );
}

sub suggest_epd_plates :Local {
    my ( $self, $c ) = @_;

    my $search_string = $c->request->param( 'epd_plate_name' );

    my $html_set = $self->_suggest_plates( $c, $search_string, 'EPD' );

    $c->res->body( $html_set );
}

sub _suggest_plates {
    my ( $self, $c, $search_string, $type ) = @_;

    my @plates;
    if ( defined $search_string and length $search_string > 4 and defined $type ) {
        @plates = $c->model( 'HTGTDB::Plate' )->search( 
            { type => $type, name => { like => $search_string . '%' } } 
        );
    }

    #epd plates need trailing numbers removed as the plate to suggest doesn't actually exist in the db
    if ( $type eq 'EPD' ) {
        #they should look something like EPD0975_1
        @plates = uniq( map { $_ =~ /(.*)_\d+$/ } @plates );
    }

    return '<ul>' . join( '', map { "<li>$_</li>" } @plates ) . '</ul>';
}

sub latest_runs :Local :Args(0) {
    my ( $self, $c ) = @_;

    my $config = HTGT::QC::Config->new;

    #if they do latest_runs?prescreen=1 then only shows prescreen runs.
    if ( $c->request->param( 'prescreen' ) ) {
        $config->is_prescreen(1);
        $c->stash( prescreen => 1 );
    }

    my $llr = HTGT::QC::Util::ListLatestRuns->new( { config => $config } );

    $c->stash( latest => $llr->get_latest_run_data );
    $c->stash( template => 'newqc/latest_runs.tt' );
}

sub kill_farm_jobs :Local :Args(1) {
    my ( $self, $c, $qc_run_id ) = @_;

    my $config = HTGT::QC::Config->new;

    if ( $c->request->param('prescreen') ) {
        $config->is_prescreen(1);
    }

    my $kill_jobs = HTGT::QC::Util::KillQCFarmJobs->new(
        {
            qc_run_id => $qc_run_id,
            config    => $config,
        } );
    my $jobs_killed = $kill_jobs->kill_unfinished_farm_jobs();
    $c->stash( status_msg => 'Killing farm jobs (' . join( ' ', @{$jobs_killed} ) . ')' );
    $c->go( 'latest_runs' );
}

sub qc_farm_error_rpt :Local :Args(1) {
    my ( $self, $c, $params ) = @_;

    my ( $qc_run_id, $last_stage ) = $params =~ /^(.+)___(.+)$/;
    my $config = HTGT::QC::Config->new;

    if ( $c->request->param('prescreen') ) {
        $config->is_prescreen(1);
    }

    my $error_file = $config->basedir->file( $qc_run_id, 'error', $last_stage . '.err' );
    my @error_file_content = $error_file->slurp( chomp => 1 );

    $c->stash( run_id => $qc_run_id );
    $c->stash( last_stage => $last_stage );
    $c->stash( error_content => \@error_file_content );
    $c->stash( template => 'newqc/qc_farm_error_rpt' );
}

sub failed_runs :Local :Args(0) {
    my ( $self, $c ) = @_;

    my $lfr = HTGT::QC::Util::ListFailedRuns->new( { config => HTGT::QC::Config->new } );

    $c->stash( failed => $lfr->get_failed_run_data );
    $c->stash( template => 'newqc/failed_runs.tt' );
}

sub submit_es_cell :Local :Args(0) {
    my ( $self, $c ) = @_;

    #note: run type gets determined in _validated_es_cell_params

    #we should perhaps only list valid es cell profiles.
    $c->stash( profiles => $self->_list_all_profiles );

    #this page displays different things depending on the post parameters
    #if the method isn't post then they havent submitted a form yet.
    if( $c->request->method eq 'POST' ) {
        my $params = $self->_validated_es_cell_params( $c )
            or return;

        if ( $c->req->param( 'submit_initial_info' ) ) {
            #stuff to get sequences etc.
            $c->stash( sequencing_projects => $params->{ sequencing_projects } );
            $c->stash( template_plate      => $params->{ template_plate } );

            #we dont want to display the form or get active runs on this page
            return;
        }
        elsif ( $c->req->param( 'submit_job' ) ) {
            unless ( $c->req->param( 'sequencing_projects' ) ) {
                #do we need to re-stash the sequencing projects?
                $c->stash( error_msg => "No sequencing projects selected." );
                return;
            }
                
            $self->_submit_qc_job( $c, $params );

            #we don't return as we want to display the submit page to the user
        }
    }

    #if we reach here we're not on the submit_initial_info page,
    #so get all the active runs.

    my $llr = HTGT::QC::Util::ListLatestRuns->new( { config => HTGT::QC::Config->new } );

    #we are only interested in es cell runs so filter the others out
    $c->stash( active_es_runs => [ grep { $_->{is_escell} } @{ $llr->get_active_runs() } ] );
}

sub submit :Local :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( profiles => $self->_list_all_profiles );

    return unless $c->request->method eq 'POST';

    my $params = $self->_validated_submit_params( $c )
        or return;

    if ( $c->req->param( 'submit_initial_info' ) ) {
        try {
            my $plate_map = create_suggested_plate_map(
                $params->{ sequencing_projects },
                $c->model( 'HTGTDB' )->schema,
                "Plate",
            );
            $c->stash( plate_map         => $plate_map );
            $c->stash( plate_map_request => 1 );
        }
        catch {
            $c->stash( error_msg => 'Error creating plate map:' . $_ );
            return;
        };
    }
    elsif ( $c->req->param('submit_plate_map_info') ) {
        my $plate_map = $self->_build_plate_map( $c );
        my $validated_plate_map = $self->_validate_plate_map( $c, $plate_map, $params->{sequencing_projects} );
        unless ( $validated_plate_map ) {
            $c->stash( plate_map => $plate_map );
            $c->stash( plate_map_request => 1 );
            return;
        }

        $params->{plate_map} = $validated_plate_map;
        $self->_submit_qc_job( $c, $params );
    }
}

sub _submit_es_cell_qc_update {
    my ( $self, $c, $orig_plate_name, $plate_name, $qc_run_id ) = @_;

    $c->log->info( "Submitting ES Cell QC update job for plate $plate_name" );

    my $output_file = $LOG_DIR . '/' . $plate_name . '-' . $qc_run_id . '.out';
    my $error_file = $LOG_DIR . '/' . $plate_name . '-' . $qc_run_id . '.err';

    run_cmd(
        'bsub',
        '-o', $output_file,
        '-e', $error_file,
        '-q', 'normal',
        '-P', 'team87',
        '-M', '1000000',
        '-R', "'select[mem>1000] rusage[mem=1000]'",
        'update-escell-plate-qc.pl',
        '--orig-plate-name=' . $orig_plate_name,
        '--plate-name=' . $plate_name,
        '--qc-run-id=' . $qc_run_id,
        '--user-id=' . $c->user->id
    );

    return;
}

sub run_cmd {
    my @cmd = @_;

    my $output;
    eval {
        IPC::Run::run( \@cmd, '<', \undef, '>&', \$output )
                or die "$output\n";
    };
    if ( my $err = $@ ) {
        chomp $err;
        die "$cmd[0] failed: $err";
    }

    chomp $output;
    return  $output;
}

sub _submit_qc_job {
    my ( $self, $c, $params ) = @_;

    $c->log->info( "Submitting QC job " . join(',', @{ $params->{sequencing_projects} } )
                   . "/$params->{template_plate} ($params->{profile})" );

    my $run_id;

    try {
        my $config = HTGT::QC::Config->new;

        my %run_params = (
            config              => $config,
            profile             => $params->{ profile },
            template_plate      => $params->{ template_plate },
            sequencing_projects => $params->{ sequencing_projects },
            run_type            => $params->{ run_type },
            persist             => 1
        );

        #if you add a new run type here make sure to modify the enum in Run.pm
        #this just maps a run type to the correct class
        my %run_types = (
            es_cell   => "ESCell",
            prescreen => "ESCellPreScreen",
            vector    => "Vector",
        );

        die "$params->{ run_type } is not a valid run type."
            unless exists $run_types{ $params->{ run_type } };

        my $submit_qc_farm_job = "HTGT::QC::Util::SubmitQCFarmJob::" . $run_types{ $params->{ run_type } };

        #add any additional type specific modifications in this if
        if ( $params->{ run_type } eq "vector" ) {
            #only vector needs a plate_map. 
            $run_params{ plate_map } = $params->{ plate_map };
        } 
        elsif ( $params->{ run_type } eq "prescreen" ) {
            #prescreen goes to a diff directory, so notify our config instance that we're prescreen.
            $run_params{ config }->is_prescreen(1);
        }
            

        #run holds all of these parameters together
        my $run = HTGT::QC::Run->init( %run_params );
        $run_id = $run->id;

        #this is to allow some flexibility in job memory as some were using more than 2gb
        my $memory_req = ( $c->request->params->{ 'big_memory' } ) ? 4000 : 2000;

        #now we have all the information required we can actually start the job:
        $submit_qc_farm_job->new( { qc_run => $run, memory_required => $memory_req } )->run_qc_on_farm();

        $c->log->info( "Submitted QC job $run_id" );
    }
    catch {
        $c->log->error( "QC job submission failed: $_" );
        $c->stash( error_msg => "QC job submission failed: $_" );

        $run_id = undef; #we get a run id even if submission fails, so get rid of it.
    };

    if ( $run_id ) {
        # Blank out the request parameters
        for my $param_name ( qw( profile template_plate sequencing_project sequencing_projects epd_plate_name ) ) {
            $c->request->param( $param_name, undef );
        }

        $c->stash( status_msg => "QC job $run_id submitted to farm for processing" );

        return $run_id;
    }
}

sub _validated_es_cell_params {
    my ( $self, $c ) = @_;
    my @errors;

    my $epd_plate_name = $self->_clean_input( $c, $c->request->params->{ 'epd_plate_name' }) . '_';
    my $profile = $self->_clean_input( $c, $c->request->params->{ 'profile' } );
    my @projects = $c->request->param( 'sequencing_projects' );
    my $template_plate_name = 'T' . $self->_clean_input( $c, $c->request->params->{ 'epd_plate_name' });

    #if we're on the last step and the array is of length zero, there are none selected.
    if ( $c->req->param( 'submit_job' ) and not @projects ) {
        push @errors, "No sequencing projects selected.";
    }

    #make sure the selected profile is in our list of valid profiles
    if ( $profile and not any { $_ eq $profile } @{ $self->_list_all_profiles } ) {
        push @errors, "Please select a profile name from the drop-down menu";
    }

    my $epd_plates = $c->model( 'HTGTDB::Plate' )->search({ 
        'me.name' => { like => "$epd_plate_name%" } 
    });

    #make sure the EPD plate is valid. a resultset in numeric context returns the count
    if ( $epd_plates == 0 ) {
        push @errors, "Please select a valid EPD plate";
    }
    elsif ( $c->model( 'HTGTDB::Plate' )->search( { name => $template_plate_name, type => 'VTP' } ) == 0 ) {
        #get ep plates as an array instead of resultset object
        my @ep_plates = $epd_plates->related_resultset( 'wells' )
                                   ->related_resultset( 'parent_well' )
                                   ->related_resultset( 'plate' )
                                   ->search( 
                                        { 'plate.type' => 'EP' }, 
                                        { distinct => 1 } 
                                    );
        
        #make sure we got an ep plate
        if ( @ep_plates ) {
            #create template plate_data
            my @parent_wells;
            #get the parents of every plate we found
            for my $ep_plate ( @ep_plates ) {
                my @parents = $ep_plate->wells->search( 
                    {},
                    { order_by => { -asc => 'well_name' } } 
                );

                push @parent_wells, map { [ $ep_plate->name, $_->well_name ] } @parents;
            }

            #create the template plate if it doesn't exist
            create_plate( 
                $c->model( 'HTGTDB' )->schema, 
                plate_name => $template_plate_name, 
                plate_type => 'VTP', 
                plate_data => [ @parent_wells ], 
                created_by => $c->user->id 
            );
        }
        else {
            push @errors, "EPD plate has no parent plates";
        }
    }

    if ( @errors ) {
        $c->stash( error_msg => join '<br />', @errors );
        return;
    }

    #everything was successful, so build the params hash and return it

    #r2r-only profile signifies a prescreen run.
    my $run_type = ( $profile eq 'r2r-only-es-cell' ) ? 'prescreen' : 'es_cell';

    my %params = (
        epd_plate_name => $epd_plate_name,
        profile        => $profile,
        template_plate => $template_plate_name, #inferred template plate
        run_type       => $run_type,
    );

    if ( @projects ) {
        $c->log->info("Ungrouping ES Cell plates");
        #if we've got projects the user has selected them, so we need to ungroup
        @projects = $self->ungroup_es_cell_plates( $epd_plate_name, @projects );
    }
    else {
        $c->log->info("Grouping ES Cell plates");
        #if we don't have any projects then fetch any sequencing projects for this plate
        @projects = $self->get_grouped_es_cell_plates( $epd_plate_name );
    }

    $params{ sequencing_projects } = \@projects;

    return \%params;
}

#remove trailing letters from plates and return an array of the results
sub get_grouped_es_cell_plates {
    my ( $self, $epd_plate_name ) = @_;

    #get all possible plates
    my @all_projects = $self->_get_trace_projects( $epd_plate_name );

    #we need to remove all the _A, _B etc. extensions from plates as it confuses users.
    #we also have to restore them after the user has submitted.
    my %grouped_projects;
    for my $project ( @all_projects ) {
        my ( $stripped ) = $project =~ /(\w+_\d)_\w/; #HEPD0848_1_R -> HEPD0848_1
        next unless $stripped; #this will happen to mislabelled plates with no trailing letter
        $grouped_projects{ $stripped }++;
    }

    return sort keys %grouped_projects;
}

#this is to undo the previous function and get the full list required for qc
sub ungroup_es_cell_plates {
    my ( $self, $epd_plate_name, @selected_projects ) = @_;

    my @all_projects = $self->_get_trace_projects( $epd_plate_name );

    my @ungrouped;
    for my $project ( @selected_projects ) {
        #find any projects with the same start as our selected projects,
        #so for HEPD0848_1 we expect HEPD0848_1_A, HEPD0848_1_B, etc.
        #we do $project_ to remove projects that have been mislabelled and 
        #don't have a trailing letter
        push @ungrouped, sort grep { $_ =~ /^${project}_/ } @all_projects;
    }

    return @ungrouped;
}

sub _get_trace_projects {
    my ( $self, $epd_plate_name ) = @_;
    return @{ HTGT::QC::Util::ListTraceProjects->new()->get_trace_projects( $epd_plate_name ) };
}

sub _validated_submit_params {
    my ( $self, $c ) = @_;
    my @errors;

    my %params = (
        profile        => $self->_clean_input( $c, $c->request->params->{ 'profile' } ),
        template_plate => $self->_clean_input( $c, $c->request->params->{ 'template_plate' } ),
        run_type       => 'vector',
    );

    for my $p ( keys %params ) {
        push @errors, "$p must be specified"
            unless length( $params{$p} );
    }

    my $sequencing_project = $c->request->params->{ 'sequencing_project' };
    my @sequencing_projects;
    if ( $sequencing_project ) {
        if ( ref $sequencing_project eq 'ARRAY'  ){
            for my $seq_proj ( @{ $sequencing_project } ) {
                next unless $seq_proj;
                push @errors, "Sequencing project '$seq_proj' not found"
                    unless $self->_sequencing_project_exists( $c, $seq_proj );
                push @sequencing_projects, $seq_proj;
            }
        }
        else {
            push @errors, "Sequencing project '$sequencing_project' not found"
                unless $self->_sequencing_project_exists( $c, $sequencing_project );
            push @sequencing_projects, $sequencing_project;
        }
    }
    else {
        push @errors, "sequencing project(s) must be specified";
    }
    $params{ sequencing_projects } = [ uniq @sequencing_projects ];

    if ( $params{profile} and not any { $_ eq $params{profile} } @{ $self->_list_all_profiles } ) {
        push @errors, "Please select a profile name from the drop-down menu";
    }

    if ( $params{template_plate} and not $c->model( 'HTGTDB::Plate' )->find({ type => 'VTP', name => $params{template_plate} }) ) {
        push @errors, "Template plate '$params{template_plate}' not found";
    }

    if ( @errors ) {
        $c->stash( error_msg => join '<br />', @errors );
        return;
    }

    return \%params;
}

sub _build_plate_map {
    my ( $self, $c ) = @_;
    my $params = $c->request->params;
    my $sequencing_projects = $c->request->params->{ 'sequencing_project' };
    $sequencing_projects = [ $sequencing_projects ] unless ref $sequencing_projects;

    my @map_params = grep{ $_ =~ /_map$/ } keys %{ $params };

    my %plate_map;
    foreach my $map_key ( @map_params ) {
        my $map = $self->_clean_input( $c, $params->{$map_key});
        next unless $map;
        my $plate_name = substr( $map_key,0, -4 );

        $plate_map{$plate_name} = $map;
    }

    return \%plate_map;
}

sub _validate_plate_map {
    my ( $self, $c, $plate_map, $sequencing_projects ) = @_;
    my @errors;

    my $seq_project_plate_names = get_sequencing_project_plate_names( $sequencing_projects );

    for my $plate_name ( @{ $seq_project_plate_names } ) {
        unless ( defined $plate_map->{$plate_name} ) {
            push @errors, "$plate_name not defined in plate_map";
        }

        my $canonical_plate_name = $plate_map->{$plate_name};
        unless ( $canonical_plate_name ) {
            push @errors, "$plate_name has no new plate_name mapped to it";
        }
    }

    if ( @errors ) {
        $c->stash( error_msg => join '<br />', @errors );
        return;
    }

    return $plate_map;
}

sub _sequencing_project_exists {
    my ( $self, $c, $project ) = @_;

    if ( $project and not $c->model( 'BadgerRepository' )->exists( $project ) ) {
        return;
    }
    return 1;
}

sub _clean_input {
    my ( $self, $c, $value ) = @_;
    return unless $value;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;

    return $value;
}


__PACKAGE__->meta->make_immutable;

