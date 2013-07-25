package HTGT::Utils::ParseMutagenesisPredictionReports;

use Moose;
use Const::Fast;
use Path::Class;
use namespace::autoclean;

with qw( MooseX::Log::Log4perl );

const my $STATIC_FOLDER => '/software/team87/brave_new_world/data/misc';

sub get_gene_and_transcript_counts{
    my ( $self, $report_filename ) = @_;

    my $report_dir = dir($STATIC_FOLDER);
    my $report_file = $report_dir->file( $report_filename );
    my $report_fh = $report_file->openr();

    my ( %genes, %transcripts );
    while( my $report_row = $report_fh->getline() ){
        next if $report_row =~ /^Project ID/;

        my ( $ens_gene_id, $ens_transcript_id )
            = $report_row =~ /^.+,(ENSMUSG\d+),(ENSMUST\d+),/;
        $genes{$ens_gene_id}++;
        $transcripts{$ens_transcript_id}++;
    }

    return ( scalar keys %genes, scalar keys %transcripts );
}

__PACKAGE__->meta->make_immutable;
