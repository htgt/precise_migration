#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Getopt::Long;
use Log::Log4perl ':easy';
use IO::File;
use Pod::Usage;
use HTGT::Utils::TaqMan::Design;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

{
    my $log_level = $WARN;
    my ( $target, $sequence, $include_duplicates );
    GetOptions(
        'help'                => sub { pod2usage( -verbose => 1 ) },
        'man'                 => sub { pod2usage( -verbose => 2 ) },
        'debug'               => sub { $log_level = $DEBUG },
        'target=s'            => \$target,
        'sequence'            => \$sequence,
        'include-duplicates!' => \$include_duplicates
    ) and @ARGV == 1
        or pod2usage(2);

    Log::Log4perl->easy_init( { level => $log_level, layout => '%p %m%n' } );

    my $input_file = IO::File->new( $ARGV[0] );

    my $taqman = HTGT::Utils::TaqMan::Design->new(
        schema             => HTGT::DBFactory->connect('eucomm_vector'),
        target             => $target,
        sequence           => $sequence ? 1 : 0,
        include_duplicates => $include_duplicates ? 1 : 0,
        input_file         => $input_file,
    );

    my $zip = $taqman->create_zip_file;

    my $fh = IO::File->new( 'taqman_design_info.zip', 'w' )
        or die "Failed to create zip file: $!";

    unless ( $zip->writeToFileHandle($fh) == AZ_OK ) {
        die "Unable to write zip archive to filehandle: $!";
    }
}

__END__

=head1 NAME

get_taqman_design_info.pl - get information needed to create taqman primers for specific designs

=head1 SYNOPSIS

get_taqman_design_info.pl [options] input-file

      --help            Display help page
      --debug           Show debug logging
      --man             Display the manual page
      --input=s         Specify individual design id or gene
      --target=s        The target region of the design (critical or deleted)
      --sequence        Output sequence information instead of coordinates
      --include-duplicates! Don't ignore designs which already have taqman assays for that target

Target region can be critical ( U3 to D5 ) or deleted ( between U's and between D's )
Input-file is a file that is required unless the --input option is specified on command line, the
file must have design_id, mgi_accession_id or marker_symbol on each line.

=head1 DESCRIPTION

Takes in design_id's, mgi_accession_ids or gene marker symbols as input (as command line option, file or command
line argument). Outputs csv file(s) with deleted or critical region
coordinates, if sequence option specified then sequences are outputed instead of coordinates.

=head1 AUTHOR

Sajith Perera

=head1 BUGS

None reported... yet.

=headl TODO


=cut
