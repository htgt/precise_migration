#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use Log::Log4perl ':easy';
use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use HTGT::Utils::UploadQCResults::Simple;
use HTGT::Utils::UploadQCResults::PIQ;
use HTGT::Utils::UploadQCResults::DnaPlates;
use Const::Fast;
use IO::File;
use Try::Tiny;
use HTGT::Constants qw( %QC_RESULT_TYPES );

my $loglevel = $INFO;
my $schema   = HTGT::DBFactory->connect('eucomm_vector');
const my $EDIT_USER => $ENV{'USER'};
my $skip_header;

GetOptions(
    'help'             => sub { pod2usage( -verbose => 1 ) },
    'man'              => sub { pod2usage( -verbose => 2 ) },
    'debug'            => sub { $loglevel = $DEBUG },
    'commit'           => \my $commit,
    'qc_result_type=s' => \my $qc_result_type,
    'skip_header'      => \$skip_header,
    'override'         => \my $override,
) and @ARGV == 1
    or pod2usage(2);

Log::Log4perl->easy_init( { level => $loglevel, layout => '%p %m%n' } );

my $input_file = IO::File->new( $ARGV[0], O_RDONLY );
die "Could not open input file: $ARGV[0]"  unless $input_file;

unless ($qc_result_type) {
    ERROR('Must specify a qc result type: ' . join ' ', keys %QC_RESULT_TYPES );
    pod2usage(2);
}

$schema->txn_do(
    sub {
        try {
            my $QC_Updater;
            if ( $qc_result_type =~ /piq/i ) {
                $QC_Updater = HTGT::Utils::UploadQCResults::PIQ->new(
                    schema         => $schema,
                    user           => $EDIT_USER,
                    input          => $input_file,
                    override       => $override ? 1 : 0,
                );
            }
            elsif ( $qc_result_type =~ /SBDNA|QPCRDNA/i ) {
                $QC_Updater = HTGT::Utils::UploadQCResults::DnaPlates->new(
                    schema         => $schema,
                    user           => $EDIT_USER,
                    input          => $input_file,
                    dna_plate_type => $qc_result_type,
                );

            }
            else {
                $QC_Updater = HTGT::Utils::UploadQCResults::Simple->new(
                    schema         => $schema,
                    user           => $EDIT_USER,
                    input          => $input_file,
                    qc_result_type => $qc_result_type,
                    skip_header    => $skip_header,
                );
            }

            $QC_Updater->parse_csv;
            $QC_Updater->update_qc_results;
            if ( $QC_Updater->has_errors ) {
                $schema->txn_rollback;
                map { ERROR($_) } @{ $QC_Updater->errors };
            }
            else {
                map { INFO($_) } @{ $QC_Updater->update_log };
                $schema->txn_rollback unless $commit;
            }
        }
        catch {
            $schema->txn_rollback;
            ERROR('Error uploading QC: ' . $_ );
            return;
        };
    }
);


__END__

=head1 NAME

load_qc_results.pl load qc results into well data

=head1 SYNOPSIS

 load_qc_results.pl [options] input-file

      --help              Display a brief help message
      --man               Display the manual page
      --debug             Print debug messages
      --commit            Commit results to database
      --qc_result_type=s  Type of qc result you are uploading (required)
      --skip_header       Remove first line of csv
      --override          Ignore certain data checks, piq results only

Possibly qc_result_types:

=over

=item

piq

=item

SBDNA

=item

QPCRDNA

=item

LOA

=item

LoxP_Taqman

=back

For details on the type of data required for each result type see here:
http://www.sanger.ac.uk/htgt/qc/update/update_qc_results

=head1 WARNING

The override option must be used with caution, it skips the check that stops a worse result replacing a better one.

Also it does not check for required fields so you could create a mismatch bewteen a qc result and its associated data.

=head1 DESCRIPTION

Load qc results 

=head1 AUTHOR

Sajith Perera

=head1 BUGS

None reported... yet.

=cut
