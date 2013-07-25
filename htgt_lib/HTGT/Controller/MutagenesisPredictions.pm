package HTGT::Controller::MutagenesisPredictions;
use Moose;
use HTGT::Utils::ParseMutagenesisPredictionReports;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

HTGT::Controller::MutagenesisPredictions - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 view

=cut

sub view :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $parser = HTGT::Utils::ParseMutagenesisPredictionReports->new;

    my ( $full_gc, $full_tc )
        = $parser->get_gene_and_transcript_counts('plated-designs-mp-report.csv');
    my ( $main_fail_gc, $main_fail_tc )
        = $parser->get_gene_and_transcript_counts('plated-designs-main-transcript-fails.csv');
    my ( $pc_fail_gc, $pc_fail_tc )
        = $parser->get_gene_and_transcript_counts('plated-designs-protein-coding-fails.csv');
    my ( $all_fail_gc, $all_fail_tc )
        = $parser->get_gene_and_transcript_counts('plated-designs-transcript-fails.csv');

    $c->stash( full_gc => $full_gc );
    $c->stash( full_tc => $full_tc );
    $c->stash( main_fail_gc => $main_fail_gc );
    $c->stash( main_fail_tc => $main_fail_tc );
    $c->stash( pc_fail_gc => $pc_fail_gc );
    $c->stash( pc_fail_tc => $pc_fail_tc );
    $c->stash( all_fail_gc => $all_fail_gc );
    $c->stash( all_fail_tc => $all_fail_tc );
    $c->stash( template => 'mutagenesispredictions/view.tt' );
}



=head1 AUTHOR

Mark Quinton-Tulloch

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

