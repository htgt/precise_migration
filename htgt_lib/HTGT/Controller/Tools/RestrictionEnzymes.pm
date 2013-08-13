package HTGT::Controller::Tools::RestrictionEnzymes;
use Moose;
use namespace::autoclean;
use HTGT::Utils::SouthernBlot;
use Const::Fast;
use Try::Tiny;
use UNIVERSAL;

BEGIN {extends 'Catalyst::Controller'; }

my $VALID_CLONE_NAME_RX = qr/^\w+$/;
my $VALID_FRAG_SIZE_RX  = qr/^\d+$/;
my $VALID_TOLERANCE_RX  = qr/^\d{1,2}$/;

const my %VALID_PROBES        => (
    NeoR  => "Probe to Neo",
    LacZ3 => "Probe to 3' half of LacZ",
    LacZ5 => "Probe to 5' half of LacZ"
);

=head1 NAME

HTGT::Controller::Tools::RestrictionEnzymes - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $es_clone_name     = $self->get_param( $c, 'es_clone_name', '' );
    my $max_fragment_size = $self->get_param( $c, 'max_fragment_size', 0 );
    my $tolerance         = $self->get_param( $c, 'tolerance', 25 );
    my $probe             = $self->get_param( $c, 'probe', 'NeoR' );

    # Re-populate the stash in case of error return
    $c->stash->{es_clone_name}     = $es_clone_name;
    $c->stash->{max_fragment_size} = $max_fragment_size;
    $c->stash->{tolerance}         = $tolerance;
    $c->stash->{probes}            = $self->init_probes( $c, $probe );

    return unless $c->req->param( 'find_restriction_enzymes' );
    
    unless ( $es_clone_name =~ $VALID_CLONE_NAME_RX ) {
        $c->stash->{error_msg} = "Invalid ES clone name: '$es_clone_name'";
        return;
    }

    unless ( $max_fragment_size =~ $VALID_FRAG_SIZE_RX ) {
        $c->stash->{error_msg} = "Invalid max fragment size: '$max_fragment_size'";
        return;        
    }

    unless ( $tolerance =~ $VALID_TOLERANCE_RX and $tolerance >= 0 and $tolerance < 100 ) {
        $c->stash->{error_msg} = "Invalid tolerance: '$tolerance'";
        return;
    }

    unless ( $VALID_PROBES{ $probe } ) {
        $c->stash->{error_msg} = "Invalid probe: '$probe'";
        return;
    }
    
    try {
        my $sb = HTGT::Utils::SouthernBlot->new(
            es_clone_name     => $es_clone_name,
            max_fragment_size => $max_fragment_size,
            tolerance_pct     => $tolerance,
            probe             => $probe
        );
        $c->stash->{show_results}   = 1;
        $c->stash->{probe_desc}     = $VALID_PROBES{$probe};
        $c->stash->{fivep_enzymes}  = $sb->fivep_enzymes;
        $c->stash->{threep_enzymes} = $sb->threep_enzymes;
        $self->audit( $c );        
    }
    catch {       
        $c->stash->{error_msg} = UNIVERSAL::isa( $_, 'Throwable::Error' ) ? $_->message : $_;
        delete $c->stash->{fivep_enzymes};
        delete $c->stash->{threep_enzymes};
    };
}

sub get_param {
    my ( $self, $c, $param_name, $default_value ) = @_;

    my $param_value = $c->req->param( $param_name );

    $param_value = $default_value
        unless defined $param_value;

    # Trim whitespace
    for ( $param_value ) {
        s/^\s+//;
        s/\s+$//;
    }

    return $param_value;
}

sub init_probes {
    my ( $self, $c, $probe ) = @_;

    my @probes;
    for ( sort keys %VALID_PROBES ) {
        push @probes, {
            name    => $_,
            desc    => $VALID_PROBES{$_},
            checked => $_ eq $probe ? "checked" : undef
        };        
    }

    return \@probes;    
}

sub audit {
    my ( $self, $c ) = @_;

    $c->audit_info( join ',',
                    $c->stash->{probe_desc},
                    $c->stash->{es_clone_name},
                    $self->_enzyme_info( "5'", $c->stash->{fivep_enzymes}->[0] ),
                    $self->_enzyme_info( "3'", $c->stash->{threep_enzymes}->[0] )
                );
}

sub _enzyme_info {
    my ( $self, $desc, $enzyme ) = @_;

    return '<undef>' unless defined $enzyme;

    sprintf( '%s enzyme=%s (preferred=%s, fragment_size=%s, cuts_in_probe=%s)',
             $desc,
             $enzyme->{enzyme},
             $enzyme->{is_preferred},
             $enzyme->{fragment_size},
             $enzyme->{distance_probe_num} < 0 ? 'yes' : 'no' );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

