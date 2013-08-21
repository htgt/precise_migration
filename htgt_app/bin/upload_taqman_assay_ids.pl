#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Getopt::Long;
use Log::Log4perl ':easy';
use Pod::Usage;
use HTGT::Utils::TaqMan::Upload;
use Try::Tiny;
use IO::File;

my $log_level = $INFO;
my $commit;
GetOptions(
    'debug'   => sub { $log_level = $DEBUG },
    'help'    => sub { pod2usage( -verbose => 1 ) },
    'man'     => sub { pod2usage( -verbose => 2 ) },
    'plate=s' => \my $plate,
    'commit'  => \$commit,
) and @ARGV == 1
    or pod2usage(2);

pod2usage(2) unless $plate;
Log::Log4perl->easy_init( { level => $log_level, layout => '%p %m%n' } );
my $schema = HTGT::DBFactory->connect('eucomm_vector');

my $csv_file = IO::File->new( $ARGV[0] );

$schema->txn_do(
    sub {
        try{
            my $taqman_upload = HTGT::Utils::TaqMan::Upload->new(
                schema        => $schema,
                csv_filename  => $csv_file,
                user          => $ENV{'USER'},
                plate_name    => $plate,
            );

            if ( $taqman_upload->has_errors ) {
                $schema->txn_rollback;
                ERROR('Rolling back changes, have following errors');
                map { ERROR($_) } @{ $taqman_upload->errors };
            }
            else {
                map { INFO($_) } @{ $taqman_upload->update_log };
                unless ( $commit ) {
                    INFO('Rolling back changes, script run in non-commit mode');
                    $schema->txn_rollback;
                }
            }
        }
        catch {
            $schema->txn_rollback;
            ERROR('Error uploading taqman data: ' . $_ );
        };
    }
);


__END__

=head1 NAME

upload_taqman_assay_ids.pl -

=head1 SYNOPSIS

upload_taqman_assay_ids.pl [options] input-file

      --debug           Show debug level log messages
      --help            Display help page
      --man             Display the manual page
      --plate=s         Name of plate assays stored in
      --commit          Run program in commit mode

Input-file is a csv file that is required, must have design_id, well_name, design_region and assay_id column
Option fields are: forward_primer_seq, reverse_primer_seq and reporter_primer_seq
Plate is required field, the wells are stored in the csv file

=head1 DESCRIPTION

Take in a csv file with taqman assay information linked to design ids and uploads this information
into htgt.

=head1 AUTHOR

Sajith Perera

=head1 BUGS

None reported... yet.

=headl TODO


=cut
