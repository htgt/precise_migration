#!/usr/bin/env perl
#
# XXX This script should be integrated into the QC system as an action.
#

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::FetchHTGTEngSeqParams;

use HTGT::DBFactory;
use HTGT::QC::Exception;
use Getopt::Long;
use YAML::Any;
use Log::Log4perl qw( :easy );

my $log_level = $WARN;

GetOptions(
    'debug'    => sub { $log_level = $DEBUG },
    'verbose'  => sub { $log_level = $INFO },
    'target=s' => \my $target_plate_type,
    'stage=s'  => \my $stage,
    'dir'      => \my $dirname
) and @ARGV == 1 or die "Usage: $0 [OPTIONS] PLATE_NAME\n";

die "--stage not specified\n"
    unless defined $stage;

Log::Log4perl->easy_init( $log_level );

my $plate_name = shift @ARGV;

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my $plate = $htgt->resultset('Plate')->find( { name => $plate_name } )
    or die "Failed to retrieve plate $plate_name\n";

my @plates;

if ( $target_plate_type ) {
    my %seen;
    @plates = grep { ! $seen{$_->plate_id}++ } get_target_plates( $plate, $target_plate_type );
}
else {
    push @plates, $plate;
}

DEBUG( 'Retrieving engineered sequences from: ' . join( q{, }, @plates ) );

my %params;

for my $plate ( @plates ) {
    my $this_plate_params = fetch_htgt_eng_seq_params( $plate, $stage );
    for my $p ( @{$this_plate_params} ) {
        $params{ $p->{well_name} } = $p;
    }    
}

print YAML::Any::Dump( { wells => \%params } );

sub get_target_plates {
    my ( $plate, $type ) = @_;

    if ( $plate->type eq $type ) {
        return $plate;
    }

    my %parent_plates;
    for my $well ( $plate->wells ) {
        my $parent_well = $well->parent_well
            or next;
        my $parent_plate = $parent_well->plate;
        $parent_plates{$parent_plate->plate_id} = $parent_plate;
    }

    return map { get_target_plates( $_, $type ) } values %parent_plates;
}
