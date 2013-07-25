package HTGT::Utils::Recovery::Report::GatewayDistributeSummary;

use Moose;
use namespace::autoclean;
use Iterator;
use HTGT::Utils::Recovery::Report::GatewayDistribute;

with qw( HTGT::Utils::Report::GenericIterator MooseX::Log::Log4perl );

sub _build_name {
    'Gateway Recovery Distributable Vectors Summary'
}

sub _build_columns {
    [ qw( recovery_plate num_unique num_duplicate unique duplicate ) ]
}

sub _build_iterator {
    my $self = shift;

    my $it = HTGT::Utils::Recovery::Report::GatewayDistribute->new( schema => $self->schema );

    my $next_record = sub {
        if ( $it->has_next ) {
            return $it->next_record;
        }
        return;
    };
    
    my $record = $next_record->();
    
    return Iterator->new(
        sub {
            Iterator::is_done unless $record;
            my $plate = $record->{recovery_plate};
            my @plate_data = ( $record );
            while ( $record = $next_record->() and $record->{recovery_plate} eq $plate ) {
                push @plate_data, $record;
            }
            my @uniq = map $_->{marker_symbol}, grep  $_->{unique_to_plate}, @plate_data;
            my @dup  = map $_->{marker_symbol}, grep !$_->{unique_to_plate}, @plate_data;
            return {
                recovery_plate => $plate,
                num_unique     => scalar @uniq,
                num_duplicate  => scalar @dup,
                unique         => join( q{, }, @uniq ),
                duplicate      => join( q{, }, @dup )
            };
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
