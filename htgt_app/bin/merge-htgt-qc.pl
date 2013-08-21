#!/usr/bin/env perl
#
# $HeadURL$
# $LastChangedRevision$
# $LastChangedDate$
# $LastChangedBy$
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory::Lazy;
use List::MoreUtils qw( uniq );
use Log::Log4perl ':easy';
use CSV::Reader;
use CSV::Writer;

my $log_level = $WARN;

GetOptions(
    'help'       => sub { pod2usage( -verbose => 1 ) },
    'man'        => sub { pod2usage( -verbose => 2 ) },
    'debug'      => sub { $log_level = $DEBUG },
    'verbose'    => sub { $log_level = $INFO },
) and @ARGV == 1 or pod2usage(2);

Log::Log4perl->easy_init( { layout => '%m%n', level => $log_level } );

my $analysis_for = parse_analysis( shift @ARGV );

my $csv = CSV::Writer->new;

$csv->write( qw( plate_name well_name design valid_primers pass_level
                 my_design my_valid_primers my_alt_design my_alt_valid_primers ) );

for my $plate_name ( sort { $a cmp $b } uniq( keys %{$analysis_for} ) ) {
    my $plate = htgt->resultset( 'Plate' )->find(
        {
            name => $plate_name
        },
        {
            prefetch => { wells => 'design_instance' },
            order_by => 'wells.well_name'
        }
    ) or die "Failed to retrieve plate $plate_name";
    for my $well ( $plate->wells ) {
        my @primers = get_valid_primers_for_well( $well );
        $csv->write( $plate_name, $well->well_name, $well->design_instance->design_id,
                     join( q{,}, @primers ), $well->well_data_value( 'pass_level' ),
                     map { $_->{design_id}, $_->{valid_primers} }
                         @{ $analysis_for->{$plate_name}{$well->well_name} || [] } );
    }
}

sub get_valid_primers_for_well {
    my ( $well ) = @_;

    my $qctest_result_id = $well->well_data_value( 'qctest_result_id' );
    unless ( defined $qctest_result_id ) {
        WARN( "no QC test result id for $well" );
        return;
    }

    my $qctest_result = vector_qc->resultset( 'QctestResult' )->find(
        {
            qctest_result_id => $qctest_result_id
        }
    );

    unless ( $qctest_result ) {
        ERROR( "QC test result $qctest_result_id not found" );
        return;
    }

    my %valid_primers;

    foreach my $primer ( $qctest_result->qctestPrimers ) {
        my $seq_align_feature = $primer->seqAlignFeature
            or next;
        my $loc_status = $seq_align_feature->loc_status
            or next;
        $valid_primers{ uc( $primer->primer_name ) } = 1
            if $loc_status eq 'ok';
    }

    my @primers = sort keys %valid_primers;    
    
    DEBUG( "valid primers for $well: " . join( q{, }, @primers ) );

    return @primers;
}

sub parse_analysis {
    my $filename = shift;

    my $csv = CSV::Reader->new( input => $filename, use_header => 1 );

    my %results_for;

    # PG00244_Z_1f04.372464_L1L2_Bact_P#L3L4_pD223_DTA_T_spec

    while ( my $r = $csv->read ) {
        my ( $plate, $well, $di ) = $r->{TargetID} =~ m/^(.+)([a-z]\d\d)\.(\d+)_/
            or die "failed to parse target id: '$r->{TargetID}'";
        push @{ $results_for{ $plate }{ uc $well } },
            {
                design_id     => $di,
                valid_primers => join( q{,}, grep { $r->{$_} } qw( L1 LR PNF R3 ) ),
                pass          => $r->{pass} ? 'pass' : 'fail'
            };
    }

    return \%results_for;
}

__END__

=head1 NAME

fetch-htgt-qc.pl - Describe the usage of script briefly

=head1 SYNOPSIS

fetch-htgt-qc.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for fetch-htgt-qc.pl, 

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ray Miller

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
