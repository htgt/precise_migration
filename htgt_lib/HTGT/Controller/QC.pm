package HTGT::Controller::QC;

use strict;
use warnings;

use base 'Catalyst::Controller';

use Bio::SeqIO;
use Bio::SeqFeature::Generic;
use DateTime;
use JSON;

use HTGT::Utils::Report::Recovery;
use HTGT::Utils::Report::QCResultsAndPrimers ':all';
use TargetedTrap::IVSA::SyntheticConstruct;

=head1 NAME

HTGT::Controller::QC - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

Redirected to '/qc/qc_runs'

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
}

=head2 qc_runs

Page to list all QC runs

=cut

sub qc_runs : Local {
    my ( $self, $c ) = @_;
    $self->_qc_runs_table($c) if $c->req->params->{stage};
}

=head2 _qc_runs_table

Method for the 'qc_runs' page to load a table of qc runs...

=cut

sub _qc_runs_table : Local {
    my ( $self, $c ) = @_;

    my $options = {};
    unless ( $c->check_user_roles('edit') ) {
        $options->{is_public} = '1';
    }

    $options->{stage} = $c->req->params->{stage};

    my @qctest_runs =
      $c->model('ConstructQC::QctestRun')
      ->search( $options, { order_by => { -desc => 'run_date' } } );

    $c->stash->{timestamp}   = DateTime->now;
    $c->stash->{qctest_runs} = \@qctest_runs;
}

=head2 construct_list

Page to list all QC results for a given QC run

=cut

sub construct_list : Local {
    my ( $self, $c ) = @_;

    # Fetch the QctestRun
    my $qctest_run =
      $c->model('ConstructQC::QctestRun')
      ->find( { qctest_run_id => $c->req->params->{qcrun_id} } );

    # Cehck that the user is allowed to view this page...
    if ( $qctest_run->is_public != 1 ) {
        unless ( $c->check_user_roles('edit') ) {
            $c->flash->{error_msg} =
              "Sorry, you are not authorised to view this report";
            $c->response->redirect( $c->uri_for('/') );
            return 0;
        }
    }

    # And the QctestResults (this is MUCH faster than doing a prefetch above)
    my $qc_result_rs = $c->model('ConstructQC::QctestResult')->search(
        {
            'qctestRun.qctest_run_id' => $c->req->params->{qcrun_id},
            (
                $c->req->params->{all_results}
                ? ()
                : ( is_best_for_construct_in_run => '1' )
            ),    #temporary hack dj3
        },
        {
            join     => 'qctestRun',
            prefetch => [
                'constructClone', 'expectedSyntheticVector',
                'matchedSyntheticVector',
            ],
            order_by => { -desc => 'is_best_for_engseq_in_run' }
        }
    );

    # Use this query to fetch all of the primers used/found on each QCtest
    # (shed loads faster than drilling down from the QCtestResult)
    my $primer_rs = $c->model('ConstructQC::QctestPrimer')->search(
        {
            'qctestRun.qctest_run_id' => $c->req->params->{qcrun_id},

         #'qctestResult.is_best_for_construct_in_run' => '1',#temporary hack dj3
            'me.is_valid' => '1'
        },
        { join => { qctestResult => 'qctestRun' } }
    );

    my %valid_primers;
    while ( my $primer = $primer_rs->next ) {
        push(
            @{ $valid_primers{ $primer->qctest_result_id } },
            $primer->primer_name
        );
    }

    my @design_plates;
    my @design_insts;

    # change to use raw sql to optimise the query
    my $sql = qq [
        select sv.design_plate
        from synthetic_vector sv
           join qctest_result r on r.expected_engineered_seq_id = sv.engineered_seq_id
        where
           r.is_best_for_construct_in_run = 1 and r.qctest_run_id = ?
        group by
           sv.design_plate
       union
       select sv.design_plate
       from synthetic_vector sv
          join qctest_result t on t.engineered_seq_id = sv.engineered_seq_id
        where
          t.is_best_for_construct_in_run = 1 and t.qctest_run_id = ?
        group by
          sv.design_plate
    ];

    my $sth = $c->model('ConstructQC')->storage()->dbh()->prepare($sql);
    $sth->execute( $c->req->params->{qcrun_id}, $c->req->params->{qcrun_id} );

    while ( my $des_plate_rs = $sth->fetchrow_hashref() ) {
        push( @design_plates, $des_plate_rs->{DESIGN_PLATE} );
    }

# Horrible DBI (but fast) query to fetch the Design, Gene, Exon, Locus etc info...
# (using the design plates or design_instances from above)
    $sql = qq(
        select  distinct 
        i.design_instance_id,        
        i.plate,
        i.well,
        d.design_id,
        d.design_name,
        mgi_gene.marker_symbol gene,
        mgi_gene.representative_genome_id ens_vega_id
        from    
        design d
        join design_instance i on i.design_id = d.design_id
        join project on project.design_instance_id = i.design_instance_id
        join mgi_gene on mgi_gene.mgi_gene_id = project.mgi_gene_id
    );

    for ( my $i = 0 ; $i < scalar(@design_plates) ; $i++ ) {
        $design_plates[$i] = "'" . $design_plates[$i] . "'";
    }
    $sql .= 'where   i.plate in (' . join( ',', @design_plates ) . ')';

    $sth   = $c->model('HTGTDB')->storage->dbh->prepare($sql);
    $sth->execute();

    my %di_data;

    # Load the DI data into a hashref ready for use...
    while ( my $row = $sth->fetchrow_hashref ) {
        $di_data{ $row->{DESIGN_INSTANCE_ID} } = {
            plate      => $row->{PLATE},
            well       => $row->{WELL},
            design_id  => $row->{DESIGN_ID},
            gene       => $row->{GENE},
            ens_vega_id => $row->{ENS_VEGA_ID}
        };
    }

    # Now (finally!) fetch our QC data....
    my %data;
    my %data_by_design;
    while ( my $result = $qc_result_rs->next ) {

        # Clone
        $data{ $result->qctest_result_id }->{clone} =
          $result->constructClone->name;

        # 384 well notation
        my $three_eight_four_well
            = HTGTDB::Plate::parse_well_name( $result->constructClone->name, '1' );
        if ( $three_eight_four_well ) {
            $data{ $result->qctest_result_id }->{three_eight_four} =
                $three_eight_four_well->{well};
        }

        # Exp_design
        my $exp_di = $result->expectedSyntheticVector->design_instance_id;

        $data{ $result->qctest_result_id }->{exp_design_id} =
          $di_data{$exp_di}->{design_id};
        $data{ $result->qctest_result_id }->{exp_design} =
            $di_data{$exp_di}->{plate}
          . $di_data{$exp_di}->{well} . '_'
          . $di_data{$exp_di}->{design_id};

        # Obs_design
        my $obs_di = $result->matchedSyntheticVector->design_instance_id;
        $data{ $result->qctest_result_id }->{obs_design_id} =
          $di_data{$obs_di}->{design_id};
        $data{ $result->qctest_result_id }->{obs_design} =
            $di_data{$obs_di}->{plate}
          . $di_data{$obs_di}->{well} . '_'
          . $di_data{$obs_di}->{design_id};
          
        #Is the matched Synvec 'genomic' - ie a hit to a genomic region not on the expected plate?
        $data{ $result->qctest_result_id }->{genomic_hit} = $result->matchedEngineeredSeq->is_genomic; 

        # Get the cassette info (if gateway)
        if ( $qctest_run->stage eq 'post_gateway' ) {
            my ($cassette) =
              ( $result->matchedSyntheticVector->cassette_formula =~
                  /_([sg]t[012k])/ );
            $data{ $result->qctest_result_id }->{cassette} = $cassette;
        }

        # Gene, Exon, Locus info...
        $data{ $result->qctest_result_id }->{gene} = $di_data{$obs_di}->{gene};
        $data{ $result->qctest_result_id }->{ens_vega_id} = $di_data{$obs_di}->{ens_vega_id};
        
        # Best for design
        if ( $result->is_best_for_engseq_in_run == 1 ) {
            $data{ $result->qctest_result_id }->{best} =
              $data{ $result->qctest_result_id }->{obs_design};
        }

        # Chosen for design
        my $chosen_di;
        if ( $result->is_chosen_for_engseq_in_run ) {
            $chosen_di = $result->chosenSyntheticVector->design_instance_id;
            $data{ $result->qctest_result_id }->{chosen} =
                $di_data{$chosen_di}->{plate}
              . $di_data{$chosen_di}->{well} . '_'
              . $di_data{$chosen_di}->{design_id};
        }

        # Pass Level
        $data{ $result->qctest_result_id }->{pass_level} = $result->pass_status;

        # Chosen Status
        if ( $result->chosen_status ) {
            $data{ $result->qctest_result_id }->{chosen_status} =
              $result->chosen_status;

            if ( $result->chosen_status =~ /(a|b)$/ ) {
                $data{ $result->qctest_result_id }->{aorb} = $1;
            }
        }

        # Exp/Obs match
        if ( $exp_di != $obs_di ) {
            $data{ $result->qctest_result_id }->{exp_obs_match} =
              'not as expected';
        }

        # Primers
        my $valid_primers_count = 0;
        eval {
            $valid_primers_count =
              scalar( @{ $valid_primers{ $result->qctest_result_id } } );
        };
        if ( $valid_primers_count > 0 ) {
            $data{ $result->qctest_result_id }->{primers} =
              join( ' ', @{ $valid_primers{ $result->qctest_result_id } } );
        }

        # Comment
        $data{ $result->qctest_result_id }->{comment} = $result->result_comment;

        # Push the info onto 'data_by_design'
        my $tmp_by_design = {
            qc_test_result_id => $result->qctest_result_id,
            exp_design_inst   => $exp_di,
            exp_design        => $di_data{$exp_di}->{plate}
              . $di_data{$exp_di}->{well} . '_'
              . $di_data{$exp_di}->{design_id},
            obs_design_inst => $obs_di,
            obs_design      => $di_data{$obs_di}->{plate}
              . $di_data{$obs_di}->{well} . '_'
              . $di_data{$obs_di}->{design_id},
            pass_status        => $result->pass_status,
            chosen_design_inst => $chosen_di
        };

        if ( $result->is_best_for_engseq_in_run == 1 ) {
            $tmp_by_design->{best_for_design} = 1;
        }

        push( @{ $data_by_design{$obs_di} }, $tmp_by_design );

    }

    # Pre-select the 'chosen' QC results (if we're working with vectors...)
    if ( $qctest_run->stage =~ /post_gateway|post_cre/ ) {
        foreach my $design_id ( keys %data_by_design ) {
            my @results = @{ $data_by_design{$design_id} };

            if ( scalar(@results) == 1 ) {

                # Make sure nothing is marked as chosen yet...
                if ( !defined $results[0]->{chosen_design_inst} ) {
                    $data{ $results[0]->{qc_test_result_id} }->{chosen} =
                      $results[0]->{obs_design};
                    $data{ $results[0]->{qc_test_result_id} }->{auto_chosen} =
                      1;
                }
            }
            else {

                # Make sure nothing is marked as chosen yet...
                my $already_marked_chosen = undef;
                my $best_for_design_index = undef;

                for ( my $i = 0 ; $i < scalar(@results) ; $i++ ) {
                    if ( $results[$i]->{chosen_design_inst} ) {
                        $already_marked_chosen = 1;
                    }
                    if ( $results[$i]->{best_for_design} ) {
                        $best_for_design_index = $i;
                    }
                }

                unless ( defined $already_marked_chosen ) {

                    # sort the results...
                    my @results =
                      sort { sort_vector_results( $a, $b ) } @results;

   # okay, so the top one is the 'best' one - check that there's no well slop...
                    if (
                        $results[0]->{exp_design} eq $results[0]->{obs_design} )
                    {

                        # good enough for us!
                        $data{ $results[0]->{qc_test_result_id} }->{chosen} =
                          $results[0]->{obs_design};
                        $data{ $results[0]->{qc_test_result_id} }
                          ->{auto_chosen} = 1;
                    }
                    else {

     # damn well slop... see if the next result that ISN'T a well slop is better
     # than a pass2 - Tony would prefer this...

                        my $choose_me = undef;
                        for ( my $i = 0 ; $i < scalar(@results) ; $i++ ) {
                            if ( $results[$i]->{exp_design} eq
                                $results[$i]->{obs_design} )
                            {
                                if (
                                    is_vector_pass_best(
                                        $results[$i]->{pass_status}, 'pass2'
                                    )
                                  )
                                {
                                    $choose_me = $i;
                                    $i         = scalar(@results);
                                }
                            }
                        }

                        # did we find a good one?
                        if ( defined $choose_me ) {
                            $data{ $results[$choose_me]->{qc_test_result_id} }
                              ->{chosen} = $results[$choose_me]->{obs_design};
                            $data{ $results[$choose_me]->{qc_test_result_id} }
                              ->{auto_chosen} = 1;
                        }
                        else {

                            # nope, take the original well slop...
                            $data{ $results[0]->{qc_test_result_id} }
                              ->{chosen} = $results[0]->{obs_design};
                            $data{ $results[0]->{qc_test_result_id} }
                              ->{auto_chosen} = 1;
                        }
                    }
                }
            }
        }
    }

    $c->stash->{qctest_run} = $qctest_run;
    $c->stash->{keys} =
      [ sort { $data{$a}->{clone} cmp $data{$b}->{clone} } keys %data ];
    $c->stash->{results} = \%data;
}

=head2 sort_vector_results

Private sorting method for 'construct_list' when trying to pre-select which are the best constructs 
in post-cre or post-gateway samples.  Will sort an array of hashrefs by the best pass level and 
'best for design' parameters.

=cut

sub sort_vector_results : Private {
    my ( $result1, $result2 ) = @_;

    my ( $pass1_no1, $pass1_no2, $pass1_letter ) =
      parse_vector_pass_level( $result1->{pass_status} );
    my ( $pass2_no1, $pass2_no2, $pass2_letter ) =
      parse_vector_pass_level( $result2->{pass_status} );

    my $return_val = 0;
    my $skip       = undef;

    # test passX
    if ( defined $pass1_no1 && defined $pass2_no1 ) {
        if    ( $pass1_no1 < $pass2_no1 ) { $return_val = -1; $skip = 1; }
        elsif ( $pass1_no1 > $pass2_no1 ) { $return_val = 1;  $skip = 1; }

        # they're the same - test the other params...
    }

    unless ($skip) {

        # If the above does not cause an exit, test passX.Y
        if ( defined $pass1_no2 && defined $pass2_no2 ) {
            if    ( $pass1_no2 < $pass2_no2 ) { $return_val = -1; $skip = 1; }
            elsif ( $pass1_no2 > $pass2_no2 ) { $return_val = 1;  $skip = 1; }

            # they're the same - test the other params...
        }
    }

    unless ($skip) {

        # If we get this far, test passX.Y[a|b]
        if ( defined $pass1_letter && defined $pass2_letter ) {
            if ( $pass1_letter lt $pass2_letter ) {
                $return_val = -1;
                $skip       = 1;
            }
            elsif ( $pass1_letter gt $pass2_letter ) {
                $return_val = 1;
                $skip       = 1;
            }

            # they're the same - test the other params...
        }
    }

    unless ($skip) {

        # Next, check the 'best_for_design' param
        if ( defined $result1->{best_for_design} ) {
            $return_val = -1;
            $skip       = 1;
        }
        elsif ( defined $result2->{best_for_design} ) {
            $return_val = 1;
            $skip       = 1;
        }
    }

    unless ($skip) {

     # Finally, check for well slop - if we have two pass levels that are equal,
     # the well slop needs to come second

        my $val_for_result1 = 0;
        my $val_for_result2 = 0;
        if ( $result1->{exp_design} eq $result1->{obs_design} ) {
            $val_for_result1 = 1;
        }
        if ( $result2->{exp_design} eq $result2->{obs_design} ) {
            $val_for_result2 = 1;
        }
        $return_val = $val_for_result1 <=> $val_for_result2;
    }

    return $return_val;
}

=head2 is_vector_pass_best

Private method compare two pass_levels.  Takes either one or two pass levels as its arguments... 
- If given two pass levels, will return 1 if the first pass_level is a better pass, (0 if not)
- If given a single pass_level, will return 1 if it is better than a 'pass3', (0 if not)

=cut

sub is_vector_pass_best : Private {
    my $new_pass_level = shift;
    my $cur_pass_level = shift;
    unless ($cur_pass_level) { $cur_pass_level = 'pass3'; }

    my ( $cur1, $cur2, $cur_letter ) = parse_vector_pass_level($cur_pass_level);
    my ( $new1, $new2, $new_letter ) = parse_vector_pass_level($new_pass_level);

    # test passX ...
    if ( ( defined $new1 ) && ( $new1 < $cur1 ) ) { return 1; }
    elsif ( ( !defined $new1 ) || ( $new1 == $cur1 ) ) {

        # test passX.Y ...
        if ( ( defined $new2 ) && ( $new2 < $cur2 ) ) { return 1; }
        elsif ( ( !defined $new2 ) || ( $new2 == $cur2 ) ) {

            # test passX.Y[a|b]
            my $comp_letters = $new_letter cmp $cur_letter;
            if   ( $comp_letters < 0 ) { return 1; }
            else                       { return 0; }
        }
    }
}

=head2 parse_vector_pass_level

Private method to parse a vector pass level into its three components passX.Yz, 
where X and Y are numbers, and z is a letter, these can then be used to sort or 
classify pass levels.

=cut

sub parse_vector_pass_level : Private {
    my $pass_level = shift;
    $pass_level =~ s/d//g; # XXX temporary work-around to parse deletion pass levels, see RT#168559.
    my $digit1;
    my $digit2;
    my $letter;

# Now try and cope with the different types of 'pass_levels' avaialble... ARRRGGGHHH!!!
    if ( $pass_level =~ /^pass(\d)\.(\d)(\D+)$/ ) {
        $digit1 = $1;
        $digit2 = $2;
        $letter = $3;
    }
    elsif ( $pass_level =~ /^pass(\d)\.(\d)$/ ) {
        $digit1 = $1;
        $digit2 = $2;
        $letter = 'z';
    }
    elsif ( $pass_level =~ /^pass(\d)$/ )     { $digit1 = $1; $letter = 'z'; }
    elsif ( $pass_level =~ /^pass(\d)(\D)$/ ) { $digit1 = $1; $letter = $2; }
    elsif ( $pass_level =~ /^pass(\D)$/ )     { $letter = $1; }
    elsif ( $pass_level =~ /^warn_.*([a|b])$/ ) { $letter = $1; }
    elsif ( $pass_level =~ /^fail$/ )           { $letter = 'z'; }
    elsif ( $pass_level =~ /fail|warn/ )        { $letter = 'z'; }
    elsif ( $pass_level eq 'pass' ) { $letter = 'a'; }
    else { die "ERROR: Unreadable pass level " . $pass_level . "\n"; }

    return ( $digit1, $digit2, $letter );
}

=head2 qctest_result_and_primer_list

Method for retrieving qctest results given a qc run id

=cut

sub qctest_result_and_primer_list : Local {
    my ( $self, $c ) = @_;

    my $qctest_run_id  = $c->req->params->{qctest_run_id};
    my $display_synvec = $c->req->params->{display_synvec} || 0;

    if ( $display_synvec == 1 ) {
        $c->stash->{synvecs}  = retrieve_data_for( $c->model('ConstructQC'), $qctest_run_id , { order => 'synvec' , optimize => 1 } );
        $c->stash->{template} = 'qc/qctest_result_by_synvec.tt';
    }
    else {
        $c->stash->{results}  = retrieve_data_for( $c->model('ConstructQC'), $qctest_run_id , { order => 'clone' , optimize => 1 });
        $c->stash->{template} = 'qc/qctest_result.tt';
    }

    $c->stash->{qctest_run_id} = $qctest_run_id;
    $c->stash->{test_results}  = $c->stash->{results};
}

=head2 dump_best_clones_to_csv_file

Method for dumping best clones to a csv file which can be used to create a 384 plate

=cut

sub dump_best_clones_to_csv_file : Local {
    my ( $self, $c ) = @_;
    my $qctest_run_id = $c->req->params->{qctest_run_id};
    
    my $test_results = retrieve_data_for( $c->model('ConstructQC'), $qctest_run_id , { order => 'clone' , optimise => 1 });
    
    my @clones;
    foreach my $test_result (@$test_results) {
	if ($test_result->{best_for_design} == 1) {
	    push @clones, $test_result;
	}
    }
    @clones = sort { $a->{design_well} <=> $b->{design_well} } @clones;

    $c->stash->{clones} = \@clones;
    $c->stash->{template}  = 'qc/best_clones.csvtt';
}

=head2 results_list 

Simple reporting of qctest_results.

=cut

sub results_list : Local {
    my ( $self, $c ) = @_;
    my %search_params = qw(
      qctest_result_id   me.qctest_result_id
      qctest_run_id      me.qctest_run_id
      construct_clone_id me.construct_clone_id
      engineered_seq_id  me.engineered_seq_id
      pass_status        me.pass_status
      is_best_for_construct_in_run me.is_best_for_construct_in_run
      );    #convert HTTP params to names suitable for DBIx::Class queries
    my $where;

    if ( $c->check_user_roles('edit')
        and my $json = $c->req->params->{'where'} )
    {
        $where = jsonToObj($json);
    } #Holy moley - what's he doing here? ;-) - allowing JSON for the DBIx::Class query

    my $r_rs = $c->model('ConstructQC::QctestResult')->search(
        ref $where ? $where : {
            (
                $c->check_user_roles('edit') ? ()
                : ( 'qctestRun.is_public' => 1 )
            ),
            (
                map {
                    exists( $c->req->params->{$_} )
                      ? ( $search_params{$_} => $c->req->params->{$_} )
                      : ()
                  } keys %search_params
            )
        },
        {
            join     => 'qctestRun',
            prefetch => [
                'matchedEngineeredSeq',
                'constructClone',
                'qctestRun',
            ]
        }
    );
    $c->stash->{qctest_results_rs} = $r_rs;
    my @primers =
      $r_rs->related_resultset('constructClone')
      ->related_resultset('qcSeqreads')
      ->search( undef, { select => ['oligo_name'], distinct => 1 } )
      ->get_column('oligo_name')->all;
    $c->stash->{primers} = \@primers;
}

sub seq_view : Local {
    my ( $self, $c ) = @_;

    my $gene = undef;

    if ( defined $c->req->params->{gene_id} ) {
        $gene =
          $c->model('HTGTDB::GnmGene')
          ->find( { id => $c->req->params->{gene_id} }, {} );
    }

    $c->stash->{do_not_show_login} = 'true';
    $c->stash->{gene}              = $gene;
    $c->stash->{engseq_id}         = $c->stash->{engineered_seq_id} =
      $c->req->params->{engineered_seq_id} || $c->req->params->{engseq_id};
    $c->stash->{qctest_result_id} = $c->req->params->{qctest_result_id};
    $c->stash->{design_id}        = $c->req->params->{design_id};
    $c->stash->{cassette}         = $c->req->params->{cassette};
}

=head2 seq_view_file

Gets synthetic construct from legacy QC system if synthetic construct id given, wildtype region of interest if design given, or synth allele if cassette given as well, or synth vector if backbone given as well.

=cut

sub seq_view_file : Local {
    my ( $self, $c ) = @_;

    my $seq;    #a Bio::SeqI object
    if ( my $qctest_result_id = $c->req->params->{qctest_result_id} ) {
        $seq =
          $c->model('ConstructQC::QctestResult')->find({qctest_result_id => $qctest_result_id})
          ->bioseq();
    }
    elsif ( my $engseq_id = $c->req->params->{engineered_seq_id}
        || $c->req->params->{engseq_id} )
    {
        $seq =
          $c->model('ConstructQC::EngineeredSeq')->find({ engineered_seq_id =>  $engseq_id })->bioseq();
    }
    elsif ( my $d_id = $c->req->params->{design_id} ) {
        my $d = $c->model(q(HTGTDB::Design))->find({design_id => $d_id});
        die "Could not find design $d_id" unless $d;
        if ( my $cs = $c->req->params->{cassette} ) {
            if ( my $bb = $c->req->params->{backbone} ) {
                $seq = $d->vector_seq( $cs, $bb );
                $seq->is_circular(1);
            }
            elsif ( my $tt = $c->req->params->{targeted_trap} ) {
                $seq =
                  $d->allele_seq( $cs, 1 );    # give the targeted trap option 1
            }
            else {
                $seq = $d->allele_seq($cs);
            }
        }
        elsif ( my $bb = $c->req->params->{backbone} ) {
            $seq = $d->vector_seq( undef, $bb );
        }
        else {
            ($seq) = $d->wildtype_seq;
        }
    }
    elsif ( my $cs = $c->req->params->{cassette} ) {
        $seq =
          TargetedTrap::IVSA::SyntheticConstruct::get_cassette_vector_seq($cs);
    }
    elsif ( my $bb = $c->req->params->{backbone} ) {
        $seq = TargetedTrap::IVSA::SyntheticConstruct::get_backbone_seq($bb);
    }
    die "No sequence object available" unless $seq;

    if ( $c->req->params->{munge} ) {    #hack for VectorNTI
        for my $f ( $seq->get_SeqFeatures ) {
            if ( my @n = $f->annotation->get_Annotations('note') ) {
                my $str = join ", ", @n;
                $str = substr( $str, 0, 15 ) if ( length($str) > 15 );
                $f->primary_tag($str);
            }
        }
    }

# this is the quick solution to contain 'label' feature annotations in Genebank file (requested by Roland Friedel)
    for my $f ( $seq->get_SeqFeatures ) {
        if ( not $f->has_tag('label') ) {
            if ( my @n = $f->get_tagset_values('note') ) {
                $f->add_tag_value( 'label', @n );
            }
        }
    }

    my $seqstr;
    my $strio = IO::String->new($seqstr);
    my $seqo  = new Bio::SeqIO(
        -fh     => $strio,
        -format => (
            $c->req->params->{format} ? $c->req->params->{format} : q(genbank)
        )
    );

    $seqo->write_seq($seq);
    $c->res->body("$seqstr");
    $c->res->content_type('text/plain');
    return $seq;
}

use Bio::Graphics;

sub seq_view_graphics : Local {
    my ( $self, $c ) = @_;
    my $seq = $self->seq_view_file($c);

    #loop to tidy up features....
    if ( !$c->req->params->{notart} ) {
        for ( $seq->get_SeqFeatures ) {
            $_->remove_tag('translation') if $_->has_tag('translation');
            if ( my @n = $_->get_tagset_values('note') ) {
                if ( join( "", @n ) =~ /primer/i ) {
                    $_->primary_tag('primer_bind');
                    foreach (@n) {
                        $_->value($1) if /^(.*?)(?:\s+(?:seq\s*)?primer\s*)$/;
                    }
                }
                elsif ( join( "", @n ) =~ /(\sarm)|target.region/i ) {
                    $_->primary_tag('genomic');
                }
                elsif ( join( "", @n ) =~ /en-?2/i ) {
                    $_->primary_tag('genomic');
                }
                elsif ( join( "", @n ) =~ /bgal|neo/i ) {
                    $_->primary_tag('genomic');
                }
                elsif ( join( "", @n ) =~ /promoter/i ) {
                    $_->primary_tag('genomic');
                }
                elsif ( join( "", @n ) =~ /loxp|frt/i ) {
                    $_->primary_tag('SSR_site');
                    foreach (@n) { $_->value($1) if /^(.*?)(?:\s+site\s*)$/ }
                }
                elsif ( join( "", @n ) =~ /\b[LRB][1-4]\b/ ) {
                    $_->primary_tag('genomic');
                }
                elsif ( join( "", @n ) =~ /\bpA\b/ ) {
                    $_->primary_tag('genomic');
                    foreach (@n) { $_->value($1) if /^(.*?)(?:\s+pA\s*)$/ }
                }
                elsif ($_->primary_tag() eq 'misc_feature'
                    || $_->primary_tag() eq 'CDS' )
                {
                    $_->primary_tag('genomic');
                }
                elsif ( $_->primary_tag() eq 'seq_align' ) {
                }
                else {
                    if (   defined $c->req->params->{engseq_id}
                        or defined $c->req->params->{engineered_seq_id} )
                    {
                        $_->primary_tag('cassette');
                    }
                }
            }
        }
    }

    # sort features by their primary tags
    my %sorted_features;
    for my $f ( $seq->all_SeqFeatures ) {
        my $tag = $f->primary_tag;
        push @{ $sorted_features{$tag} }, $f;
    }

    my $panel = Bio::Graphics::Panel->new(
        -segment   => $seq,
        -key_style => 'between',
        -width     => 800,
        -pad_left  => 10,
        -pad_right => 10
    );

    my $wholeseq = Bio::SeqFeature::Generic->new(
        -start        => 1,
        -end          => $seq->length,
        -display_name => $seq->display_name
    );

    # rule/scale
    $panel->add_track(
        $wholeseq,
        -glyph  => 'arrow',
        -bump   => 0,
        -double => 1,
        -tick   => 2
    );

    # special cases

    if ( $sorted_features{genomic} && !$c->req->params->{notart} ) {

        # Edit the features...
        my $edited_feats;
        foreach my $f ( @{ $sorted_features{genomic} } ) {
            my $s = join " ", $f->get_tagset_values('note');
            use Switch;
            switch ($s) {
                case /^FCHK/i       { }
                case /frame/i       { }
                case /neoSph/i      { }
                case /neoPst/i      { }
                case /neoBst/i      { }
                case /B\d/i         { }
                case /R\d amp/i     { }
                case /LacZ(.+)/i    { }
                case /betact\d/i    { }
                case /RAF5/i        { }
                case /LAR3_1/i      { }
                case /T2/i          { }
                case /translation/i { }
                case /TM domain/i   { }
                case /Rat Cd4/i     { }
                else { push( @{$edited_feats}, $f ); }
            }
        }

        $panel->add_track(
            $edited_feats,
            -glyph => sub {
                my $f = shift;
                my $s = join " ", $f->get_tagset_values('note');
                use Switch;
                switch ($s) {
                    case /arm|region/i { return 'generic' }
                    else               { return 'transcript2' }
                }
            },
            -bgcolor => sub {
                my $f = shift;
                my $s = join " ", $f->get_tagset_values('note');
                use Switch;
                switch ($s) {
                    case /arm/i           { return 'red' }
                    case /region/i        { return 'chartreuse' }
                    case /SV\d/i          { return 'green' }
                    case /en\-2/i         { return 'cyan' }
                    case /en2/i           { return 'cyan' }
                    case /IRES/i          { return 'purple' }
                    case /promoter/i      { return 'magenta' }
                    case /neo/i           { return 'grey' }
                    case /lacZ/i          { return 'blue' }
                    case /galactosidase/i { return 'blue' }
                    case /bgal/i          { return 'blue' }
                    else                  { return 'yellow' }
                }
            },
            -fgcolor => sub {
                my $f = shift;
                my $s = join " ", $f->get_tagset_values('note');
                use Switch;
                switch ($s) {
                    case /arm/i           { return 'red' }
                    case /region/i        { return 'chartreuse' }
                    case /SV\d/i          { return 'green' }
                    case /en\-2/i         { return 'cyan' }
                    case /en2/i           { return 'cyan' }
                    case /IRES/i          { return 'purple' }
                    case /promoter/i      { return 'magenta' }
                    case /neo/i           { return 'grey' }
                    case /lacZ/i          { return 'blue' }
                    case /galactosidase/i { return 'blue' }
                    case /bgal/i          { return 'blue' }
                    else                  { return 'yellow' }
                }
            },
            -key    => 'Genomic Features',
            -bump   => 0,
            -height => 12
        );
        delete $sorted_features{genomic};
    }

    if ( $sorted_features{exon} && !$c->req->params->{notart} ) {
        $panel->add_track(
            $sorted_features{exon},
            -glyph   => 'transcript2',
            -bgcolor => sub {
                my $f = shift;
                my $s = join " ", $f->get_tagset_values('note');
                if   ( $s =~ /target/ ) { return '#074987'; }
                else                    { return 'orange'; }
            },
            -fgcolor => sub {
                my $f = shift;
                my $s = join " ", $f->get_tagset_values('note');
                if   ( $s =~ /target/ ) { return '#074987'; }
                else                    { return 'orange'; }
            },
            -key    => 'Exons',
            -bump   => 0,
            -height => 12
        );
        delete $sorted_features{exon};
    }

    if ( $sorted_features{LRPCR_primer} && !$c->req->params->{notart} ) {

        # Edit the features...
        my $edited_feats;
        foreach my $f ( @{ $sorted_features{LRPCR_primer} } ) {
            my $s = join " ", $f->get_tagset_values('note');
            if   ( $s =~ /EX/ ) { next; }
            else                { push( @{$edited_feats}, $f ); }
        }

        $panel->add_track(
            $edited_feats,
            -glyph   => 'transcript2',
            -bgcolor => 'blue',
            -fgcolor => 'blue',
            -key     => 'LRPCR Primers',
            -height  => 12,
            -bump    => 0
        );
        delete $sorted_features{LRPCR_primer};
    }

    if ( $sorted_features{rcmb_primer} && !$c->req->params->{notart} ) {

        # Edit the features...
        my $edited_feats;
        foreach my $f ( @{ $sorted_features{rcmb_primer} } ) {
            my $s = join " ", $f->get_tagset_values('note');
            if   ( $s =~ /U|D/ ) { next; }
            else                 { push( @{$edited_feats}, $f ); }
        }

        $panel->add_track(
            $edited_feats,
            -glyph   => 'transcript2',
            -bgcolor => 'black',
            -fgcolor => 'black',
            -key     => 'Gap Retrieval Primers',
            -bump    => 0,
            -height  => 12
        );
        delete $sorted_features{rcmb_primer};
    }

    if ( $sorted_features{SSR_site} && !$c->req->params->{notart} ) {
        $panel->add_track(
            $sorted_features{SSR_site},
            -glyph   => 'transcript2',
            -fgcolor => sub {
                my $f = shift;
                my $s = join " ", $f->get_tagset_values('note');
                use Switch;
                switch ($s) {
                    case /FRT/i  { return 'green' }
                    case /loxP/i { return 'red' }
                    else         { return 'black' }
                }
            },
            -bgcolor => sub {
                my $f = shift;
                my $s = join " ", $f->get_tagset_values('note');
                use Switch;
                switch ($s) {
                    case /FRT/i  { return 'green' }
                    case /loxP/i { return 'red' }
                    else         { return 'orange' }
                }
            },
            -font2color => 'grey',
            -key        => 'FRT/loxP Sites',
            -height     => 12
        );
        delete $sorted_features{'SSR_site'};
    }

    if ( $sorted_features{seq_align} && !$c->req->params->{notart} ) {
        $panel->add_track(
            $sorted_features{seq_align},
            -glyph      => 'transcript2',
            -font2color => 'grey',
            -key        => 'read alignments',
            -height     => 12
        );
        delete $sorted_features{'seq_align'};
    }

    if ( !$c->req->params->{notart} ) {
        delete $sorted_features{target_element};
        delete $sorted_features{gateway};
        delete $sorted_features{primer_bind};
    }
    if ( $c->req->params->{notart} ) {

        # general case
        my @colors =
          qw(orange cyan blue purple green chartreuse magenta yellow aqua);
        my $idx = 0;
        for my $tag ( sort keys %sorted_features ) {
            my $features = $sorted_features{$tag};
            $panel->add_track(
                $features,
                -glyph       => 'transcript2',
                -bgcolor     => $colors[$idx],
                -fgcolor     => $colors[$idx],
                -font2color  => 'grey',
                -key         => "${tag}",
                -height      => 12,
                -description => \&generic_description,
            );
            if   ( $idx < 8 ) { $idx++; }
            else              { $idx = 0; }
        }
    }

    $c->res->body( $panel->png );
    $c->res->content_type('image/png');

}

sub gene_label : Private {
    my $feature = shift;
    my @notes;
    foreach (qw(product gene)) {
        next unless $feature->has_tag($_);
        @notes = $feature->each_tag_value($_);
        last;
    }
    $notes[0];
}

sub gene_description : Private {
    my $feature = shift;
    my @notes;
    foreach (qw(note)) {
        next unless $feature->has_tag($_);
        @notes = $feature->each_tag_value($_);
        last;
    }
    return unless @notes;
    substr( $notes[0], 30 ) = '...' if length $notes[0] > 30;
    $notes[0];
}

sub generic_description : Private {
    my $feature = shift;
    my $description;
    my @values = $feature->get_tagset_values('label');
    return join ", ", @values if @values;
    foreach ( grep { $_ ne "db_xref" and $_ ne "type" } $feature->all_tags ) {
        @values = $feature->each_tag_value($_);
        $description .= $_ eq 'note' ? "@values" : "$_=@values; ";
    }
    $description =~ s/; $//;    # get rid of last
    $description;
}

=head2 qctest_result_view

Retrieve the components of a QCTestResult of interest to us

=cut

sub qctest_result_view : Local {
    my ( $self, $c ) = @_;

    # Retrieve and validate the qctest_result_id
    my $qctest_result_id = $c->request->param('qctest_result_id');

    unless ( defined $qctest_result_id ) {
        $c->flash->{error_msg} = 'qctest_result_id is not defined';
        $c->log->error('qctest_result_id is not defined');
        return;
    }
    unless ( $qctest_result_id =~ /^\d+$/ ) {
        $c->flash->{error_msg} =
          "qctest_result_id ($qctest_result_id) is not numeric";
        $c->log->error("qctest_result_id ($qctest_result_id) is not numeric");
        return;
    }

    # Retrieve and validate the QctestResult object
    my $qctest_result = $c->model('ConstructQC::QctestResult')->find(
        { qctest_result_id => $qctest_result_id },
        {
            prefetch =>
              [ 'constructClone', 'matchedEngineeredSeq', 'qctestPrimers' ]
        }
    );

    unless ( $qctest_result ) {
        $c->flash->{error_msg} =
          "No QctestResult with qctest_result_id ($qctest_result_id)";
        $c->log->error( "No ConstructQC::QctestResult for "
           . "qctest_result_id ($qctest_result_id)" );
        return;
    }

    my @primers = ();
    for my $primer ( $qctest_result->qctestPrimers ) {
        my $primer_hash_ref = {};

        # populate the primer hash
        $primer_hash_ref->{name}        = $primer->primer_name;
        $primer_hash_ref->{status}      = $primer->primer_status;

        if ( defined $primer->qcSeqread ) {
          $primer_hash_ref->{seqread_id}  = $primer->qcSeqread->seqread_id;
          $primer_hash_ref->{trace}       = $primer->qcSeqread->read_name;
          $primer_hash_ref->{read_length} = length $primer->qcSeqread->sequence;
        }

        if ( defined $primer->seqAlignFeature ) {
            $primer_hash_ref->{align_length} =
              $primer->seqAlignFeature->align_length;
            $primer_hash_ref->{cmatch} =
              $primer->seqAlignFeature->cmatch;
            $primer_hash_ref->{alignment} =
              $primer->seqAlignFeature->seq_align_id;
            $primer_hash_ref->{features} =
              $primer->seqAlignFeature->observed_features;
            $primer_hash_ref->{synvec_loc} =
                $primer->seqAlignFeature->engseq_start
              . '-'
              . $primer->seqAlignFeature->engseq_end
              . $primer->seqAlignFeature->engseq_ori;
            $primer_hash_ref->{seqread_loc} =
                $primer->seqAlignFeature->seqread_start
              . '-'
              . $primer->seqAlignFeature->seqread_end
              . $primer->seqAlignFeature->seqread_ori;
            $primer_hash_ref->{mscore} =
              sprintf '%02.2f', $primer->seqAlignFeature->map_score;
            $primer_hash_ref->{percent_identity} =
              sprintf '%02.2f', $primer->seqAlignFeature->percent_identity;
        }

        push @primers, $primer_hash_ref;
    }

    # Stash what we need from the QctestResult object
    $c->stash->{qctest_result} = {
        qctest_result_id         => $qctest_result->qctest_result_id,
        construct_clone_name     => $qctest_result->constructClone->name,
        engineered_sequence_name => $qctest_result->matchedEngineeredSeq->name,
        pass_status              => $qctest_result->pass_status,
        qctest_primers           => [@primers],
        construct_clone_id       =>
          $qctest_result->constructClone->construct_clone_id,
        engineered_sequence_id   =>
          $qctest_result->matchedEngineeredSeq->engineered_seq_id,
        stage                    => $qctest_result->qctestRun->stage =~ m/allele/
                                  ? 'Allele'
                                  : 'Synthetic Vector',
    };

    # Stash the SeqAlignFeature object
    if ( my $seq_align_id = $c->request->param('align_id') ) {
        unless ( $seq_align_id =~ /^\d+$/ ) {
            $c->flash->{error_msg} =
              "seq_align_id ($seq_align_id) is not numeric";
            $c->log->error("seq_align_id ($seq_align_id) is not numeric");
            return;
        }

        my $seq_align_feature =
          $c->model('ConstructQC::SeqAlignFeature')
          ->find( { seq_align_id => $seq_align_id },
            { prefetch => [ 'qcSeqread', 'engineeredSeq' ] } );

        unless ( $seq_align_feature ) {
            $c->flash->{error_msg} =
              "No SeqAlignFeature with id ($seq_align_id)";
            $c->log->error(
                "No ConstructQC::SeqAlignFeature with id ($seq_align_id)");
            return;
        }

        $c->stash->{seq_align_feature} = {
            id        => $seq_align_id,
            alignment => $seq_align_feature->show_alignment,
        };
    }
}

=head1 AUTHOR

Darren Oakley <do2@sanger.ac.uk>
David K Jackson <david.jackson@sanger.ac.uk>
Nelo Onyiah <io1@sanger.ac.uk>
Wanjuan Yang<wy1@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
