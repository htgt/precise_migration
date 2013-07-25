package HTGT::Utils::Report::QCResultsAndPrimers;

use 5.008;
use strict;
use warnings FATAL => qw(all);

use Params::Validate qw(:all);
use Sub::Exporter -setup => { exports => [qw(retrieve_data_for)] };

=head1 SYNOPSIS

    use HTGT::Utils::Report::QCResultsAndPrimers ':all';

    $results = retrieve_data_for( $model, $run_id, { order => 'synvec' } );

    # somewhere else ...
    sub qctest_result_and_primer_list : Local {
        my ( $self, $c ) = @_;

        my $qctest_run_id  = $c->req->params->{qctest_run_id};
        my $display_synvec = $c->req->params->{display_synvec} || 0;

        my ( $sort_by, $template ) =
          $display_synvec == 1
          ? ( 'synvec', 'qc/qctest_result_by_synvec.tt' )
          : ( 'clone',  'qc/qctest_result.tt' );

        $c->stash{results} = retrieve_data_for( $c->model('ConstructQC'),
            $qctest_run_id, { order => $sort_by } );

        $c->stash{template} = $template;
        $c->stash{run_id}   = $qctest_run_id;
    }

=head1 DESCRIPTION

This module provides an interface for retrieving the QC test results for a specified run as
well as routines for sorting these results and organizing them by test result or synthetic
vectors.

=method B<retrieve_data_for>

  retrieve_data_for(
    Model   $model,
    Int     $run_id,
    HashRef $params,
  )

E<where:>

  $params = {
    'synvec|clone' order    => 'synvec',
    Bool           optimize => 1
  }

=cut

sub retrieve_data_for {
    my ( $model, $run_id, $params ) = validate_pos(
        @_,
        { can   => [qw(resultset)] },
        { regex => qr/^\d+$/ },
        { type  => HASHREF, optional => 1 },
    );

    # Validate the remaining parameters
    my $optimize =
      defined $params->{optimize} && $params->{optimize} == 0 ? 0 : 1;
    my $order =
      defined $params->{order} && $params->{order} =~ m/clone|synvec/
      ? $params->{order}
      : 'synvec';

    my %function_for =
      ( synvec => \&_orientate_by_synvec, clone => \&_orientate_by_clone );

    my $results_rs = _find_results_for_run( $model, $run_id );
    my $final_results = _munge_qcresults_resultset($results_rs);

    # return the data sorted with the correct sorting function
    return $function_for{$order}->($final_results);
}

sub _find_results_for_run {
    my ( $model, $run_id ) = @_;
    my $run = $model->resultset('QctestRun')->find(
        {
            'me.qctest_run_id' => $run_id,
            'qctestResults.is_best_for_construct_in_run' => 1,   # make optional
        },
        {
            prefetch => [
                {
                    'qctestResults' => [
                        'constructClone',
                        {
                            'qctestPrimers' =>
                              [ 'qcSeqread', 'seqAlignFeature' ]
                        },
                        'matchedEngineeredSeq',
                        'matchedSyntheticVector',
                    ]
                }
            ],
        },
    );
    return $run->qctestResults;
}

sub _munge_qcresults_resultset {
    my ($results_rs) = @_;
    my %results_for = ();

  QCTEST_RESULTS: while ( my $current_result = $results_rs->next ) {
        my $eng_seq = $current_result->matchedEngineeredSeq;
        my $synvec  = $current_result->matchedSyntheticVector;
        my $primers = $current_result->qctestPrimers;

# create a new $results_for{eng_seq}{qw(name design_well design_plate is_genomic)}
        unless ( exists $results_for{ $eng_seq->name } ) {
            $results_for{ $eng_seq->name }{name} = $eng_seq->name;
            $results_for{ $eng_seq->name }{design_plate} =
              $synvec->design_plate;
            $results_for{ $eng_seq->name }{design_well} = $synvec->design_well;
            $results_for{ $eng_seq->name }{is_genomic}  = $eng_seq->is_genomic
              || 0;
        }

        # update the qw(qc_results good_clones available_primers)
        push @{ $results_for{ $eng_seq->name }{qc_results} },
          {
            qctest_result_id => $current_result->qctest_result_id,
            pass_status      => $current_result->pass_status,
            construct_clone  => $current_result->constructClone->name,
            clone_plate      => $current_result->constructClone->plate,
            clone_well       => $current_result->constructClone->well,
            best_for_design  => $current_result->is_best_for_engseq_in_run,
            primers          => _munge_primers_resultset($primers),
            synthetic_vector => $eng_seq->name,
          };
    }

    return [ values %results_for ];
}

# can make this return the %ok_primers
sub _munge_primers_resultset {
    my ($primers_rs) = @_;
    my $primers = {};

  QCTEST_PRIMER: while ( my $current_primer = $primers_rs->next ) {
        my %single_primer = (
            primer_status => $current_primer->primer_status,
            primer_name   => $current_primer->primer_name,
        );

        if ( $current_primer->qcSeqread ) {
            $single_primer{read_length} =
              length $current_primer->qcSeqread->sequence;
        }

        if ( $current_primer->seqAlignFeature ) {
            $single_primer{align_length} =
              $current_primer->seqAlignFeature->align_length;
            $single_primer{loc_status} =
              $current_primer->seqAlignFeature->loc_status;
        }
        $primers->{ $current_primer->primer_name } = \%single_primer;
    }
    return $primers;
}

sub _orientate_by_synvec {
    my ($results_ref) = @_;
    my @final_results = ();

    while ( my $current_result = shift @{$results_ref} ) {
        my ( %available_primers, %all_clones );

        for my $qc_result ( @{ $current_result->{qc_results} } ) {

            # retrieve the available_primers
            for my $primer ( values %{ $qc_result->{primers} } ) {
                $available_primers{ $primer->{primer_name} }++;
            }

            # retrieve the good_clones
            my %clone = (
                clone_name       => $qc_result->{construct_clone},
                pass_status      => $qc_result->{pass_status},
                best_for_design  => $qc_result->{best_for_design},
                ok_primers_count => scalar
                  grep { defined $_->{loc_status} && $_->{loc_status} eq 'ok' }
                  values %{ $qc_result->{primers} },
            );

            $all_clones{ $clone{clone_name} } = \%clone;
            $qc_result->{ok_primers_count}    = $clone{ok_primers_count}; 
        }

        $current_result->{available_primers} = [ keys %available_primers ];

        # collect and sort the good clones
        $current_result->{good_clones} = [
            sort {
                     $b->{best_for_design}  <=> $a->{best_for_design}
                  || $b->{ok_primers_count} <=> $a->{ok_primers_count}
            }
            grep { $_->{ok_primers_count} >= 2 } values %all_clones
        ];

        $current_result->{qc_results} = [
            sort {
                   $b->{best_for_design}  <=> $a->{best_for_design}
                || $b->{ok_primers_count} <=> $a->{ok_primers_count}
            } @{$current_result->{qc_results}}
        ];
        
        push @final_results, $current_result;
    }

    # return the sorted results
    return [
        sort {
                 $a->{is_genomic}   <=> $b->{is_genomic}
              || $a->{design_plate} <=> $b->{design_plate}
              || $a->{design_well}  cmp $b->{design_well}
        } @final_results
    ];
}

sub _orientate_by_clone {
    [
        sort { $a->{construct_clone} cmp $b->{construct_clone} }
        map  { @{ $_->{qc_results} } } @{ $_[0] }
    ];
}

=head1 TODO

=over 4

=item Try a CPAN sort module

A number of sort modules exist on CPAN which are supposedly more efficient.
See L<http://search.cpan.org/search/?query=sort&mode=module> for some examples.

=back

=cut

1;
