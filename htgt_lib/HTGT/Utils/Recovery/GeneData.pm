package HTGT::Utils::Recovery::GeneData;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-recovery/trunk/lib/HTGT/Utils/Recovery/GeneData.pm $
# $LastChangedRevision: 4103 $
# $LastChangedDate: 2011-02-22 15:48:39 +0000 (Tue, 22 Feb 2011) $
# $LastChangedBy: rm7 $

use strict;
use warnings FATAL => 'all';

use Moose;
use HTGT::DBFactory;
use HTGT::Utils::Recovery::Constants qw( :state :limits :cassettes @PCS_PRIMERS $PROJECT_STATUS_REDESIGN_REQUESTED );
use List::Util qw( reduce );
use List::MoreUtils qw( uniq all any );
use Hash::MoreUtils qw( slice_def );
use DateTime;
use Readonly;
use namespace::autoclean;

with 'MooseX::Log::Log4perl';
with 'HTGT::Utils::Recovery::ResultSets';

=pod

=head1 SYNOPSIS

  use HTGT::Utils::Recovery::GeneRecovery;

  my $ac = HTGT::Utils::Recovery::GeneRecovery->new( mgi_gene_id => $mgi_gene_id );

  if ( $ac->is_in_acr ) {
      print $mgi_gene_id . " is in alternate clone recovery\n";
  }

=head1 DESCRIPTION

Utilities for processing genes for recovery.

=cut

=attr schema

An HTGT schema object for use by this module. If not specified in the constructor,
a connection to eucomm_vector is made via HTGT::DBFactory.

=cut

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1,
    lazy     => 1,
    default  => sub { HTGT::DBFactory->connect('eucomm_vector') },
);

=attr qc_schema

A ConstructQC schema object for use by this module. If not specified
in the constructor, a connection to vector_qc is made via
HTGT::DBFactory;

=cut

has qc_schema => (
    is       => 'ro',
    isa      => 'ConstructQC',
    required => 1,
    lazy     => 1,
    default  => sub { HTGT::DBFactory->connect( 'vector_qc' ) },
);

=method dbh

Convenience method to return the database handle underlying our
schema.

=cut

sub dbh {
    shift->schema->storage->dbh;
}

=attr mgi_gene_id

This is what it's all about!


=cut


has mgi_gene_id => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

=method mgi_gene

Convenience method to return a B<HTGTDB::MGIGene> object for our I<mgi_gene_id>.

=cut

has mgi_gene => (
    is         => 'ro',
    isa        => 'HTGTDB::MGIGene',
    lazy_build => 1,
);

sub _build_mgi_gene {
    my $self = shift;
    $self->schema->resultset('MGIGene')->find( $self->mgi_gene_id )
        or confess( "MGIGene " . $self->mgi_gene_id . " not found" );
}

=attr has_project_with_ignore_gene_status

Returns true if this gene has at least one project with status ES-TC
or better, otherwise false.

=cut

has _projects_with_ignore_gene_status => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Project]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        projects_with_ignore_gene_status    => 'elements',
        has_project_with_ignore_gene_status => 'count',
    }   
);

sub _build__projects_with_ignore_gene_status {
    my $self = shift;

    my @projects = $self->project_ignore_gene_status_rs->all;

    $self->log->debug( 'projects with ignore gene status: ' . join( q{, }, map sprintf( '%d[%s]', $_->project_id, $_->status->code ), @projects ) );

    \@projects;
}

=attr active_projects

Returns a list of B<HTGTDB::Project> objects representing the active
KOMP/EUCOMM projects for this gene.

=cut

has _active_projects => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Project]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        active_projects     => 'elements',
        has_active_projects => 'count',
    }
);

sub _build__active_projects {
    my $self = shift;

    my @active_projects = $self->active_project_rs->all;

    $self->log->debug( "active projects: " . join( q{, }, map sprintf( '%d[%s]', $_->project_id, $_->status->code ), @active_projects ) );

    return \@active_projects;
}

=attr active_project_ids

Returns a reference to a list of I<project_id> for the active
KOMP/EUCOMM projects for this gene.

=cut

has active_project_ids => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_active_project_ids {
    my $self = shift;

    [ map $_->project_id, $self->active_projects ];
}

=attr has_redesign_requested_project

Returns true if any of the projects for this gene have status redesign requested,
otherwise false.

=cut

has has_redesign_requested_project => (
    is         => 'ro',
    isa        => 'Bool',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_has_redesign_requested_project {
    my $self = shift;

    any { $_->status->code eq $PROJECT_STATUS_REDESIGN_REQUESTED } $self->active_projects;    
}


=attr has_redesign_recovery_project

Returns true if some project for the gene has status design complete and a recovery
design attached, otherwise false.

=cut

has has_redesign_recovery_project => (
    is         => 'ro',
    isa        => 'Bool',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_has_redesign_recovery_project {
    my $self = shift;

    for my $dc_project ( grep { $_->status->code eq 'DC' } $self->active_projects ) {
        next unless $dc_project->design_id;
        return 1 if $dc_project->design->is_recovery_design;
    }

    return 0;
}

=attr active_bl6_projects

Returns a list of B<HTGTDB::Project> objects representing the active
KOMP/EUCOMM projects for this gene with a Bl6/J BAC strain.

=cut

has _active_bl6_projects => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Project]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        active_bl6_projects     => 'elements',
        has_active_bl6_projects => 'count',
    }
);

sub _build__active_bl6_projects {
    my $self = shift;

    my @active_projects = $self->active_bl6_project_rs->all;

    $self->log->debug( "active Bl6/J projects: " . join( q{, }, map sprintf( '%d[%s]', $_->project_id, $_->status->code ), @active_projects ) );

    return \@active_projects;
}

=attr active_bl6_project_ids

Returns a reference to a list of I<project_id> for the active
KOMP/EUCOMM projects for this gene with a Bl6/J BAC strain.

=cut

has active_bl6_project_ids => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1
);

sub _build_active_bl6_project_ids {
    my $self = shift;

    [ map $_->project_id, $self->active_bl6_projects ];
}

=attr is_komp

Returns true if at least one of the active projects for this gene is
KOMP_CSD.

=cut

has is_komp => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

sub _build_is_komp {
    my $self = shift;

    any { $_->is_komp_csd } $self->active_projects;
}

=attr is_eucomm

Returns true if at least one of the active projects for this gene is EUCOMM.

=cut

has is_eucomm => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

sub _build_is_eucomm {
    my $self = shift;

    any { $_->is_eucomm } $self->active_projects;
}

=attr wsdi_active_projects

Returns a list of well_summary_bi_di rows for the active KOMP/EUCOMM
projects for this gene B<regardless of BAC strain>.

=cut

has _wsdi_active_projects => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::WellSummaryByDI]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        wsdi_active_projects => 'elements',
    }
);

sub _build__wsdi_active_projects {
    my $self = shift;

    [ $self->wsdi_active_project_rs->all ];
}


=attr wsdi_active_bl6_projects

Returns a list of well_summary_by_di rows for the active KOMP/EUCOMM
projects for this gene B<with a Bl6/J BAC strain>.

=cut

has _wsdi_active_bl6_projects => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::WellSummaryByDI]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        wsdi_active_bl6_projects => 'elements',
    }
);

sub _build__wsdi_active_bl6_projects {
    my $self = shift;

    [ $self->wsdi_active_bl6_project_rs->all ];
}

=attr epd_distribute_count

The total number of distributable EPD wells for the active projects
for this gene.

=cut

has epd_distribute_count => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_epd_distribute_count {
    my $self = shift;

    my $count = grep {
        defined $_->epd_well_id
            and defined $_->epd_distribute
                and $_->epd_distribute eq 'yes';    
    } $self->wsdi_active_bl6_projects;

    $self->log->debug( "found $count distributable EPD wells for " . $self->mgi_gene_id );

    return $count;
}

=method design_wells

Returns a list of B<HTGTDB::Well> obejcts representing the design wells for
KOMP/EUCOMM projects for this gene.

=cut

=method has_design_wells

Returns true if the active projects for this gene have design wells, otherwise false.

=cut

has _design_wells => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        design_wells     => 'elements',
        has_design_wells => 'count',
    }
);

sub _build__design_wells {
    my $self = shift;

    my ( @design_wells, %seen );

    for ( $self->wsdi_active_projects ) {
        next unless defined $_->design_well_id
            and not $seen{ $_->design_well_id }++;
        push @design_wells, $_->design_well;
    }

    $self->log->debug( "design wells: " . join( q{, }, @design_wells ) );

    return \@design_wells;    
}

=method design_wells

Returns a list of B<HTGTDB::Well> obejcts representing the design wells for
KOMP/EUCOMM projects for this gene.

=cut

=method has_design_wells

Returns true if the active projects for this gene have design wells, otherwise false.

=cut

has _bl6_design_wells => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        bl6_design_wells     => 'elements',
        has_bl6_design_wells => 'count',
    }
);

sub _build__bl6_design_wells {
    my $self = shift;

    my ( @design_wells, %seen );

    for ( $self->wsdi_active_bl6_projects ) {
        next unless defined $_->design_well_id
            and not $seen{ $_->design_well_id }++;
        push @design_wells, $_->design_well;
    }

    $self->log->debug( "design wells: " . join( q{, }, @design_wells ) );

    return \@design_wells;    
}

=attr distributable_targvec_wells

Returns a list of B<HTGTDB::Well> objects for the distributable
targeting vectors for this gene.

=method has_distributable_targvecs

Returns true if this gene has at least one distributable targeting
vector, otherwise false.

=cut

has _distributable_targvecs => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        distributable_targvec_wells => 'elements',
        has_distributable_targvecs  => 'count',
    }
);

sub _build__distributable_targvecs {
    my $self = shift;

    my ( @distributable_targvecs, %seen );

    for ( $self->wsdi_active_bl6_projects ) {
        next if not defined $_->pgdgr_well_id
            or $seen{ $_->pgdgr_well_id }++;

        my $distribute = $_->pgdgr_distribute;

        push @distributable_targvecs, $_->pgdgr_well
            if defined $distribute and $distribute eq 'yes';        
    }

    $self->log->debug( "distributable targeting vectors: " . join( q{, }, @distributable_targvecs ) );

    return \@distributable_targvecs;
}

=method targvec_wells

Returns a list of B<HTGTDB::Well> objects for the targeting vectors for this gene.

=cut

sub targvec_wells {
    my $self = shift;

    my ( @targvecs, %seen );

    for ( $self->wsdi_active_bl6_projects ) {
        next if not defined $_->pgdgr_well_id
            or $seen{ $_->pgdgr_well_id }++;

        push @targvecs, $_->pgdgr_well;
    }

    return @targvecs;
}

=method qc_done_pcs_wells

Returns a list of B<HTGTDB::Well> objects for the PCS wells from
plates stamped 'qc_done'.

=cut

=method has_qc_done_pcs_wells

Returns true if the gene has PCS wells with QC done, otherwise false.

=cut

has _qc_done_pcs_wells => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles => {
        qc_done_pcs_wells     => 'elements',
        has_qc_done_pcs_wells => 'count',
    }
);

sub _build__qc_done_pcs_wells {
    my $self = shift;

    my ( @qc_done_pcs_wells, %seen );

    my @pcs_wells = grep $_->plate->type eq 'PCS',
        map _descendants( $_->design_well ),
            grep { defined $_->design_well_id and  not $seen{ $_->design_well_id } }
                $self->wsdi_active_bl6_projects;
    
    %seen = ();
    
    for my $pcs_well ( @pcs_wells ) {
        next if $seen{ $pcs_well->well_id }++;
        my $qc_done = $pcs_well->plate->plate_data_value( 'qc_done' );
        next unless $qc_done and $qc_done eq 'yes';
        push @qc_done_pcs_wells, $pcs_well;        
    }

    $self->log->debug( 'QC done PCS wells: ' . join( q{, }, @qc_done_pcs_wells ) );
    
    return \@qc_done_pcs_wells;
}

=attr pcs_well_valid_primers

Hash, keyed on well id, of the valid PCS primers for each well.

=cut

has pcs_well_valid_primers => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => [ 'Hash' ],
    handles    => {
        get_pcs_well_valid_primers => 'get'
    }
);

sub _build_pcs_well_valid_primers {
    my $self = shift;

    my %valid_primers_by_well_id = map {
        $_->well_id => $self->_valid_pcs_primers_for_well( $_ )
    } $self->qc_done_pcs_wells;

    return \%valid_primers_by_well_id;
}

sub _valid_pcs_primers_for_well {
    my ( $self, $well ) = @_;

    my %primers = slice_def( $self->_valid_primers_for_well( $well ), @PCS_PRIMERS );
    
    $self->log->debug( "$well PCS primers: " . join( q{, }, keys %primers ) );

    return \%primers;
}

sub _valid_primers_for_well {
    my ( $self, $well ) = @_;

    my $qctest_result_id = $well->well_data_value( 'qctest_result_id' );
    unless ( defined $qctest_result_id ) {
        $self->log->warn( "no QC test result id for $well" );
        return {};
    }

    my $qctest_result = $self->qc_schema->resultset( 'QctestResult' )->find(
        {
            qctest_result_id => $qctest_result_id
        }
    );

    unless ( $qctest_result ) {
        $self->log->warn( "QC test result $qctest_result_id not found" );
        return {};        
    }

    my %valid_primers;
    
    foreach my $primer ( $qctest_result->qctestPrimers ) {
        my $seq_align_feature = $primer->seqAlignFeature
            or next;
        my $loc_status = $seq_align_feature->loc_status
            or next;
        $valid_primers{ lc( $primer->primer_name ) } = 1
            if $loc_status eq 'ok';
    }

    $self->log->debug( "valid primers for $well: " . join( q{, }, keys %valid_primers ) );

    return \%valid_primers;
}

=method pcs_wells_with_loxp_primer

Returns a list of PCS wells with a valid loxP primer.

=cut

=method has_pcs_well_with_loxp_primer

Returns true if any of the PCS wells for the active projects for this gene have
a vaild loxP primer, otherwise false.

=cut

has _pcs_wells_with_loxp_primer => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        pcs_wells_with_loxp_primer    => 'elements',
        has_pcs_well_with_loxp_primer => 'count',
    }
);

sub _build__pcs_wells_with_loxp_primer {
    my $self = shift;

    my @wells;

    for my $pcs_well ( $self->qc_done_pcs_wells ) {
        my $primers = $self->get_pcs_well_valid_primers( $pcs_well->well_id );
        push @wells, $pcs_well
            if $primers->{lr} or $primers->{lrr};
    }

    $self->log->debug( "PCS wells with valid loxP primer: " . join( q{, }, @wells ) );

    return \@wells;
}

=method pcs_wells_with_loxp_and_cassette_primer

Returns a list of PCS wells with a valid loxP and cassette primer.

=cut

=method has_pcs_well_with_loxp_and_cassette_primer

Returns true if any of the PCS wells for the active projects for this gene have
a vaild loxP primer and a valid cassette primer, otherwise false.

=cut

has _pcs_wells_with_loxp_and_cassette_primer => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        pcs_wells_with_loxp_and_cassette_primer     => 'elements',
        has_pcs_well_with_loxp_and_cassette_primer => 'count',
    }
);

sub _build__pcs_wells_with_loxp_and_cassette_primer {
    my $self = shift;

    my @wells;

    for my $pcs_well ( $self->pcs_wells_with_loxp_primer ) {
        my $primers = $self->get_pcs_well_valid_primers( $pcs_well->well_id );
        push @wells, $pcs_well
            if $primers->{z1} or $primers->{z2};
    }

    $self->log->debug( "PCS wells with valid loxP and cassette primer: " . join( q{, }, @wells ) );
    
    return \@wells;
}

=attr best_pcs_well

Returns the PCS well with the most valid primers.

Note: this method will throw an exception if called when there are on
PCS wells with a valid loxP primer.

=cut

has best_valid_pcs_well => (
    is         => 'ro',
    isa        => 'Object | Undef',
    lazy_build => 1,
);

sub _build_best_valid_pcs_well {
    my $self = shift;

    my @candidates;

    if ( $self->has_pcs_well_with_loxp_and_cassette_primer ) {
        @candidates = $self->pcs_wells_with_loxp_and_cassette_primer;
    }
    elsif ( $self->has_pcs_well_with_loxp_primer ) {
        @candidates = $self->pcs_wells_with_loxp_primer;        
    }

    my $best_well = undef;
    my $best_primer_count = 0;
    
    for my $pcs_well ( @candidates ) {
        my $nprimers = keys %{ $self->get_pcs_well_valid_primers( $pcs_well->well_id ) };
        $self->log->debug( "$pcs_well has $nprimers valid primers" );
        if ( $nprimers > $best_primer_count ) {
            $best_primer_count = $nprimers;
            $best_well = $pcs_well;
        }
    }

    $self->log->debug( "best valid PCS well: " . ( $best_well || '<undef>' ) );

    return $best_well;
}

=attr failed_targvecs_with_good_primers

Returns a list of targeting vectors with pass_level 'fail' but
a good LR and PNF or NF or L1 primer. These are candidates for
re-sequencing.

=cut

=method has_fail_targvec_with_good_primers

Returns true if the gene has at least one targeting vector with
pass_level 'fail' but a goor LR and PNF or NF or L1 primer.

=cut

has _fail_targvecs_with_good_primers => (
    isa        => 'ArrayRef[HashRef]',
    traits     => [ 'Array' ],
    handles    => {
        has_fail_targvec_with_good_primers => 'count',
        fail_targvecs_with_good_primers    => 'elements',
    },
    lazy_build => 1,
);

sub _build__fail_targvecs_with_good_primers {
    my $self = shift;

    my %seen;
    my @fail_targvecs;
    for ( $self->wsdi_active_bl6_projects ) {
        next unless $_->pgdgr_well_id
            and $_->pg_pass_level
                and $_->pg_pass_level eq 'fail'
                    and not $seen{ $_->pgdgr_well_id }++;
        my $well = $_->pgdgr_well;
        my $primers = $self->_valid_primers_for_well( $well );
        push @fail_targvecs, { well => $well, primers => $primers }
            if $primers->{lr} and ( $primers->{nf} or $primers->{pnf} or $primers->{l1} );        
    }

    return \@fail_targvecs;    
}

=attr needs_promoter

Returns true if this gene needs a cassette with a promoter, otherwise false.

A gene needs a promoter if it is SP, TM, or has fewer than
I<$MIN_PROMOTORLESS_TRAPS> traps.

=cut

has needs_promoter => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

sub _build_needs_promoter {
    my $self = shift;
    
    $self->mgi_gene->sp
        or $self->mgi_gene->tm
            or ( $self->mgi_gene->mgi_gt_count || 0 ) < $MIN_PROMOTORLESS_TRAPS;
}

=attr needs_promoter_but_no_targvec_with_promoter 

Returns true if the gene needs a cassette with promoter, but all
distributable targeting vectors are without promoter, otherwise false.

=cut

sub needs_promoter_but_no_targvec_with_promoter {
    my $self = shift;

    return unless $self->needs_promoter;

    my @tv_cassettes = map $_->well_data_value( 'cassette' ), $self->distributable_targvec_wells;

    all { $IS_PROMOTORLESS_CASSETTE{ $_ } } @tv_cassettes;
}

=method gwr_wells

=cut

=method has_gwr_wells

=cut

has _gwr_wells => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        gwr_wells     => 'elements',
        has_gwr_wells => 'count',
    }
);

sub _build__gwr_wells {
    my $self = shift;

    my ( @gwr_wells, %seen );
    
    for ( $self->wsdi_active_bl6_projects ) {
        next if not defined $_->pgdgr_well_id
            or $seen{ $_->pgdgr_well_id }++;
        my $is_gwr = $_->pgdgr_well->well_data_value( 'gateway_recovery' )
            || $_->pgdgr_well->plate->plate_data_value( 'gateway_recovery' )
                || '';
        push @gwr_wells, $_->pgdgr_well
            if $is_gwr eq 'yes';
    }
    
    $self->log->debug( "gateway recovery wells: " . join( q{, }, @gwr_wells ) );

    return \@gwr_wells;
}

=method acr_wells

=cut

=method has_acr_wells

=cut

has _acr_wells => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        acr_wells     => 'elements',
        has_acr_wells => 'count',
    }
);

sub _build__acr_wells {
    my $self = shift;

    my ( @acr_wells, %seen );
    
    for ( $self->wsdi_active_bl6_projects ) {
        next if not defined $_->pgdgr_well_id
            or $seen{ $_->pgdgr_well_id }++;

        push @acr_wells,
            grep { ( $_->well_data_value( 'alternate_clone_recovery' )
                         || $_->plate->plate_data_value( 'alternate_clone_recovery' )
                             || '' ) eq 'yes' }
                _descendants( $_->pgdgr_well );
    }
    
    $self->log->debug( "alternate clone recovery wells: " . join( q{, }, @acr_wells ) );

    return \@acr_wells;
}

=method acr_well_pass_levels

=cut

has _acr_well_pass_levels => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => [ 'Hash' ],
    handles    => {
        acr_well_pass_levels    => 'values',
        get_acr_well_pass_level => 'get',
    }
);

sub _build__acr_well_pass_levels {
    my $self = shift;

    my %pass_level_for_well;

    for my $well ( $self->acr_wells ) {
        my @pass_levels = uniq grep defined, map $_->well_data_value( 'pass_level' ), $well, $well->child_wells;
        if ( @pass_levels ) {
            my $pass_level = reduce { HTGTDB::Well::qc_update_needed( $a, $b, 'postgw' ) ? $b : $a } @pass_levels;            
            $self->log->debug( "pass_level for $well: " . join( q{, }, @pass_levels ) . " => $pass_level" );
            $pass_level_for_well{ $well->well_id } = $pass_level;
        }        
    }

    $self->log->debug(
        sub {
            "acr pass levels: " .
                join( q{, },
                      map sprintf( '%s => %s', $_, $pass_level_for_well{ $_->well_id } || '<undef>' ), $self->acr_wells );            
        } );

    return \%pass_level_for_well;            
}

=method acr_wells_with_qc_pass

=cut

=method has_acr_wells_with_qc_pass

=cut

has _acr_wells_with_qc_pass => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        acr_wells_with_qc_pass     => 'elements',
        has_acr_wells_with_qc_pass => 'count',
    }
);

sub _build__acr_wells_with_qc_pass {
    my $self = shift;

    my @acr_passes = grep { ( $self->get_acr_well_pass_level( $_->well_id ) || '' ) =~ qr/^pass/ } $self->acr_wells;

    $self->log->debug( "acr wells with QC pass: " . join( q{, }, @acr_passes ) );

    return \@acr_passes;
}

=method acr_well_dna_statuses

=cut

=method get_acr_well_dna_status

=cut

has _acr_well_dna_status => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => [ 'Hash' ],
    handles    => {
        acr_well_dna_statuses   => 'values',
        get_acr_well_dna_status => 'get',
    }
);

sub _build__acr_well_dna_status {
    my $self = shift;

    my %dna_status_for_acr_well;

    for my $w ( $self->acr_wells_with_qc_pass ) {
        $self->log->debug( "Examining child wells of $w for DNA status" );
        my @c_dna_status = map $_->well_data_value( 'DNA_STATUS' ), $w->child_wells;
        unless ( any { defined } @c_dna_status ) {
            $self->log->debug( "Examining grandchild wells of $w for DNA status" );
            @c_dna_status = map $_->well_data_value( 'DNA_STATUS' ), map $_->child_wells, $w->child_wells;
        }
        if ( any { defined $_ and $_ eq 'pass' } @c_dna_status ) {
            $self->log->debug( "$w has DNA pass" );
            $dna_status_for_acr_well{ $w->well_id } = 'pass';
        }
        elsif ( all { defined $_ } @c_dna_status ) {
            $self->log->debug( "$w has DNA fail" );
            $dna_status_for_acr_well{ $w->well_id } = 'fail';
        }
        else {
            $dna_status_for_acr_well{ $w->well_id } = undef;
        }
    }

    $self->log->debug(
        sub {
            "DNA status for acr wells: "
                . join( q{, }, map {
                    sprintf( '%s => %s', $_, $dna_status_for_acr_well{ $_->well_id } || '<undef>' );                    
                } $self->acr_wells_with_qc_pass );
        }
    );

    \%dna_status_for_acr_well;
}

=method acr_wells_with_dna_pass

=cut

=method has_acr_wells_with_dna_pass

=cut

has _acr_wells_with_dna_pass => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        acr_wells_with_dna_pass     => 'elements',
        has_acr_wells_with_dna_pass => 'count',
    }
);

sub _build__acr_wells_with_dna_pass {
    my $self = shift;

    my @acr_dna_passes = grep { ( $self->get_acr_well_dna_status( $_->well_id ) || '' ) eq 'pass' } $self->acr_wells_with_qc_pass;

    $self->log->debug( "acr wells with DNA pass: " . join( q{, }, @acr_dna_passes ) );

    return \@acr_dna_passes;    
}        

=method acr_well_eps

=cut

=method has_acr_wells_with_ep

=cut

has _acr_well_eps => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        acr_well_eps          => 'elements',
        has_acr_wells_with_ep => 'count',
    }
);

sub _build__acr_well_eps {
    my $self = shift;

    my @eps = grep $_->plate->type eq 'EP', _descendants( $self->acr_wells_with_dna_pass );
                                                             
    $self->log->debug( "EPs from DNA pass acr wells: " . join( q{, }, @eps ) );

    return \@eps;
}

sub _descendants {

    my @descendants;
    for my $c ( map $_->child_wells, @_ ) {
        push @descendants, $c, _descendants( $c );
    }

    return @descendants;
}

=method latest_acr_attempt_date

=cut

has latest_acr_attempt_date => (
    is         => 'ro',
    isa        => 'DateTime',
    lazy_build => 1
);

sub _build_latest_acr_attempt_date {
    my $self = shift;

    $self->_find_latest_plate_create_date( 'acr_wells' );
}

=method latest_distributable_targvec_date

=cut

has latest_distributable_targvec_date => (
    is         => 'ro',
    isa        => 'DateTime',
    lazy_build => 1,
);

sub _build_latest_distributable_targvec_date {
    my $self = shift;

    $self->_find_latest_plate_create_date( 'distributable_targvec_wells' );
}

sub _find_latest_plate_create_date {
    my ( $self, $what ) = @_;
    
    my $latest_date = DateTime::Infinite::Past->new;

    for ( $self->$what ) {
        my $this_date = $_->plate->created_date;
        $latest_date = $this_date
            if $this_date > $latest_date;
    }

    $self->log->debug( "Most recent $what: " . ( $latest_date || '<undef>' ) );

    return $latest_date;    
}

=method rdr_wells

=cut

=method has_rdr_wells

=cut

has _rdr_wells => (
    is         => 'ro',
    isa        => 'ArrayRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Array' ],
    handles    => {
        rdr_wells     => 'elements',
        has_rdr_wells => 'count',
    }
);

sub _build__rdr_wells {
    my $self = shift;

    my ( @rdr_wells, %seen );
    
    for ( $self->wsdi_active_bl6_projects ) {
        next if not defined $_->design_well_id
            or $seen{ $_->design_well_id }++;
        my $is_rdr =
            $_->design_well->well_data_value( 'redesign_recovery' )
                || $_->design_well->well_data_value( 'resynthesis_recovery' )
                    || $_->design_well->plate->plate_data_value( 'redesign_recovery' )
                        || $_->design_well->plate->plate_data_value( 'resynthesis_recovery' )
                            || '';
        push @rdr_wells, $_->design_well
            if $is_rdr eq 'yes';
    }
    
    $self->log->debug( "redesign/resynthesis recovery wells: " . join( q{, }, @rdr_wells ) );

    return \@rdr_wells;
}

=attr invalid_cassettes

List of cassettes that are not valid for this gene.

ST cassettes are not valid for any genes.

If a gene is SP or TM or has fewer than I<$MIN_PROMOTORLESS_TRAPS> traps,
then promotorless cassettes are not valid.

=cut

=method is_invalid_cassette( I<$cassette> )

Returns true if I<$cassette> is not valid for this gene, otherwise false.

=cut

has _invalid_cassettes => (
    is         => 'ro',
    isa        => 'HashRef[Str]',
    lazy_build => 1,
    traits     => [ 'Hash' ],
    handles    => {
        invalid_cassettes   => 'keys',
        is_invalid_cassette => 'exists',
    }
);

sub _build__invalid_cassettes {
    my $self = shift;

    if ( $self->needs_promoter ) {
        return \%IS_PROMOTORLESS_CASSETTE;
    }
    else {
        return \%IS_ST_CASSETTE;
    }
}

=method is_valid_cassette( I<$cassette> )

Returns true if I<$cassette> is valid for this gene, otherwise false.

=cut

sub is_valid_cassette {
    my ( $self, $cassette ) = @_;

    not $self->is_invalid_cassette( $cassette );
}


=method _chosen_clone_plates

Helper function that returns a hash, keyed on clone name, whose value
is a list of 96-well PGD or PGR plate names containing that clone.

B<WARNING:> This is not an exhaustive list. A clone is also "chosen" if
the 384-well PG plate well has child wells. Use B<chosen_clones> to
get a complete list of chosen clones.

=cut

sub _chosen_clone_plates {
    my $self = shift;

    my %plates_for;

    my $sth = $self->dbh->prepare( <<'EOT' );
SELECT DISTINCT well_data.data_value, plate.name
FROM well_data
JOIN well ON well.well_id = well_data.well_id
JOIN plate ON plate.plate_id = well.plate_id AND plate.type IN ( 'PGD', 'PGR' )
JOIN project ON project.design_instance_id = well.design_instance_id
LEFT OUTER JOIN plate_data ON plate_data.plate_id = plate.plate_id AND plate_data.data_type = 'is_384'
WHERE well_data.data_type = 'clone_name'
AND project.mgi_gene_id = ?
AND plate_data.data_value IS NULL
AND well_data.data_value IS NOT NULL
ORDER BY well_data.data_value
EOT

    $sth->execute( $self->mgi_gene_id );

    while ( my $r = $sth->fetchrow_arrayref ) {
        push @{ $plates_for{ $r->[0] } }, $r->[1];
    }

    return \%plates_for;
}


=method mk_clone_name( I<$plate_name>, I<$well_name> )

Constructs a clone name from a plate name and well name by inserting
the well name into the plate name just before the iteration, or at the
end if the plate name has no iteration.

=cut

sub mk_clone_name {
    my ( $self, $plate_name, $well_name ) = @_;
    
    {
        no warnings 'uninitialized'; # $1 will be undef when plate has no iteration
        
        $plate_name =~ s/(_\d+)?\z/_$well_name$1/;
    }

    return $plate_name;
}

=attr _chosen_clones

Hash of chosen clones keyed on clone name.

=cut

=method chosen_clones

Returns a list of chosen clones; each chosen clone is a hash
containing the clone name and a comma-separated list of plates on
which the clone was found.

A clone is "chosen" if it appears as a clone_name on a 96-well PGD or PGR plate,
B<or> the 384-well PG well has child wells.

=cut

=method has_chosen_clones

Returns true if this gene has at least 1 chosen clone, otherwise false.

=cut

=method is_chosen_clone( I<$clone_name> )

Returns true if I<$clone_name> is a chosen clone, otherwise false.

=cut

has _chosen_clones => (
    is         => 'ro',
    isa        => 'HashRef[HashRef]',
    lazy_build => 1,
    traits     => [ 'Hash' ],
    handles    => {
        chosen_clones     => 'values',
        has_chosen_clones => 'count',
        is_chosen_clone   => 'exists',
    },
);

sub _build__chosen_clones {
    my $self = shift;

    my $plates_for = $self->_chosen_clone_plates;

    my %chosen_clones;

    for my $tv ( grep { $_->plate->plate_data_value( 'is_384' ) || '' eq 'yes' } $self->targvec_wells ) {
        my $clone_name = $self->mk_clone_name( $tv->plate->name, $tv->well_name );
        my %c = ( chosen_clone_name => $clone_name,
                  chosen_well       => $tv,
                  child_plates      => [],
                  distribute        => $tv->well_data_value( 'distribute' ) || 'no',
              );
        if ( $tv->child_wells > 0 ) {
            push @{ $c{child_plates} }, $tv->plate->name;
        }
        if ( $plates_for->{ $clone_name } ) {
            push @{ $c{child_plates} }, @{ $plates_for->{ $clone_name } };    
        }
        if ( @{ $c{child_plates} } ) {
            $c{child_plates} = join q{,}, sort { $a cmp $b } uniq @{ $c{child_plates} };
            $chosen_clones{ $clone_name } = \%c;
        }
    }

    $self->log->debug( "chosen clones: " . join( q{, }, map $_->{chosen_clone_name}, values %chosen_clones ) );
    
    return \%chosen_clones;
}

=method is_chosen_clone_well( I<$well> )

Takes a single argument, an B<HTGTDB::Well> object. Returns true if
I<$well> contains a chosen clone, otherwise false.

=cut

sub is_chosen_clone_well {
    my ( $self, $well ) = @_;

    my $clone_name = $self->mk_clone_name( $well->plate->name, $well->well_name );
    
    $self->is_chosen_clone( $clone_name );
}

=attr alternate_clones

Returns a list of B<HTGTDB::Well> objects representing the alternate
clones for this gene.

A distributable targeting vector is considered a suitable alternate clone
if it has a valid cassette and is not already a chosen clone.

If alternates with promoter are available, alternates without promoter
are suppressed.

=cut

has _alternate_clones => (
    is         => 'ro',
    isa        => 'HashRef[HTGTDB::Well]',
    lazy_build => 1,
    traits     => [ 'Hash' ],
    handles    => {
        alternate_clones     => 'values',
        has_alternate_clones => 'count',
        is_alternate_clone   => 'exists',
    },
);

sub _build__alternate_clones {
    my $self = shift;

    my @alternates = grep {
        (not $self->is_chosen_clone_well( $_ ) )
            and $self->is_valid_cassette( $_->well_data_value( 'cassette' ) )
                and ( $_->plate->plate_data_value( 'is_384' ) || '' ) eq 'yes';
    } $self->distributable_targvec_wells;
    
    my @alternates_with_promoter = grep {
        not $IS_PROMOTORLESS_CASSETTE{ $_->well_data_value( 'cassette' ) }        
    } @alternates;

    if ( @alternates_with_promoter ) {
        @alternates = @alternates_with_promoter;
    }

    my %alternates = map { $self->mk_clone_name( $_->plate->name, $_->well_name ) => $_ } @alternates;

    $self->log->debug( 'alternate clones: ' . join( q{, }, values %alternates ) );
    
    return \%alternates;
}

has already_recovered_clones => (
    traits     => [ 'Hash' ],
    lazy_build => 1,
    handles    => {
        already_recovered => 'exists'
    }
);

sub _build_already_recovered_clones {
    my $self = shift;

    $self->schema->storage->dbh->selectall_hashref( <<'EOT', 'DATA_VALUE' );
select well_data.data_value
from well_data
join well on well.well_id = well_data.well_id
join plate on plate.plate_id = well.plate_id
join plate_data 
  on plate_data.plate_id = plate.plate_id 
  and plate_data.data_type = 'alternate_clone_recovery' 
  and plate_data.data_value = 'yes'
where well_data.data_type = 'clone_name'
EOT
}

around already_recovered => sub {
    my $orig = shift;
    my $self = shift;

    if ( @_ > 1 ) {
        $self->$orig( $self->mk_clone_name( @_ ) );                      
    }
    else {
        $self->$orig( @_ );        
    }    
};

has _chosen_for_recovery => (
    isa        => 'ArrayRef[HashRef]',
    traits     => [ 'Array' ],
    handles    => {
        has_chosen_for_recovery => 'count',
        chosen_for_recovery     => 'elements',        
    },
    lazy_build => 1
);

sub _build__chosen_for_recovery {
    my $self = shift;

    my @chosen = grep {
        $_->{distribute} eq 'yes' and not $self->already_recovered( $_->{chosen_clone_name} )
    } $self->chosen_clones;

    $self->log->debug( "chosen clones for recovery: " . join( q{, }, map $_->{chosen_clone_name}, @chosen ) );
    
    return \@chosen;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
