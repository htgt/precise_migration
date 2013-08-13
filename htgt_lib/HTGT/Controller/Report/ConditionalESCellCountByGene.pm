package HTGT::Controller::Report::ConditionalESCellCountByGene;
use Moose;
use Const::Fast;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

const my $MAX_GENE_IDS => 500;

#my @GENE_ID_TYPES => (
#    [ qr/OTT\w+/  => 'vega_gene_id'     ],
#    [ qr/ENS\w+/  => 'ensembl_gene_id'  ],
#    [ qr/MGI:\d+/ => 'mgi_accession_id' ],
#    [ qr/[\w-]+/  => 'marker_symbol'    ]
#);
my @GENE_ID_TYPES = (
    [ qr/OTT\w+/  => 'vega_gene_id'     ],
    [ qr/ENS\w+/  => 'ensembl_gene_id'  ],
    [ qr/MGI:\d+/ => 'mgi_accession_id' ],
    [ qr/[\w-]+/  => 'marker_symbol'    ]
);

const my $QUERY_TMPL => <<'EOT';
select mgi_gene.marker_symbol, mgi_gene.ensembl_gene_id, mgi_gene.mgi_accession_id, mgi_gene.vega_gene_id,
  count(distinct well.well_id) as conditional_es_cell_count
from mgi_gene
join project
  on project.mgi_gene_id = mgi_gene.mgi_gene_id
join well
  on well.design_instance_id = project.design_instance_id
join plate
  on plate.plate_id = well.plate_id
  and plate.type = 'EPD'
join well_data
  on well_data.well_id = well.well_id
  and well_data.data_type = 'distribute'
  and well_data.data_value = 'yes'
where
( %s )
group by mgi_gene.marker_symbol, mgi_gene.ensembl_gene_id, mgi_gene.mgi_accession_id, mgi_gene.vega_gene_id
order by mgi_gene.marker_symbol
EOT

=head1 NAME

HTGT::Controller::Report::ConditionalESCellCountByGene - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

Render a blank template unless the I<show_results> parameter is set,
in which case parse the gene identifiers, query the database, and
populate the stash with the returned column names and data.

=cut

sub index :Path( '/report/conditional_es_cell_count_by_gene' ) :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{max_gene_ids} = $MAX_GENE_IDS;
    $c->stash->{template} = 'report/conditional_es_cell_count_by_gene/index.tt';
    
    return unless $c->request->param( 'show_results' );
    
    my $genes = $self->_parse_gene_ids( $c->request->param( 'gene_identifiers' ) );
    unless ( defined $genes and keys %{$genes} ) {
        $c->stash->{error_msg} = "Please list the genes to include in this report";
        return;
    }

    my ( $query, $placeholders ) = $self->_build_dist_es_cell_query( $genes );
    if ( @{$placeholders} > $MAX_GENE_IDS ) {
        $c->stash->{error_msg} = "At most $MAX_GENE_IDS gene identifiers may be entered";
        return;        
    }

    if ( $c->request->param( 'view' ) || '' eq 'csvdl' ) {
        $c->stash->{template} = 'report/conditional_es_cell_count_by_gene/csv.tt';
    }
    
    $c->model( 'HTGTDB' )->storage->dbh_do(
        sub {
            my $sth = $_[1]->prepare( $query );
            $sth->execute( @{$placeholders} );
            $c->stash->{data}    = $sth->fetchall_arrayref;
            $c->stash->{columns} = $sth->{NAME_uc};
        }
    );

    return;
}

=head2 _build_dist_es_cell_query

Build the SQL to count the number of distributable ES cells per gene.
Interpolates into the template C<$QUERY_TMPL> a WHERE clause to limit
the search to the genes specified by the user. Returns the SQL as a
string and a reference to the list of placeholders.

=cut

sub _build_dist_es_cell_query {
    my ( $self, $genes ) = @_;

    my ( @where, @placeholders );    
    for my $column ( sort keys %{$genes} ) {
        my @values = @{ $genes->{$column} };
        push @where, sprintf( 'mgi_gene.%s in ( %s )', $column, join( q{, }, ( '?' ) x @values ) );
        push @placeholders, @values;
    }

    my $query = sprintf( $QUERY_TMPL, join( "\nor ", @where ) );

    return ( $query, \@placeholders );
}


=head2 _parse_gene_ids

Parse a list of gene ids from text entered by the user. Group
according to type (Ensembl, Vega, MGI or marker symbol). Returns a
hash keyed on identifier type.

=cut

sub _parse_gene_ids {
    my ( $self, $text ) = @_;

    return unless $text;

    my %parsed;

    my @identifiers = $text =~ m/([\w:-]+)/smg;

    for my $id ( @identifiers ) {
        for my $gene_id_type ( @GENE_ID_TYPES ) {
            my ( $rx, $type ) = @{ $gene_id_type };
            if ( $id =~ $rx ) {
                push @{ $parsed{$type} }, $id;
                last;
            }
        }
    }
    
    return \%parsed;
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

__END__
