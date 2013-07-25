package HTGT::Utils::DesignCheckRole;

=head1 NAME

HTGT::Utils::DesignCheckRole

=head1 DESCRIPTION

This role is consumed by all the specific check modules.

=cut

use Moose::Role;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';
requires '_build_checks';

has design => (
    is  => 'ro',
    isa => 'HTGTDB::Design',
);

has target_slice => (
    is  => 'ro',
    isa => 'Maybe[Bio::EnsEMBL::Slice]',
);

has status_notes => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    default => sub { [] },
    handles => {
        add_note    => 'push',
        join_notes  => 'join',
        clear_notes => 'clear',
    }
);

has design_annotation => (
    is  => 'ro',
    isa => 'Maybe[HTGTDB::DesignAnnotation]',
);

has valid => (
    is      => 'ro',
    isa     => 'Bool',
    traits  => ['Bool'],
    default => 0,
    handles => {
        set_status_valid   => 'set',
    }
);

has status => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_status',
    clearer   => 'unset_status', #for override
);

has check_type => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

has status_field => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_status_field {
    shift->check_type . '_status_id';
}

has status_notes_field => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_status_notes_field {
    shift->check_type . '_status_notes';
}

#this will be implemented by a subclass
has checks => (
    traits     => [ 'Array' ],
    is         => 'ro',
    isa        => 'ArrayRef[Str]',
    lazy_build => 1,
    handles    => {
        get_checks => 'elements'
    }
);

=head2 update_design_annotation_status

The method that should be called first on all the design checker modules.
It updates the design annotation if required. 
Returns true of all the checks pass.

=cut
sub update_design_annotation_status {
    my $self = shift;

    #this sets the status
    $self->check_status;

    unless ( $self->status ) {
        $self->log->error( 'Status not set for '. $self->check_type );
        return;
    }

    $self->log->info( 'The ' . $self->check_type . ' status is: ' . $self->status );
    $self->log->debug( $_ ) for @{ $self->status_notes };

    return $self->valid;
}

=head2 check_status

Get all the checks available to the subclass currently inheriting this role and run them.
If they're all successful the overall status for this type is set to valid.

=cut
sub check_status {
    my ( $self ) = @_;
    
    my $display_name = $self->get_current_classname;

    #now perform all the checks.
    for my $check ( $self->get_checks ) {
        $self->log->info("Checking $display_name: $check");
        next if $self->$check;

        #if the test didn't pass see if there's an override, if not return
        return unless $self->current_status_is_overriden;
    }

    $self->log->info("$display_name Checks PASSED");
    $self->is_valid;

    return 1;
}

=head2 get_current_classname

Return the current subclass name, needed so we can print which checks are being run

=cut
sub get_current_classname {
    my $self = shift;

    #convert to a display name, e.g. artificial_intron -> Artificial Intron
    my @words = map { ucfirst } split "_", $self->check_type;

    #we might want the actual words or as a string
    return wantarray ? @words : join " ", @words;
}


=head2 current_status_is_overriden

Determine if the currently set status has been marked as overridden by a human. 
Intended to be called after at least one of the checks has been run

=cut
sub current_status_is_overriden {
    my ( $self ) = shift;

    #if $self->status isn't set yet this will return false

    #make sure we actually got a design annotation as it's optional
    unless ( defined $self->design_annotation ) {
        $self->log->warn( 'No design annotation provided, skipping override checks.' );
        return;
    }

    #see if any human annotations are attached to this design
    my @human_annotations = $self->design_annotation->human_annotations;

    $self->log->info( 'Found ' . scalar @human_annotations . ' human annotations' );

    return unless @human_annotations;

    #if so, does the override status have overrides relevant to our class
    for my $ha ( @human_annotations ) {
        #if its not an override entry then skip it.
        next unless $ha->human_annotation_status->override;

        #make the db field name, e.g. artificial_intron_status
        my $field = lc( $self->check_type . '_status' );
        $self->log->debug( "Field determined to be $field" );

        #see if there's a definition for this set of checks, and if not try the next annotation
        next unless defined $ha->human_annotation_status->$field;
        
        #if so, does that override status match $self->status? 
        if ( $ha->human_annotation_status->$field->id eq $self->status ) {
            $self->log->info( $self->status . ' overridden by human annotation.' );
            #we basically pretend we didn't set the status or any notes
            $self->unset_status; 
            $self->clear_notes;
            
            return 1; #we've determined this status to be overridden, so return true
        }
    }

    $self->log->info( 'No override found for ' . $self->status );

    return;
}

=head2 set_status

Sets the status for the check module, also takes optional arrayref of notes.

=cut
sub set_status {
    my ( $self, $status, $notes ) = @_;

    # Check we have not already set a status
    die('We already have a status of ' . $self->status . ' can not set to new status ' . $status )
        if $self->has_status;

    $self->status( $status );

    if ( $notes ) {
        $self->add_note( $_ ) for @{ $notes };
    }
}

=head2 is_valid

Sets the status to 'valid' and the valid attribute to true 

=cut
sub is_valid {
    my $self = shift;

    $self->set_status_valid;
    $self->set_status( 'valid' );
}

1;

__END__
