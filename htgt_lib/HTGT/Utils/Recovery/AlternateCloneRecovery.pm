package HTGT::Utils::Recovery::AlternateCloneRecovery;

use strict;
use warnings;

use Readonly;
use List::MoreUtils 'uniq';
use Log::Log4perl;
use HTGT::Utils::RegeneronGeneStatus;

Readonly my %IS_PROMOTORLESS_CASSETTE =>  map { $_ => 1 }
    qw( L1L2_gt0 L1L2_gt1 L1L2_gt2 L1L2_gtk L1L2_st0 L1L2_st1 L1L2_st2 );

Readonly my %IS_ST_CASSETTE => map { $_ => 1 }
    qw( L1L2_st0 L1L2_st1 L1L2_st2 );

# Don't consider a promotorless targetting vector for recovery unless it
# has at least $MIN_PROMOTORLESS_TRAPS targetted traps.
Readonly my $MIN_PROMOTORLESS_TRAPS => 4;

# Don't consider genes for recovery if they have more than
# $MAX_EPD_DISTRIBUTE distributable clones.
Readonly my $MAX_EPD_DISTRIBUTE     => 2;  
                          
Readonly my $CLONES_FOR_RECOVERY => <<"EOT";
select distinct project.mgi_gene_id,
                mgi_gene.sp,
                mgi_gene.tm,
                mgi_gene.mgi_gt_count,
                well.design_instance_id,
                well.well_id,
                well.parent_well_id,
                plate.name plate_name,
                well.well_name,
                wd1.data_value cassette,
                wd2.data_value clone_name,
                plate_data.data_value is_384,
                wd3.data_value distribute
from project
join mgi_gene
  on mgi_gene.mgi_gene_id = project.mgi_gene_id
join well 
  on well.design_instance_id = project.design_instance_id
join plate 
  on plate.plate_id = well.plate_id 
  and plate.type in ( 'PGD', 'PGR' )
left outer join plate_data 
  on plate_data.plate_id = plate.plate_id
  and plate_data.data_type = 'is_384'
join well_data wd1 on wd1.well_id = well.well_id
  and wd1.data_type = 'cassette'
left outer join well_data wd2
  on wd2.well_id = well.well_id
  and wd2.data_type = 'clone_name'
left outer join well_data wd3
  on wd3.well_id = well.well_id
  and wd3.data_type = 'distribute'
where well.design_instance_id is not null
and ( project.is_eucomm = 1 or project.is_komp_csd = 1 )
-- XXX TESTING
-- and project.mgi_gene_id < 100
EOT

Readonly my $ALTERNATE_CLONE_RECOVERY_GENES => <<"EOT";
select distinct project.mgi_gene_id
from project
join well
  on well.design_instance_id = project.design_instance_id
join plate_data pd
  on pd.plate_id = well.plate_id
  and pd.data_type = 'alternate_clone_recovery'
  and pd.data_value = 'yes'
where ( project.is_eucomm = 1 or project.is_komp_csd = 1 )
EOT

Readonly my $PARENT_WELL_IDS => <<'EOT';
select well.well_id, plate.name plate_name
from well
join plate
  on plate.plate_id = well.plate_id
  and plate.type in ( 'PGD', 'PGR' )
join plate_data
  on plate_data.plate_id = plate.plate_id
  and plate_data.data_type = 'is_384'
  and plate_data.data_value = 'yes'
join well child_well
  on child_well.parent_well_id = well.well_id
EOT

Readonly my $PRIORITY_COUNTS => <<'EOT';
select mgi_gene_id, count( distinct ext_user_id ) as count
from gene_user
group by mgi_gene_id
EOT

Readonly my $EPD_DISTRIBUTE_COUNTS => <<'EOT';
select project.mgi_gene_id, count(distinct well.well_id )
from project
join well
  on well.design_instance_id = project.design_instance_id
join well_data wd1
  on wd1.well_id = well.well_id
  and wd1.data_type = 'distribute'
  and wd1.data_value = 'yes'
join plate
  on plate.plate_id = well.plate_id and plate.type = 'EPD'
where ( project.is_eucomm = 1 or project.is_komp_csd = 1 )
group by project.mgi_gene_id
EOT

sub RecoveryDataColumns {
    return [ qw( marker_symbol
                 ensembl_gene
                 vega_gene
                 design_plate
                 design_well
                 chosen_clones
                 pgdgr_plate
                 pgdgr_well
                 cassette
                 backbone
                 epd_distribute_count
                 mgi_gt_count
                 tm
                 sp
                 pg_pass_level
                 sponsor
                 regeneron_status
                 priority_count
            )
       ];
}

sub new {
    my ( $proto, %args ) = @_;
    my $class = ref( $proto ) || $proto;        
    bless( \%args, $class );
}

sub log {
    my ( $self ) = @_;
    $self->{logger} ||= Log::Log4perl->get_logger( ref $self );
}

sub schema {
    my ( $self ) = @_;
    $self->{htgtdb_schema};
}

sub idcc_mart {
    my ( $self ) = @_;
    return $self->{idcc_mart};
}

sub sort_rows {
    my ( $self, $a_ref ) = @_;
    
    $self->log->debug( "sort_wells" );

    [
        sort {
                   ($a->{ marker_symbol } || '') cmp ($b->{ marker_symbol } || '')
                || ($a->{ design_plate } || 0)   <=> ($b->{ design_plate } || 0)
                || ($a->{ design_well } || '')   cmp ($b->{ design_well } || '')
            } @{ $a_ref }
    ];
}

sub get_clones_for_recovery {
    my ( $self ) = @_;
    
    my $dbh = $self->schema->storage->dbh;
    local $dbh->{ FetchHashKeyName } = 'NAME_lc';
    
    my $clones = $dbh->selectall_hashref( $CLONES_FOR_RECOVERY, [ qw( mgi_gene_id design_instance_id well_id ) ] );

    ### get_clones_for_recovery in: $clones

    foreach my $mgi_gene_id ( keys %{ $clones } ) {
        if ( $self->is_in_recovery( $mgi_gene_id ) ) {
            ### Deleting gene already in recovery: $mgi_gene_id
            delete $clones->{ $mgi_gene_id };
            next;
        }
        if ( $self->get_epd_distribute_count( $mgi_gene_id ) > $MAX_EPD_DISTRIBUTE ) {
            ### Deleting gene with too many distributable clones: $mgi_gene_id
            delete $clones->{ $mgi_gene_id };

        }
    }

    # Don't report on genes unless they have at least one distributable vector 
    foreach my $mgi_gene_id ( keys %{ $clones } ) {
        foreach my $design_instance_id ( keys %{ $clones->{ $mgi_gene_id } } ) {
            unless ( grep $_->{is_384} && $_->{distribute}, values %{  $clones->{ $mgi_gene_id }->{ $design_instance_id } } ) {
                ### ignoring design instance (no distributable vectors): $design_instance_id
                delete $clones->{ $mgi_gene_id }->{ $design_instance_id };
            }
        }
        unless ( keys %{ $clones->{ $mgi_gene_id } } ) {
            ### ignoring mgi_gene (no distributable vectors): $mgi_gene_id
            delete $clones->{ $mgi_gene_id }
                unless keys %{ $clones->{ $mgi_gene_id } };
        }
    }

    ### get_clones_for_recovery out: $clones
    return $clones;
}

sub init {
    my ( $self ) = @_;

    ### init
    
    $self->init_parent_wells()
        unless $self->{parent_wells};
        
    $self->init_epd_distribute_counts()
        unless $self->{epd_distribute_counts};        
        
    $self->init_priority_counts()
        unless $self->{priority_counts};

    $self->init_genes_in_recovery()
        unless $self->{genes_in_recovery};
    
    $self->init_regeneron_status()
        unless $self->{regeneron_status};              
}

sub init_parent_wells {
    my ( $self ) = @_;

    ### init_parent_wells
    
    my %parent_wells;
    
    my $rows = $self->schema->storage->dbh->selectall_arrayref( $PARENT_WELL_IDS );
    foreach my $r ( @{ $rows } ) {
        push @{ $parent_wells{ $r->[0] } }, $r->[1];
    }
    
    $self->{parent_wells} = \%parent_wells; 
}

sub init_priority_counts {
    my ( $self ) = @_;

    ### init_priority_counts
    
    my %priority_counts;
    
    my $rows = $self->schema->storage->dbh->selectall_arrayref( $PRIORITY_COUNTS );
    foreach my $r ( @{ $rows } ) {
        $priority_counts{ $r->[0] } = $r->[1];
    }
    
    $self->{priority_counts} = \%priority_counts;
}

sub init_epd_distribute_counts {
    my ( $self ) = @_;
    
    ### init_epd_distribute_counts
    
    my %epd_distribute_counts;
    my $rows = $self->schema->storage->dbh->selectall_arrayref( $EPD_DISTRIBUTE_COUNTS );
    foreach my $r ( @{ $rows } ) {
        $epd_distribute_counts{ $r->[0] } = $r->[1];
    }
    
    $self->{epd_distribute_counts} = \%epd_distribute_counts;
}

sub init_genes_in_recovery {
    my ( $self ) = @_;

    ### init_genes_in_recovery

    my %genes_in_recovery;
    my $rows = $self->schema->storage->dbh->selectall_arrayref( $ALTERNATE_CLONE_RECOVERY_GENES );
    foreach my $r ( @{ $rows } ) {
        $genes_in_recovery{ $r->[0] } = 1;
    }

    $self->{genes_in_recovery} = \%genes_in_recovery;
}      

sub init_regeneron_status {
    my ( $self ) = @_;

    ### init_regeneron_status
    
    eval {
        $self->{regeneron_status} = HTGT::Utils::RegeneronGeneStatus->new( $self->idcc_mart );
    };
    if ( $@ ) {
        $self->log->error( "Failed to create HTGT::Utils::RegeneronGeneStatus: $@" );
    }
}

sub flag_chosen {
    my ( $self, $wells ) = @_;

    ### flag_chosen
    
    my %is_chosen;
    foreach my $well ( values %{ $wells } ) {
        next if $well->{is_384};
        if ( my $clone_name = $well->{clone_name} ) {
            push @{ $is_chosen{ $clone_name } }, $well->{plate_name};
        }
    }                     
                    
    foreach my $w ( grep $_->{is_384}, values %{ $wells } ) {
        push @{ $w->{is_chosen} }, @{ $is_chosen{ $w->{clone_name} } }
            if defined $w->{clone_name} and $is_chosen{ $w->{clone_name} };
    }   

    foreach my $w ( grep $_->{is_384} && !$_->{is_chosen}, values %{ $wells } ) {
        push @{ $w->{is_chosen} }, @{ $self->{parent_wells}->{ $w->{well_id} } }
            if $self->{parent_wells}->{ $w->{well_id} };
    }

}

sub get_priority_count {
    my ( $self, $mgi_gene_id ) = @_;

    ### get_priority_count: $mgi_gene_id
    $self->{priority_counts}->{ $mgi_gene_id } || 0;
}

sub get_epd_distribute_count {
    my ( $self, $mgi_gene_id ) = @_;

    ### get_epd_distribute_count: $mgi_gene_id    
    $self->{epd_distribute_counts}->{$mgi_gene_id} || 0;
}

sub get_design_well {
    my ( $self, $well ) = @_;

    ### get_design_well: $well->well_id
    
    my $candidate_design_well = $well;
    while ( $candidate_design_well ) {
        if ( $candidate_design_well->plate->type eq 'DESIGN' ) {
            return $candidate_design_well;
        }
        $candidate_design_well = $candidate_design_well->parent_well;
    }
    
    return;
}

sub is_in_recovery {
    my ( $self, $mgi_gene_id ) = @_;

    ### is_in_recovery: $mgi_gene_id

    $self->{genes_in_recovery}->{$mgi_gene_id};
}

sub get_regeneron_status {
    my ( $self, $mgi_gene ) = @_;

    ### get_regeneron_status: $mgi_gene->mgi_accession_id
    
    if ( $self->{regeneron_status} and $mgi_gene->mgi_accession_id ) {
        return $self->{regeneron_status}->status_for( $mgi_gene->mgi_accession_id );
    }

    return 'ERROR: lookup failed!';
}

sub get_well_data_the_hard_way {
    my ( $self, $well_id ) = @_;

    ### get_well_data_the_hard_way: $well_id
    $self->log->debug( "get_well_data_the_hard_way: $well_id" );
    
    my $well = $self->schema->resultset( 'HTGTDB::Well' )->find(
        { well_id => $well_id }, 
        { prefetch => [ 'plate', 'well_data' ] }
    );
    
    unless ( $well ) {
        $self->log->error( "failed to retrieve well(well_id=$well_id)" );
        return;
    }
    
    my ( $cassette, $backbone, $pg_pass_level );
    foreach my $well_data ( $well->well_data ) {
        if ( $well_data->data_type eq 'cassette' ) {
            $cassette = $well_data->data_value;
        }
        elsif ( $well_data->data_type eq 'backbone' ) {
            $backbone = $well_data->data_value;
        }
        elsif ( $well_data->data_type eq 'pass_level' ) {
            $pg_pass_level = $well_data->data_value;
        }
    }
    
    my %data = (
        design_instance_id => $well->design_instance_id,
        pgdgr_plate        => $well->plate->name,
        pgdgr_well         => $well->well_name,
        pgdgr_well_id      => $well->well_id,
        cassette           => $cassette,
        backbone           => $backbone,
        pg_pass_level      => $pg_pass_level,
    );
    
    my $project = $self->schema->resultset( 'HTGTDB::Project' )->search(
        {
            design_instance_id => $well->design_instance_id
        },
        {
            prefetch => [ 'mgi_gene' ]
        }
    )->first;
    
    if ( $project ) {
        $data{mgi_gene_id}          = $project->mgi_gene_id;
        $data{marker_symbol}        = $project->mgi_gene->marker_symbol;
        $data{ensembl_gene}         = $project->mgi_gene->ensembl_gene_id;
        $data{vega_gene}            = $project->mgi_gene->vega_gene_id;
        $data{tm}                   = $project->mgi_gene->tm;
        $data{sp}                   = $project->mgi_gene->sp;
        $data{mgi_gt_count}         = $project->mgi_gene->mgi_gt_count;
        $data{sponsor}              = $project->sponsor;
        $data{priority_count}       = $self->get_priority_count( $project->mgi_gene_id ); 
        $data{epd_distribute_count} = $self->get_epd_distribute_count( $project->mgi_gene_id );
        $data{regeneron_status}     = $self->get_regeneron_status( $project->mgi_gene );
    }
    
    my $design_well;
    while ( $well ) {
        if ( $well->plate->type eq 'DESIGN' ) {
            $design_well = $well;
            last;
        }
        $well = $well->parent_well;
    }
    
    if ( $design_well ) {
        $data{design_plate} = $design_well->plate->name;
        $data{design_well}  = $design_well->well_name;
    }

    return \%data;
}

sub get_well_data {
    my ( $self, $well_id ) = @_;

    ### get_well_data: $well_id

    my $ws = $self->schema->resultset('HTGTDB::WellSummaryByDI')->search(
        { pgdgr_well_id => $well_id },
        { prefetch => { project => 'mgi_gene' } }
    )->first;
    
    unless ( $ws ) {
        $self->log->info( "failed to retrieve well_summary_by_di(pgdgr_well_id=$well_id)" );
        return $self->get_well_data_the_hard_way( $well_id );
    }
    
    return {
        mgi_gene_id          => $ws->project->mgi_gene_id,
        design_instance_id   => $ws->design_instance_id,
        marker_symbol        => $ws->project->mgi_gene->marker_symbol,
        ensembl_gene         => $ws->project->mgi_gene->ensembl_gene_id,
        vega_gene            => $ws->project->mgi_gene->vega_gene_id,
        tm                   => $ws->project->mgi_gene->tm,
        sp                   => $ws->project->mgi_gene->sp,
        mgi_gt_count         => $ws->project->mgi_gene->mgi_gt_count,
        design_plate         => $ws->design_plate_name,
        design_well          => $ws->design_well_name,
        pgdgr_plate          => $ws->pgdgr_plate_name,
        pgdgr_well           => $ws->pgdgr_well_name,
        pgdgr_well_id        => $ws->pgdgr_well_id,
        cassette             => $ws->cassette,
        backbone             => $ws->backbone,
        pg_pass_level        => $ws->pg_pass_level,
        sponsor              => $ws->project->sponsor,
        priority_count       => $self->get_priority_count( $ws->project->mgi_gene_id ),
        epd_distribute_count => $self->get_epd_distribute_count( $ws->project->mgi_gene_id ),
        regeneron_status     => $self->get_regeneron_status( $ws->project->mgi_gene ),
    };
}

sub stringify_chosen {
    ### stringify_chosen
    
    my %chosen;
    foreach my $w ( @_ ) {
        my $plates = $w->{is_chosen}
            and not $chosen{ $w->{clone_name} }
                or next;
        $chosen{ $w->{clone_name} } = join q{,}, sort { $a cmp $b } uniq( @{ $plates } );
    }
    
    join q{ }, map "$_($chosen{$_})", sort { $a cmp $b } keys %chosen;
}

sub get_alternates_data {
    my ( $self, $mgi_gene_id, $design_instances ) = @_;

    ### get_alternates_data: $mgi_gene_id
    
    my @data;
    while ( my ( $di, $wells ) = each %{ $design_instances } ) {
        my @wells_384 = grep $_->{is_384}, values %{ $wells };
        $self->log->debug( @wells_384 . " 384-plate wells" );        
        my $chosen_str = stringify_chosen( @wells_384 );
        foreach my $alt ( grep $_->{distribute} && !$_->{is_chosen}, @wells_384 ) {
            my $wd = $self->get_well_data( $alt->{well_id} );
            $wd->{chosen_clones} = $chosen_str;
            push @data, $wd;
        }
    }

    ### get_alternates_data returning: @data
    
    return @data;
}

sub get_no_alternates_data {
    my ( $self, $mgi_gene_id, $design_instances ) = @_;

    ### get_no_alternates_data: $mgi_gene_id
    
    my @data;
    while ( my ( $di, $wells ) = each %{ $design_instances } ) {
        my @wells_384 = grep $_->{is_384}, values %{ $wells };
        $self->log->debug( @wells_384 . " 384-plate wells" );   
        foreach my $chosen ( grep $_->{distribute} && $_->{is_chosen}, @wells_384 ) {
            my $wd = $self->get_well_data( $chosen->{well_id} );
            $wd->{chosen_clones} = stringify_chosen( $chosen );
            delete $wd->{$_} for qw( pgdgr_plate pgdgr_well );
            push @data, $wd;
        }
    }

    ### get_no_alternates_data returning: @data
    
    return @data;
}

sub get_alternate_clone_recovery_wells {
    my ( $self ) = @_;
    
    ### get_alternate_clone_recovery_wells
       
    my @wells = $self->schema->resultset( 'HTGTDB::Well' )->search(
        {
            'plate_data.data_type'  => 'alternate_clone_recovery',
            'plate_data.data_value' => 'yes' 
        },
        {
            join => { 'plate' => 'plate_data' }
        }
    );

    return \@wells;
}

sub delete_unsuitable_alternates {
    my ( $self, $wells ) = @_;

    ### delete_unsuitable_alternates

    # If a gene has no TM or SP, clones with an ST cassette should not
    # be offered as alternates; see RT#161583.

    # SP/TM property will be the same for all wells
    my $clone = ( values %{ $wells } )[0];
    return if $clone->{sp} or $clone->{tm};
    
    while ( my ( $well_id, $well ) = each %{ $wells } ) {
        next unless $well->{is_384}
            and $well->{distribute}
                and $IS_ST_CASSETTE{ $well->{cassette} }
                    and not $well->{is_chosen};
        ### Deleting alternate with ST cassette: $well_id
        delete $wells->{ $well_id };
    }   
}

sub has_alternates {
    my ( $self, $design_instances ) = @_;
    ### has_alternates
    foreach my $well ( map values %$_, values %{ $design_instances } ) {
        return 1 if $well->{is_384} and $well->{distribute} and not $well->{is_chosen};
    }
    ### has_alternates returning false
    return;
}

sub has_alternates_with_promoter {
    my ( $self, $design_instances ) = @_;
    ### has_alternates_with_promoter
    foreach my $well ( map values %$_, values %{ $design_instances } ) {
        return 1 if $well->{is_384} and $well->{distribute} and not $well->{is_chosen}
            and not $IS_PROMOTORLESS_CASSETTE{ $well->{cassette} };
    }
    ### has_alternates_with_promoter returning false
    return;
}

sub is_suitable_for_promotorless_recovery {
    my ( $self, $design_instances ) = @_;

    my @clones =  map values %$_, values %{ $design_instances };

    my $clone = shift @clones; # the data we're interested in is the same for each clone, so
                               # we just look at the first one
    
    if ( $clone->{sp} or $clone->{tm} or ( $clone->{mgi_gt_count} || 0 ) < $MIN_PROMOTORLESS_TRAPS ) {
        ### clone is not suitable for promotorless recovery: $clone
        return 0;
    }

    return 1;
}

sub delete_promotorless {
    my ( $self, $design_instances ) = @_;
    ### delete_promotorless in: scalar keys %{$design_instances}

    while ( my ( $di, $wells ) = each %{ $design_instances } ) {
        while ( my ( $well_id, $well ) = each %{ $wells } ) {
            if ( $IS_PROMOTORLESS_CASSETTE{ $well->{cassette} } ) {
                delete $design_instances->{ $well_id };
            }
        }
        delete $design_instances->{ $di } unless keys %{ $design_instances->{ $di } };
    }

    ### delete_promotorless out: scalar keys %{$design_instances}

    return $design_instances;
}

sub get_recovery_data {
    my ( $self ) = @_;

    ### get_recovery_data
    
    $self->init();

    my $for_recovery = $self->get_clones_for_recovery();

    ### genes for recovery: scalar keys %{ $for_recovery }

    foreach my $design_instances_for_gene ( values %{ $for_recovery } ) {
        foreach my $wells_for_di ( values %{ $design_instances_for_gene } ) {
            $self->flag_chosen( $wells_for_di );
            $self->delete_unsuitable_alternates( $wells_for_di );
        }
    }

    my ( @in_recovery, @with_promoter, @without_promoter,  @no_alternates );

    while ( my ( $gene, $design_instances ) = each %{ $for_recovery } ) {
        if ( $self->has_alternates_with_promoter( $design_instances ) ) {
            ### has alternates with promoter: $gene
            push @with_promoter, $self->get_alternates_data( $gene, $self->delete_promotorless( $design_instances ) );
        }
        elsif ( $self->is_suitable_for_promotorless_recovery( $design_instances ) and $self->has_alternates( $design_instances ) ) {
            ### has alternates without promoter: $gene
            push @without_promoter, $self->get_alternates_data( $gene, $design_instances );
        }
        else {
            ### no alternates: $gene
            push @no_alternates, $self->get_no_alternates_data( $gene, $design_instances );
        }
    }

    foreach my $well ( @{ $self->get_alternate_clone_recovery_wells } ) {
        my $wd = $self->get_well_data_the_hard_way( $well->well_id );
        $wd->{chosen_clones} = $well->well_data_value( 'clone_name' );
        push @in_recovery, $wd;
    }
    

    $self->log->debug( sub { scalar( uniq( map $_->{mgi_gene_id}, @with_promoter ) ) . " genes with alternates with promoter" } );
    $self->log->debug( sub { scalar( uniq( map $_->{mgi_gene_id}, @without_promoter ) ) . " genes with alternates without promoter" } );   
    $self->log->debug( sub { scalar( uniq( map $_->{mgi_gene_id}, @no_alternates ) ) . " genes with no alternates" } );
    $self->log->debug( sub { scalar( uniq( map $_->{mgi_gene_id}, @in_recovery ) ) . " genes in recovery" } );

    return {
        with_promoter    => $self->sort_rows( \@with_promoter ),
        without_promoter => $self->sort_rows( \@without_promoter ),
        no_alternates    => $self->sort_rows( \@no_alternates ),
        in_recovery      => $self->sort_rows( \@in_recovery ),
    };
}

1;

__END__
