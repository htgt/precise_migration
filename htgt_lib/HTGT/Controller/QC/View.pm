package HTGT::Controller::QC::View;

use Moose;
use namespace::autoclean;
use Bio::Seq;
use Bio::SeqIO;
use IO::String;

BEGIN {
    extends 'Catalyst::Controller';
}

=head1 NAME

HTGT::Controller::QC::View - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->redirect('/welcome');

}

=head2 cloneseq

Grabs sequence data from qc_seqread table for given construct clones
Outputs as plain text file in browser in Fasta, GenBank or GCG format

=cut

sub cloneseq : Local {
    my ( $self, $c ) = @_;

    #Grab construct_clone id parameter from url and test it exists and is valid
    my $construct_clone_id = $self->_checkID( $c, 'construct_clone' );

    #Grab file format
    my $file_format = $self->_checkfileformat($c);

    #Make sure construct_clone id exists in construct clone table
    my $construct_clone
        = $c->model('ConstructQC::ConstructClone')->find( { construct_clone_id => $construct_clone_id } );
    unless ($construct_clone) {
        $c->stash->{error_msg} = "Construct Clone not found: $construct_clone_id";
        $c->detach('/welcome');
    }

    #Grab sequences that matches to construct_clone_id, error if no matches
    my @seqreads = $c->model('ConstructQC::QcSeqread')->search( { construct_clone_id => $construct_clone_id } );

    my $sequences = '';

    #Loop through sequences and place in string
    for my $seqread (@seqreads) {
        my $seq_string = $self->_seq2file( $seqread->sequence, $seqread->read_name, $file_format );
        $sequences .= $seq_string if $seq_string;
    }

    #If not sequence data found return error
    unless ($sequences) {
        $c->stash->{error_msg} = "Sequence data not found for Construct Clone: $construct_clone_id";
        $c->detach('/welcome');
    }

    #Display sequence data as a plain text file in browser
    $c->response->content_type('text/plain');
    $c->response->body($sequences);
}

=head2 seq_read

Grabs sequence data from qc_seqread table and outputs as fasta/genbank/gcg plain text file in browser

=cut

sub seq_read : Local {
    my ( $self, $c ) = @_;

    #Grab seqread_id parameter from url and test it exists and is valid
    my $seqread_id = $self->_checkID( $c, 'seq_read' );

    #Grab file format
    my $file_format = $self->_checkfileformat($c);

    #Make sure seqread_id exists in qc_seqread table
    my $seqread = $c->model('ConstructQC::QcSeqread')->find( { seqread_id => $seqread_id } );
    unless ($seqread) {
        $c->stash->{error_msg} = "Sequence read not found $seqread_id";
        $c->detach('/welcome');
    }

    #check sequence available for seqread_id
    unless ( $seqread->sequence ) {
        $c->stash->{error_msg} = "No sequence attached to seq_read $seqread_id";
        $c->detach('/welcome');
    }

    #Call subroutine to create fasta string of sequence
    my $seq_str = $self->_seq2file( $seqread->sequence, $seqread->read_name, $file_format );

    #Check sequence string has been created
    unless ($seq_str) {
        $c->stash->{error_msg} = "Unable to create Fasta sequence string for $seqread_id";
        $c->detach('/welcome');
    }

    #Display fasta string as a plain text file in browser
    $c->response->content_type('text/plain');
    $c->response->body($seq_str);
}

#Check ID
sub _checkID {
    my ( $self, $c, $type ) = @_;

    #Grab seqread_id parameter from url and test it exists and is valid
    my $ID = $c->request->param('id');
    unless ( $ID and $ID =~ /^\d+$/ ) {
        $c->stash->{error_msg} = "Missing or invalid $type id";
        $c->detach('/welcome');
    }
    return ($ID);
}

#Check File Format
sub _checkfileformat {
    my ( $self, $c) = @_;

    #Grab file format from url and check it exists and is valid
    my $file_format = $c->request->param('format');
    if ( !$file_format ) {
        $file_format = 'Fasta';
    }
    elsif ( $file_format !~ m/^Fasta$|^GCG$|^GenBank$/i ) {
        $c->stash->{error_msg} = "Invalid file format: $file_format, Must be Fasta, GenBank or GCG.";
        $c->detach('/welcome');
    }
    return ($file_format);
}

#Converts given sequence into fasta format
sub _seq2file {
    my ( $self, $seq_str, $display_id, $format ) = @_;

    return unless $seq_str;

    my $file_str;    # output

    #Create new Bio::Seq object sequence name (id) and sequence
    my $bio_seq = Bio::Seq->new( -seq => $seq_str, -display_id => $display_id );

    #Create Bio:Seq file handle from $file_str variable
    my $seq_io = Bio::SeqIO->new( -format => $format, -fh => IO::String->new($file_str) );

    #Write bio_seq object into bio_seq file handle
    $seq_io->write_seq($bio_seq);

    return $file_str;
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

