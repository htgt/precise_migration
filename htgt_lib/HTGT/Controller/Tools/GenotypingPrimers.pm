package HTGT::Controller::Tools::GenotypingPrimers;
use Moose;
use Const::Fast;
use JSON qw( to_json );
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

HTGT::Controller::Tools::GenotypingPrimers - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 CONSTANTS

=cut

=head2 $SELECT_FEATURES_SQL

Query to retrieve genotyping primers from the features for a given design

=cut

const my $SELECT_FEATURES_SQL => <<'EOT';
select feature_type_dict.description, feature_data.data_item
from design
join feature on feature.design_id = design.design_id
join feature_type_dict on feature_type_dict.feature_type_id = feature.feature_type_id
join feature_data on feature_data.feature_id = feature.feature_id
join feature_data_type_dict on feature_data_type_dict.feature_data_type_id = feature_data.feature_data_type_id
where design.design_id  = ?
and feature_type_dict.description in ( 'GF1', 'GF2', 'GF3', 'GF4', 'GR1', 'GR2', 'GR3', 'GR4' )
and feature_data_type_dict.description = 'sequence'
order by feature_type_dict.description
EOT

=head2 $SELECT_MIRKO_FEATURES_SQL

Query to retrieve genotyping primers from the features for a given mirKO design

=cut

const my $SELECT_MIRKO_FEATURES_SQL => <<'EOT';
select feature_type_dict.description, feature_data.data_item
from design
join feature on feature.design_id = design.design_id
join feature_type_dict on feature_type_dict.feature_type_id = feature.feature_type_id
join feature_data on feature_data.feature_id = feature.feature_id
join feature_data_type_dict on feature_data_type_dict.feature_data_type_id = feature_data.feature_data_type_id
where design.design_id  = ?
and feature_type_dict.description in ( 'GF1', 'GR1', 'LAR', 'RAF' )
and feature_data_type_dict.description = 'sequence'
order by feature_type_dict.description
EOT

=head2 %UNIVERSAL_PRIMERS

=cut

const my %UNIVERSAL_PRIMERS => (
    LAR3 => 'CACAACGGGTTCTTCTGTTAGTCC',
    RAF5 => 'CACACCTCCCCCTGAACCTGAAAC',
    PNF  => 'ATCCGGGGGTACCGCGTCGAG',
    R2R  => 'TCTATAGTCGCAGTAGGCGG',   
);

=head2 %UNIVERSAL_PRIMERS

=cut

const my %UNIVERSAL_MIRKO_PRIMERS => (
    LAR => 'ATAGCATACATTATACGAAGTTATCACTGG', #LR2
    RAF => 'TCTAGAAAGTATAGGAACTTCCATGGTC',  #LR3
);

=head1 METHODS

=cut

=head2 index

Given a project_id, retrieve the design for that project and return
the LR PCR genotyping primers as a JSON hash.

=cut

sub index :Path :Args(1) {
    my ( $self, $c, $project_id ) = @_;

    if ( $project_id !~ /^\d+$/ ) {
        $c->detach( 'error', [ "Invalid project_id: '$project_id'" ] );
    }

    my $project = $c->model( 'HTGTDB::Project' )->find( { project_id => $project_id } );

    if ( ! $project ) {
        $c->detach( 'error', [ "Failed to retrieve project $project_id" ] );
    }

    if ( ! $project->design_id ) {
        $c->detach( 'error', [ "Project $project_id has no design attached" ] );        
    }
   
    my $primers = $c->model( 'HTGTDB' )->storage->dbh_do(
        sub {
            $_[1]->selectall_arrayref( $SELECT_FEATURES_SQL, undef, $project->design_id );            
        }
    );

    my %primers = ( %UNIVERSAL_PRIMERS, map @{$_}, @{$primers} );
    
    $c->response->content_type( 'application/json' );
    $c->response->body( to_json( \%primers ) );
}

sub mirko_primers :Local :Args(1) {
    my ( $self, $c, $design_id ) = @_;

    if ( $design_id !~ /^\d+$/ ) {
        $c->detach( 'error', [ "Invalid design_id: '$design_id'" ] );
    }

    my $primers = $c->model( 'HTGTDB' )->storage->dbh_do(
        sub {
            $_[1]->selectall_arrayref( $SELECT_MIRKO_FEATURES_SQL, undef, $design_id );            
        }
    );
    my %mirko_primers;
    for my $primer ( @{ $primers } ) {
        $mirko_primers{ $primer->[0] } = $primer->[1];
    }
    $mirko_primers{LAR} = $UNIVERSAL_MIRKO_PRIMERS{LAR} unless exists $mirko_primers{LAR};
    $mirko_primers{RAF} = $UNIVERSAL_MIRKO_PRIMERS{RAF} unless exists $mirko_primers{RAF};
    
    $c->response->content_type( 'application/json' );
    $c->response->body( to_json( \%mirko_primers ) );
}   

sub error :Private {
    my ( $self, $c, $mesg ) = @_;

    $c->log->error( $mesg );    
    $c->response->content_type( 'application/json' );    
    $c->response->body( to_json( { error => $mesg } ) );
    $c->response->status( 500 );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

