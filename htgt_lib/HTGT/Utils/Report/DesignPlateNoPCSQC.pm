package HTGT::Utils::Report::DesignPlateNoPCSQC;

use strict;
use warnings FATAL => 'all';

use Moose;
use Iterator;
use Iterator::Util qw( imap igrep );
use List::MoreUtils qw( uniq any );
use namespace::autoclean;

with 'HTGT::Utils::Report::GenericIterator';

sub _build_table_id {
    "design_plate_no_pcs_qc"
}

sub _build_name {
    "Design Plates with no PCS QC"
}

sub _build_preamble {
    "This report lists design plates with no child PCS plates stamped 'qc_done'";
}

sub _build_columns {
    [ qw( design_plate sponsors pcs_plates ) ]
}

sub _build_iterator {
    my $self = shift;

    my $design_plates = $self->schema->resultset( 'Plate' )->search_rs(
        {
            type => 'DESIGN'
        },
        {
            order_by => \"lpad(name, 10)"
        }            
    );
    
    my $it = Iterator->new(
        sub {
            $design_plates->next or Iterator::is_done;
        }
    );

    imap { $self->_to_href( $_ ) } igrep { $self->_has_no_qc_done_pcs( $_ ) } $it;
}

sub _has_no_qc_done_pcs {
    my ( $self, $design_plate ) = @_;

    return unless $design_plate->wells > 0;

    my $has_pcs_qc = any { $_->plate_data_value( 'qc_done' ) } $design_plate->child_plates;

    return not $has_pcs_qc;
}        

sub _to_href {
    my ( $self, $design_plate ) = @_;

    return {
        design_plate => $design_plate->name,
        sponsors     => $self->_sponsors_for( $design_plate ),
        pcs_plates   => join( q{,}, map $_->name, $design_plate->child_plates ),
    };    
}

sub _sponsors_for {
    my ( $self, $design_plate ) = @_;

    my @sponsors;
    
    for my $well ( $design_plate->wells ) {
        next unless $well->design_instance_id;
        my @projects = $self->schema->resultset( 'Project' )->search(
            {
                design_instance_id => $well->design_instance_id
            }
        );
        push @sponsors, map $_->sponsor, @projects;
    }

    join( '/', uniq @sponsors );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
