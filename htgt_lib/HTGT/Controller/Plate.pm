package HTGT::Controller::Plate;

# $Id: Plate.pm 7649 2012-09-18 15:23:33Z af11 $
# $HeadURL:$
# $LastChangedDate:$
# $LastChangedRevision:$
# $LastChangedBy:$
#

use strict;
use warnings;
use base 'Catalyst::Controller';
use Regexp::Common qw /number/;
use DateTime;
use JSON;
use HTGT::Utils::RegeneronGeneStatus;
use Carp qw(confess);
use HTGT::Utils::AlterParentWell;
use HTGT::Constants qw( %RANKED_QC_RESULTS %CASSETTES %PLATE_TYPES @PIQ_SHIPPING_LOCATIONS @PIQ_HIDE_WELL_DATA);
use List::MoreUtils qw( uniq );

=head1 NAME

HTGT::Controller::Plate - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for all main methods for Plates.

=head1 METHODS

=cut

=head2 index 

Redirect to 'show_list'

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for( '/plate/list' ) );
}

=head2 get_plate_blob

Helper method to return the contents of a PlateBlob object.

=cut

sub get_plate_blob : Local {
    my ( $self, $c ) = @_;
    my $plate_blob = $c->model( 'HTGTDB::PlateBlob' )->find( { plate_blob_id => $c->req->params->{ plate_blob_id } } );

    if ( $c->req->params->{ thumbnail } ) {
        if ( $plate_blob->image_thumbnail ) {
            $c->res->content_type( $plate_blob->binary_data_type );
            $c->res->body( $plate_blob->image_thumbnail );
        }
        else {
            $c->stash->{template} = '404.tt';
            $c->res->status( 404 );
        }
    }
    else {
        $c->res->content_type( $plate_blob->binary_data_type );
        $c->res->header( "Content-Disposition", "inline; filename=" . $plate_blob->file_name );
        $c->response->body( $plate_blob->binary_data );
    }
}

=head2 list

Page to display a list of all plates in the system and some associated data.

=head2 _list

Helper function for 'list' that does the actual work - can be called via ajax.

=cut

sub list : Local {
    my ( $self, $c ) = @_;
    my %list_plate_types = %PLATE_TYPES;
    $c->stash->{plate_types} = \%list_plate_types;
    unless ( $c->req->params->{ order } ) { $c->req->params->{ order } = 'asc'; }
    if ( $c->req->params->{ type } ) { $self->_list( $c ); }
}

sub _list : Local {
    my ( $self, $c ) = @_;
    my $order_by;
    if ( $c->req->params->{ order } eq 'desc') {
        $order_by = { -desc => 'name' };
    }
    elsif ( $c->req->params->{ order } eq 'asc' ) {
        $order_by = { -asc => 'name' };
    }

    # Set up the paginated resultset
    my $plate_rs = $c->model( 'HTGTDB::Plate' )->search(
        {},
        {
            rows     => 100,
            page     => $c->req->params->{ page } ? $c->req->params->{ page } : 1,
            order_by => $order_by
        }
    );

    # Special case for PG plates...
    if ( $c->req->params->{ type } eq 'PG' ) {
        $plate_rs = $plate_rs->search(
            {
                type                    => 'PGD',
                'plate_data.data_type'  => 'is_384',
                'plate_data.data_value' => 'yes'
            },
            { join => [ 'plate_data' ] }
        );
    }

    # and PGS plates...
    elsif ( $c->req->params->{ type } eq 'PGS' ) {
        $plate_rs = $plate_rs->search( { type => 'PGD' } );
    }
    else {
        $plate_rs = $plate_rs->search( { type => $c->req->params->{ type } } );
    }

    # Calculate the pagination info...
    my $data_page_obj = $plate_rs->pager();
    use Data::Pageset;
    $c->stash->{ page_info } = Data::Pageset->new(
        {
            'total_entries'    => $data_page_obj->total_entries(),
            'entries_per_page' => $data_page_obj->entries_per_page(),
            'current_page'     => $data_page_obj->current_page(),
            'pages_per_set'    => 5,
            'mode'             => 'slide'
        }
    );
    $c->stash->{ plate_count } = $data_page_obj->total_entries();

    # Now add more to the query...
    my @plates         = ();
    my %plate_comments = ();
    my $plate_data     = {};

    # Add in a little error catching
    if ( $c->stash->{ plate_count } > 0 ) {

        # Pre-fetch plate comments if we have any...
        my $plate_comment_rs = $c->model( 'HTGTDB::PlateComment' )
            ->search( { plate_id => [ $plate_rs->get_column( 'me.plate_id' )->all() ] }, { order_by => { -asc => 'created_date' } } );
        while ( my $comment = $plate_comment_rs->next ) {
            $plate_comments{ $comment->plate_id } = $comment->plate_comment;
        }

        # Pre-fetch plate_data if we have any...
        my $plate_data_rs
            = $c->model( 'HTGTDB::PlateData' )->search( { plate_id => [ $plate_rs->get_column( 'me.plate_id' )->all() ] }, {} );
        while ( my $data = $plate_data_rs->next ) {
            $plate_data->{ $data->plate_id }->{ $data->data_type } = $data->data_value;
        }
    }

    while ( my $plate = $plate_rs->next ) {

        # Suppress these DESIGN plates
        if ( $c->req->params->{ type } eq 'DESIGN' ) {
            if (   $plate->name eq '2000'
                || $plate->name eq '1'
                || $plate->name eq '1000'
                || $plate->name eq 'GR2'
                || $plate->name eq 'GR3'
                || $plate->name eq 'GR4' )
            {
                next;
            }
        }

        my $plate_info = {};
        $plate_info->{ plate_id }     = $plate->plate_id;
        $plate_info->{ type }         = $plate->type;
        $plate_info->{ name }         = $plate->name;
        $plate_info->{ description }  = $plate->description;
        $plate_info->{ created_user } = $plate->created_user;
        $plate_info->{ edited_user }  = $plate->edited_user;
        $plate_info->{ created_date } = $plate->created_date;
        $plate_info->{ edited_date }  = $plate->edited_date;
        $plate_info->{ plate_obj }    = $plate;

        # Last plate comment
        $plate_info->{ last_comment } = $plate_comments{ $plate->plate_id };

        # Plate data
        foreach my $data_type ( keys %{ $plate_data->{ $plate->plate_id } } ) {
            $plate_info->{ $data_type } = $plate_data->{ $plate->plate_id }->{ $data_type };
        }

        push( @plates, $plate_info );
    }

    $c->stash->{ plates } = \@plates;

    # Finally re-stash the plate type and query order...
    $c->stash->{ plate_type }  = $c->req->params->{ type };
    $c->stash->{ query_order } = $c->req->params->{ order };
}

sub show_list : Local {

    # Now deprecated function (07-May-2009), remove in a few weeks after we
    # know its really not needed.

    my ( $self, $c ) = @_;

    my @plates
        = sort { $a->name cmp $b->name } $c->model( 'HTGTDB::Plate' )->search( {}, { prefetch => q(plate_data) } )->all;

    my %plates_by_type;

    foreach my $plate ( @plates ) {

        #$c->log->debug( "looking at plate " . $plate->name );
        if (   $plate->name eq '2000'
            || $plate->name eq '1'
            || $plate->name eq '1000'
            || $plate->name eq 'GR2'
            || $plate->name eq 'GR3'
            || $plate->name eq 'GR4' )
        {
            next;
        }

        my $plate_info = {};
        $plate_info->{ plate_id }     = $plate->plate_id;
        $plate_info->{ type }         = $plate->type;
        $plate_info->{ name }         = $plate->name;
        $plate_info->{ description }  = $plate->description;
        $plate_info->{ created_user } = $plate->created_user;
        $plate_info->{ edited_user }  = $plate->edited_user;
        $plate_info->{ created_date } = $plate->created_date;
        $plate_info->{ edited_date }  = $plate->edited_date;
        $plate_info->{ plate_obj }    = $plate;

        # Get the last noted plate comment
        my $pc = $plate->plate_comments->search( {}, { order_by => { -desc => 'created_date' } } )->first;

        # TODO: do a proper order by query?!? - or better given prefetch sort on dates
        $plate_info->{ last_comment } = $pc->plate_comment if $pc;

        # Get the associated plate data
        my @plate_data = $plate->plate_data;
        foreach my $data ( @plate_data ) {
            $plate_info->{ $data->data_type } = $data->data_value;
        }

        push @{ $plates_by_type{ $plate->type } }, $plate_info;
    }

    my @plate_type_list = qw(DESIGN PCS PGD PGR PGG EP EPD REPD FP RS GR GRD);

    $c->stash->{ plate_types }    = \@plate_type_list;
    $c->stash->{ plates_by_type } = \%plates_by_type;
}

=head2 create

Method to generate a page for creating new plate entries.

=head2 create384

Simple form for creating a 384 well plate - this is done by creating 4 or more child (96 well) 
plates from a parent plate.  We've set things up this way as 384 well plates are just multiple 
replicates of a single 96 well plate anyway.  The 384 plates will be easily found in the system 
as they have an extra '_1/2/3/4' suffix and also a PlateData entry of 'is_384' -> 'yes'.

=cut

sub create : Local {
    my ( $self, $c ) = @_;
    unless ( $c->check_user_roles( q(edit) ) ) {
        $c->flash->{ error_msg } = "You are not authorised to use this function";
        $c->response->redirect( $c->uri_for( '/' ) );
        return 0;
    }
    $c->stash->{ piq_shipping_locations } = \@PIQ_SHIPPING_LOCATIONS;
    my %ignore_plate_types = map{ $_ => 1 } qw( PG PC DESIGN GT GRQ );
    my %create_plate_types = map{ $_ => $PLATE_TYPES{$_} } grep{ not exists $ignore_plate_types{$_} } keys %PLATE_TYPES;
    $c->stash->{plate_types} = \%create_plate_types; 
}

sub create384 : Local {
    my ( $self, $c ) = @_;
    unless ( $c->check_user_roles( q(edit) ) ) {
        $c->flash->{ error_msg } = "You are not authorised to use this function";
        $c->response->redirect( $c->uri_for( '/' ) );
        return 0;
    }
    use HTGTDB::WellData;
    $c->stash->{ cassettes } = HTGTDB::WellData::get_all_cassettes();
    $c->stash->{ backbones } = HTGTDB::WellData::get_all_backbones();
}

=head2 _get_plate_wells

Method to be used via an Ajax call to generate a (non-editable) table of all
of the wells and their associated data from a given plate_id.  Output comes as 
a preformatted HTML table via the template file 'plate/wells.tt'

INPUT: plate_id

=cut

sub _get_plate_wells : Local {
    my ( $self, $c ) = @_;

    # Get the plate object...
    my $plate = $self->find( $c, { prefetch => { wells => q(well_data) } } );

    # Get all of the wells for the plate and all of the associated 'well_data'...
    my ( $well_data, $well_data_types ) = fetch_wells( $self, $c, $plate );

    #This is a hack - if the ordering is not to your taste - hash it out
    $well_data_types = _order_displayed_data( $c, $self, $well_data, $well_data_types );

    $c->stash->{ plate }           = $plate;
    $c->stash->{ well_data }       = $well_data;
    $c->stash->{ well_data_types } = $well_data_types;
    $c->stash->{ timestamp }       = DateTime->now;
    $c->stash->{ create_page }     = 1;
    $c->stash->{ template }        = 'plate/wells.tt';
}

=head2 _order_displayed_data

A hacky little routine to change the order of columns presented to the user.
This was a request from Wendy B.

INPUT: called by _get_plate_wells with $c, $self, the data-headers and data
OUTPUT: a list of sorted table headers - order specified by Wendy (B).

=cut

sub _order_displayed_data : Local {
    my ( $c, $self, $data, $headers ) = @_;
    my @tmp = ();
    for ( @$headers ) {
        if ( /dna_quality|gene_name|parent_plate|parent_well|pass_level|qctest_result_id/i ) {
            push @tmp, $_;
        }
        else {
            unshift @tmp, $_;
        }
    }
    return ( \@tmp );
}

=head2 _get_plate_desc

Method to be used as part of an Ajax call to get the description for a plate.

INPUT: plate_id

=cut

sub _get_plate_desc : Local {
    my ( $self, $c ) = @_;

    # Get the plate object...
    my $plate = $c->model( 'HTGTDB::Plate' )->find( { plate_id => $c->req->params->{ plate_id } } );
    if   ( defined $plate->description ) { $c->res->body( $plate->description ); }
    else                                 { $c->res->body( $plate->name ); }
}

=head2 _get_plate_type

Method to be used as part of an Ajax call to get the type value for a plate.

INPUT: plate_id

=cut

sub _get_plate_type : Local {
    my ( $self, $c ) = @_;

    # Get the plate object...
    my $plate = $c->model( 'HTGTDB::Plate' )->find( { plate_id => $c->req->params->{ plate_id } } );
    if   ( defined $plate->type ) { $c->res->body( $plate->type ); }
    else                          { $c->res->body( $plate->name ); }
}

=head2 _is_plate_locked

Method to be used as part of an Ajax call to get the 'is_locked' value for a plate.

INPUT: plate_id

=cut

sub _is_plate_locked : Local {
    my ( $self, $c ) = @_;

    # Get the plate object...
    my $plate = $self->find( $c, {} );

    if ( $plate->is_locked eq 'y' ) {
        $c->res->body( 'true' );
    }
    else {
        $c->res->body( 'false' );
    }
}

=head2 _prep_new_plate

Method to be used via an Ajax call (on the 'plate/create' page) to generate 
a blank table signifying the layout of a new plate - this is then populated 
via javascript and entered into the database.

INPUT: plate_type

=cut

sub _prep_new_plate : Local {
    my ( $self, $c ) = @_;

    # First, figure out if we're working on an existing plate and/or get the type

    my $plate = $self->find( $c, { prefetch => { wells => q(well_data) } } );

    # Now, from the plate type, work out the dimensions and
    # wells in the plate

    my $plate_type;
    if   ( $plate ) { $plate_type = $plate->type; }
    else            { $plate_type = $c->req->params->{ plate_type }; }

    my @plate_wells;
    if ( $c->req->params->{ plate_order } eq 'row' ) {
        @plate_wells = HTGTDB::Plate::get_default_well_names( $plate_type, 1 );
    }
    else {
        @plate_wells = HTGTDB::Plate::get_default_well_names( $plate_type );
    }

    # Finally, if we're editing an existing plate, match the generated
    # well names with the existing wells in the database

    my %well_info;

    if ( $plate ) {

        my %exist_well_info;
        foreach ( $plate->wells ) {
            my $exist_well_name = $_->well_name;
            my $exist_parent_well;
            my $exist_parent_well_id;
            my $exist_parent_plate;
            my $exist_parent_plate_id;

            eval {
                $exist_parent_well     = $_->parent_well->well_name;
                $exist_parent_well_id  = $_->parent_well->well_id;
                $exist_parent_plate    = $_->parent_well->plate->name;
                $exist_parent_plate_id = $_->parent_well->plate->plate_id;
            };

            $exist_well_info{ $exist_well_name } = {
                parent_well     => $exist_parent_well,
                parent_well_id  => $exist_parent_well_id,
                parent_plate    => $exist_parent_plate,
                parent_plate_id => $exist_parent_plate_id
            };
        }

        foreach my $new_well ( @plate_wells ) {
            foreach my $exist_well ( keys %exist_well_info ) {
                if ( $exist_well =~ /$new_well/ ) {
                    $well_info{ $new_well } = {
                        well_name       => $exist_well,
                        parent_well     => $exist_well_info{ $exist_well }->{ parent_well },
                        parent_well_id  => $exist_well_info{ $exist_well }->{ parent_well_id },
                        parent_plate    => $exist_well_info{ $exist_well }->{ parent_plate },
                        parent_plate_id => $exist_well_info{ $exist_well }->{ parent_plate_id }
                    };
                }
            }
        }

    }

    $c->stash->{ plate }     = $plate;
    $c->stash->{ timestamp } = $c->req->params->{ timestamp };
    $c->stash->{ wells }     = \@plate_wells;
    $c->stash->{ well_info } = \%well_info;
    $c->stash->{ template }  = 'plate/_new_plate_table.tt';
}

=head2 find

Common to code to find a plate in HTGTDB given an id, or name. Takes context, 
and optionally DBIx::Class find attributes, then an existing plate object. 
Returns a plate object and sets up stash.
 
=cut

#TODO: tidy the logic up here....
sub find : Local {
    my ( $self, $c, $findattr, $plate ) = @_;
    $findattr ||= {};

    my $plate_id = $c->req->params->{ plate_id };

    # Get all of the wells for the plate and all of the associated 'well_data'...
    if ( $plate ) {
        die "Conflicting Plate object with id " . $plate->id . " and given plate id $plate_id"
            if ( $plate_id and ( $plate->id != $plate_id ) );
    }
    elsif ( $plate_id ) {
        $plate = $c->model( 'HTGTDB::Plate' )->search( { 'me.plate_id' => $plate_id }, $findattr )->first;
        unless ( $plate ) {
            my $error_msg = "No plate with given plate_id $plate_id\n";
            $c->stash->{ error_msg } = $error_msg;
            die $error_msg;
        }
    }

    my $platename = $plate ? $plate->name : $c->req->params->{ plate_name };
    my $platetype = $plate ? $plate->type : $c->req->params->{ plate_type };
    if (    ( not $plate )
        and $platename
        and my $platers
        = $c->model( 'HTGTDB::Plate' )->search( { name => $platename, ( $platetype ? ( type => $platetype ) : () ) }, $findattr ) )
    {
        $plate = $platers->next;
        if ( $platers->next ) {    #note that count couldn't be used here with prefetching
            my $error_msg = "More than one plate has the given name $platename" . ( $platetype ? " and type $platetype" : "" ) . "\n";
            $c->stash->{ error_msg } = $error_msg;
            die $error_msg;
        }
    }

    if ( ( not $plate ) and $c->req->params->{ well_id } ) { $plate = find_well( $self, $c )->plate; }

    if ( $plate ) {
        $platetype = $plate->type;
        $platename = $plate->name;
    }

    $c->stash->{ plate } = $plate;

    return $plate;
}

=head2 find_well

Common to code to find a well in HTGTDB given an id, or name and plate. 
Takes context, and optionally DBIx::Class find parameters, then an existing 
well object. Returns a well object and sets up stash.

=cut

#TODO: tidy the logic up here....
sub find_well : Local {
    my ( $self, $c, $findparam, $well ) = @_;
    $findparam ||= {};

    #return $c->stash->{well} if $c->stash->{well} or $c->stash->{wellname}; #Avoid repeated look ups?
    my $well_id = $c->req->params->{ well_id };

    # Get all of the wells for the plate and all of the associated 'well_data'...
    if ( $well ) {
        die "Conflicting Well object with id " . $well->id . " and given well id $well_id" unless $well->id == $well_id;
    }
    elsif ( $well_id ) {
        $well = $c->model( 'HTGTDB::Well' )->find( { well_id => $well_id }, $findparam );
        unless ( $well ) {
            my $error_msg = "No well with given well_id $well_id\n";
            $c->stash->{ error_msg } = $error_msg;
            die $error_msg;
        }
    }
    my $wellname = $well ? $well->well_name : $c->req->params->{ well_name };
    my $plate = $well ? $self->find( $c, undef, $well->plate ) : $self->find( $c, { prefetch => q(wells) } );
    if ( ( not $well ) and $wellname and $plate ) {
        $well = $plate->wells->find( { well_name => $wellname } );
    }

    #$c->log->debug("$well well");
    $c->stash->{ wellname } = $wellname;
    $c->stash->{ well }     = $well;

    $c->stash->{ template } = 'plate/view.tt';    #CLUDGE!!!! temporary?
    return $well;
}

=head2 fetch_wells_potentialQC

Helper method to fetch all parent wells QC for a plate (or as temporary hack for GR/EPD one to one QC results).

INPUT:  A plate
OUTPUT: A referenced hash containing the wells and their data (keyed by well 
        name, then data_type), and a referenced array containing the data_types 
        in the order we'd wish t display them.

=cut

sub fetch_wells_potentialQC : Private {

    # Get plate info from QC....
    my ( $self, $c, $plate, $qctest_run_id ) = @_;
    my @qcoriginplates;
    my %plate_wells;
    my $di_rs = $c->model( q(HTGTDB::DesignInstance) );
    

    # If we're looking for clone info by plate and the design/well it is chosen to represent
    if($qctest_run_id){
        my $rs;
        #ÊFIRST LOOK UP THE QC-TEST-RUN with an explicit id, passed in from the plate
        
        $rs = $c->model('ConstructQC::QctestResult')->search(
            {
                'me.qctest_run_id'                => $qctest_run_id,
                'me.is_best_for_construct_in_run' => 1
            },
            {
                join => [ 'constructClone', 'qctestRun' ],
                prefetch => 'constructClone'
            }
        );
         
        # THEN LOAD UP ALL THE RESULTS ON THE QCTEST-RUN

        #@qcoriginplates = sort $rs->get_column(q(constructClone.plate))->func(q(DISTINCT))->all;
        @qcoriginplates = sort keys %{ { map { $_ => 1 } $rs->get_column( q(constructClone.plate) )->all } };

        # $c->log->debug($rs->count." QC results");
        # $c->log->debug(" from ".join(", ",@qcoriginplates));

        my %pesw;    # tmp store for expected engineered seq to its well
        for my $qr ( $rs->all ) {
            $pesw{ $qr->constructClone->plate }->{ $qr->expected_engineered_seq_id } = $qr->constructClone->well;
        }
        for my $wn ( map { values %$_ } values %pesw ) {
            $plate_wells{ $wn } = {};
        }

        
        #this should be written unless (keys %pesw); The scalar is not needed.
        @qcoriginplates = () unless scalar( keys %pesw );

        # for my $esw (values %pesw) {
        #    $c->log->debug(scalar(keys %$esw)." expected seq");
        #    $c->log->debug(scalar(keys %{{map{$_=>1}values %$esw}})." expected seq wells");
        # }

        my %done;

        $c->log->debug('before FIRST: number of reads in resultset: '.$rs->count);
        for my $qr ( $rs->all ) {

            # find any marked for distribution
            if ( $qr->distribute_for_engseq ) {
                my $wr = $plate_wells{ $pesw{ $qr->constructClone->plate }->{ $qr->distribute_for_engseq } };
                $done{ $wr } = q(distributed);
                my $distributedEngineeredSeq = $qr->distributedEngineeredSeq;
                die join( ", ", "qr id:" . $qr->id, "distribute_for_engseq:" . $qr->distribute_for_engseq )
                    unless $distributedEngineeredSeq;
                my $di_id = $qr->distributedEngineeredSeq->syntheticVector->design_instance_id;
                my $di    = $di_rs->find( { design_instance_id => $di_id } );
                push(
                    @{ $wr->{ potential_QC } },
                    {
                        qctest_run_id      => $qr->qctest_run_id,
                        qctest_result_id   => $qr->id,
                        design_instance_id => $di_id,
                        clone_name         => $qr->constructClone->name,
                        pass_level         => $qr->chosen_status || $qr->pass_status,
                        qc_assignment      => q(distributed),
                        ( $di ? ( design_instance => $di->platewelldesign ) : () )
                    }
                );
            }
        }
        

        # else find any marked chosen (manual best in run)
        for my $qr ( $rs->all ) {
            if ( $qr->is_chosen_for_engseq_in_run ) {

                # Arrrrrgh dud value - this is not meant to work like a boolean!!!!!!!!!!
                next if $qr->is_chosen_for_engseq_in_run == 1;
                my $wr = $plate_wells{ $pesw{ $qr->constructClone->plate }->{ $qr->is_chosen_for_engseq_in_run } };
                next if $done{ $wr } and $done{ $wr } ne q(chosen);
                $done{ $wr } = q(chosen);
                my $chosenEngineeredSeq = $qr->chosenEngineeredSeq;
                die join( ", ", "qr id:" . $qr->id, "is_chosen_for_engseq_in_run:" . $qr->is_chosen_for_engseq_in_run )
                    unless $chosenEngineeredSeq;
                my $di_id = $qr->chosenEngineeredSeq->syntheticVector->design_instance_id;
                my $di    = $di_rs->find( { design_instance_id => $di_id } );
                $c->log->debug("pushing");
                push(
                    @{ $wr->{ potential_QC } },
                    {
                        qctest_run_id      => $qr->qctest_run_id,
                        qctest_result_id   => $qr->id,
                        design_instance_id => $di_id,
                        clone_name         => $qr->constructClone->name,
                        pass_level         => $qr->chosen_status || $qr->pass_status,
                        qc_assignment      => q(chosen),
                        ( $di ? ( design_instance => $di->platewelldesign ) : () )
                    }
                );
            }
        }
        
        # else find any automatically chosen as best in run
        for my $qr ( $rs->all ) {
            if ( $qr->engineered_seq_id ) {
                my $wr = $plate_wells{ $pesw{ $qr->constructClone->plate }->{ $qr->engineered_seq_id } };
                next if $done{ $wr } and $done{ $wr } ne q(matched);
                $done{ $wr } = q(matched);
                my $matchedEngineeredSeq = $qr->matchedEngineeredSeq;
                die join( ", ", "qr id:" . $qr->id, "engineered_seq_id:" . $qr->engineered_seq_id ) unless $matchedEngineeredSeq;
                my $di_id = $qr->matchedEngineeredSeq->syntheticVector->design_instance_id;
                my $di    = $di_rs->find( { design_instance_id => $di_id } );
                push(
                    @{ $wr->{ potential_QC } },
                    {
                        qctest_run_id      => $qr->qctest_run_id,
                        qctest_result_id   => $qr->id,
                        design_instance_id => $di_id,
                        clone_name         => $qr->constructClone->name,
                        pass_level         => $qr->chosen_status || $qr->pass_status,
                        qc_assignment      => q(matched),
                        ( $di ? ( design_instance => $di->platewelldesign ) : () )
                    }
                );
            }
        }

        $c->stash->{ parentqc_types } = [ qw(qctest_result_id design_instance_id clone_name status selection) ];
        $c->stash->{ qcoriginplates } = \@qcoriginplates;
    }

    return
        \%plate_wells,
        ( keys %plate_wells ? [ keys %{ { map { $_ => 1 } map { keys %{ $_ } } values %plate_wells } } ] : [] );
}

=head2 well_relations

Provides a view of a well's heirarchy of related wells.

=cut

sub well_relations : Local {
    my ( $self, $c, $findparam, $well ) = @_;
    my $root = $self->find_well( $c, $findparam, $well );
    my $i = 0;
    while ( $root and my $tmp = $root->parent_well ) {
        $root = $tmp;
        die "Probable well ancestory loop!\n"
            if ++$i > 10;
    }
    $c->stash->{ rootwell } = $root;

    #  my ( $self, $c, @well_ids) = @_;
    #  @well_ids = $c->req->params->{well_id};
    #  my $m = $c->model(q(HTGTDB));
    #  my $dbh= $m->storage->dbh;
    #  my $sth = q|select distinct well_id from (select * from well connect by prior parent_well_id=well_id start with well_id = ?) where parent_well_id is null|;

    my @c = well_relations_HTML_table_rows( $root );
    $c->stash->{ table }
        = "<style>table.wellrelations td{vertical-align: middle;}</style><table class='wellrelations'><tr>"
        . join( "</tr><tr>", @c )
        . "</tr></table>";

    $c->stash->{ template } = 'plate/well_relations.tt';
}

=head2 well_relations_HTML_table_rows

Utility function to provide HTML table row contents indicating the child generations of the given well.

=cut

sub well_relations_HTML_table_rows {
    my ( $well ) = @_;

    my @childHTML;
    my $crs = $well->child_wells->search( {}, { order_by => { -asc => 'well_name' } } );
    while ( my $c = $crs->next ) { push @childHTML, well_relations_HTML_table_rows( $c ); }

    my $wn = $well->well_name;
    $wn = ( length( $wn ) < 4 ? $well->plate->name . " " : "" ) . $wn;

    #my $thisHTML = "<td>$wn (".$well->id.")</td>";
    #return map{$thisHTML.$_}(scalar(@childHTML)?@childHTML:(""));
    $childHTML[ 0 ]
        = "<td"
        . ( scalar( @childHTML ) ? " rowspan=" . scalar( @childHTML ) : ( "" ) )
        . ">$wn ("
        . $well->id
        . ")</td>"
        . $childHTML[ 0 ];
    return @childHTML;
}

=head2 fetch_wells

Helper method to fetch all the given wells and their associated 'well_data'
for a plate.

INPUT:  A plate (DBIx::Class) object
OUTPUT: A referenced hash containing the wells and their data (keyed by well 
        name, then data_type), and a referenced array containing the data_types 
        in the order we'd wish t display them.

=cut

sub fetch_wells : Private {
    my ( $self, $c, $plate, $rsattr ) = @_;

    # Get all of the wells for the plate and all of the associated 'well_data'...
    my %plate_wells;
    my %well_data_types;
    my %repeated_data_type;
    my %repeated_data_type_well;
    my %repeated_wellname;
    my %mismatch_design_instance;
    my %dodgy_design_instance;
    my %electroporated_wells;
    my %total_epd_dist_count_for_gene;
    my %sp_tm_for_gene;
    
    my $regeneron_status = eval {
        HTGT::Utils::RegeneronGeneStatus->new( $c->model( 'IDCCMart' ) );
    };
    if ( $@ ) {
        $c->log->error( "failed to create HTGT::Utils::RegeneronGeneStatus: $@" );
    }

    if ( defined $plate ) {
        if ( defined $rsattr ) {
            $plate = $c->model( 'HTGTDB::Plate' )->find( { plate_id => $plate->id }, $rsattr );
        }
    }
    else {
        $c->flash->{ error_msg } = 'Sorry, plate "' . $c->req->params->{ plate_name } . '" was not found.';
        $c->response->redirect( $c->uri_for( '/' ) );
        return;
    }

    # For PGS/PRPGS/PGG plates, we need to look up the siblings of each well (i.e. if we are
    # working with PGS00099_B - we need to check PGS00099_[ACD] etc. to see if the
    # gene/well we are currently working on has already been electroporated) - having
    # this query up front will help speed things up (rather than doing it by well)...
    # ALSO - look up epd_distribute counts well-by-well in one hit (via the project-table)
    # PCS and EP plate also need epd_distribute counts

    if ( $plate->type =~ /PG[DSG]|PCS|EP/ ) {

        # Look up already electroporated wells for each GENE for each well on this plate and store in the
        # %electroporated_wells hash (rm7, 2010-03-30); resolves RT#163643.
        my $epod_sql = <<'EOT';
select distinct target_well.design_instance_id, ep_well.well_id, ep_well.well_name
from well target_well
join plate target_plate on target_plate.plate_id = target_well.plate_id
join project target_project on target_project.design_instance_id  = target_well.design_instance_id
join project ep_project on ep_project.mgi_gene_id = target_project.mgi_gene_id
join well ep_well on ep_well.design_instance_id = ep_project.design_instance_id
join plate ep_plate on ep_plate.plate_id = ep_well.plate_id and ep_plate.type = 'EP'
where target_plate.plate_id = ?
and target_well.design_instance_id is not null
EOT
        my $epod_sth = $c->model( 'HTGTDB' )->storage->dbh->prepare( $epod_sql );
        $epod_sth->execute( $plate->plate_id );
        while ( my ( $design_instance_id, $well_id, $well_name ) = $epod_sth->fetchrow_array ) {
            push @{ $electroporated_wells{ $design_instance_id } }, { well_id => $well_id, well_name => $well_name };
        }

        # Look up epd_distribute counts for each GENE for each well on this plate, and store in temp hash
        # by well_id. This hash is looked up when the well_data hash is filled in for each well.
        my $epd_sql = <<'EOT';
select target_well.well_id, count(distinct epd_well.well_id)
from well epd_well
join well_data on well_data.well_id = epd_well.well_id and well_data.data_type = 'distribute' and well_data.data_value = 'yes'
join plate on plate.plate_id = epd_well.plate_id and plate.type = 'EPD'
join project on project.design_instance_id = epd_well.design_instance_id
join project target_project on target_project.mgi_gene_id = project.mgi_gene_id
join well target_well on target_well.design_instance_id = target_project.design_instance_id
join plate target_plate on target_plate.plate_id = target_well.plate_id
where target_plate.plate_id = ?
group by target_well.well_id
EOT

        my $sth = $c->model( 'HTGTDB' )->storage->dbh->prepare( $epd_sql );
        $sth->execute( $plate->plate_id );
        while ( my @row = $sth->fetchrow_array ) {
            $total_epd_dist_count_for_gene{ $row[ 0 ] } = $row[ 1 ];
        }

        # Look up SP and TM flags for each GENE on this plate
        my $sp_tm_sql = qq[
        select well.well_id, mgi_gene.sp, mgi_gene.tm
        from well
        join project on project.design_instance_id = well.design_instance_id
        join mgi_gene on mgi_gene.mgi_gene_id = project.mgi_gene_id
        where well.plate_id = ?
        ];

        $sth = $c->model( 'HTGTDB' )->storage->dbh->prepare( $sp_tm_sql );
        $sth->execute( $plate->plate_id );
        while ( my @row = $sth->fetchrow_array ) {
            my $is_sp = $row[1] ? 'yes' : 'no';
            my $is_tm = $row[2] ? 'yes' : 'no';
            $sp_tm_for_gene{ $row[0] } = { SP => $is_sp, TM => $is_tm };
        }
    }

    # Prefetch the well_data for all wells on this plate - speeds things up by a couple of seconds

    my @well_ids = $plate->wells->get_column( 'well_id' )->all();
    my $well_data_rs = $c->model( 'HTGTDB::WellData' )->search( { well_id => \@well_ids } );
    my $unprocessed_well_data;
    while ( my $well_data = $well_data_rs->next ) {
        if ( exists $unprocessed_well_data->{ $well_data->well_id }->{ $well_data->data_type } ) {
            $repeated_data_type{ $well_data->data_type }++;
            $repeated_data_type_well{ $well_data->well->well_name }++;
        }
        else {
            $unprocessed_well_data->{ $well_data->well_id }->{ $well_data->data_type } = $well_data->data_value;
        }
    }

    # Part of the nasty hack for removing these bits of well data
    # this is supposed to be a temp hack b4 darren redoes this nightmare
    my %headers = (
        pcr_u        => 0,
        pcr_d        => 0,
        pcr_d        => 0,
        pcr_g        => 0,
        rec_u        => 0,
        rec_d        => 0,
        rec_g        => 0,
        rec_ns       => 0,
        postcre      => 0,
        rec_comment  => 0,
        'rec-result' => 0,
    );

    #Find out if certain types of QC band info have been entered
    my $tr_pcr_done;
    my $gr_pcr_done;
    my $gf_pcr_done;
    if ( $plate->type eq 'EPD' ) {
        $tr_pcr_done = $well_data_rs->search( { data_type => 'primer_band_tr_pcr' } )->count;
        $gr_pcr_done = $well_data_rs->search( { data_type => [ 'primer_band_gr3', 'primer_band_gr4' ] } )->count;
        $gf_pcr_done = $well_data_rs->search( { data_type => [ 'primer_band_gf3', 'primer_band_gf4' ] } )->count;

        #my $fp_seq_done = $well_data_rs->search({data_type=>'five_arm_pass_level'})->count;
    }

    # This is a small optimization for the EPD QC calling
    my $five_arm_qc_ran;
    if ( $plate->type eq 'EPD' ) {
        if ( $plate->have_i_had_five_arm_qc ) { $five_arm_qc_ran = 1; }
    } 

    my $view = $c->req->params->{'view'};
    if ( $plate->type eq 'PIQ' and ( !$view or $view ne 'csvdl' ) ){
        map{ $headers{$_} = 0 } @PIQ_HIDE_WELL_DATA;
    }

    foreach my $well ( $plate->wells ) {

        # We use this hash to store all the info about each well
        my %well_data;

        # Store well name / id / di_id
        $well_data{ well_id }            = $well->well_id;
        $well_data{ well_name }          = $well->well_name;
        $well_data{ design_instance_id } = $well->design_instance_id;

        # Store all the 'well_data' information...
        my $unprocd_well_data_hash = $unprocessed_well_data->{ $well->well_id };

        foreach my $data_type ( keys %{ $unprocd_well_data_hash } ) {

            next if exists $headers{ $data_type };

            $well_data_types{ $data_type }++;

            # This is a nasty hack to avoid dumping data.

            # Filter numbers and text.
            # If int or text, leave alone.
            # If float, do some manipulation.
            if ( $unprocd_well_data_hash->{ $data_type } and $unprocd_well_data_hash->{ $data_type } =~ /^$RE{num}{real}$/
                and not $unprocd_well_data_hash->{ $data_type } =~ /^\d+$/ )
            {

                # Apply specific formatting to the following datatypes:
                #  - ug DNA => 1 decimal place
                #  - Vol {DNA,mix,water} => 0 decimal places
                # All others => 3 decimal places

                if ( $data_type =~ /UG_DNA|NG_UL_DNA/ ) {
                    $well_data{ $data_type } = sprintf( "%.1f", $unprocd_well_data_hash->{ $data_type } );
                }
                elsif ( $data_type =~ /VOL_/ ) { $well_data{ $data_type } = sprintf( "%.0f", $unprocd_well_data_hash->{ $data_type } ); }
                else                           { $well_data{ $data_type } = sprintf( "%.3f", $unprocd_well_data_hash->{ $data_type } ); }
            }
            elsif ( $data_type eq 'new_qc_test_result_id' ) {
                my $qc_test_result_id = $unprocd_well_data_hash->{new_qc_test_result_id};                
                delete $well_data_types{$data_type};
                $well_data_types{qc_test_result}++;
                $well_data{qc_test_result} = sprintf( '<a href="%s">%s</a>',
                                                      $c->uri_for( "/newqc/view_result/$qc_test_result_id" ),
                                                      substr( $qc_test_result_id, 0, 8 ) );                
            }            
            else {
                $well_data{ $data_type } = $unprocd_well_data_hash->{ $data_type };
            }
        }

        if ( $well->design_instance_jump ) {
            $well_data{ design_instance_jumps } = 1;
        }

        # Store extra info relating to the design (gene id / exons / phase etc)
        if ( $well->design_instance_id ) {
            if ( my $di
                = $c->model( 'HTGTDB::DesignInstance' )
                ->find( { design_instance_id => $well->design_instance_id }, { prefetch => { design => 'start_exon' } } ) )
            {

                # Design id
                $well_data_types{ design }++;
                $well_data{ design }    = $di->platewelldesign;
                $well_data{ design_id } = $di->design_id;

                # Validated by annotation flag
                $well_data_types{ validated_by_annotation }++;
                if ( defined $di->design->validated_by_annotation ) {
                    $well_data{ validated_by_annotation } = $di->design->validated_by_annotation;
                }
                else { $well_data{ validated_by_annotation } = "not done"; }

                # Phase
                $well_data_types{ phase }++; 
                if   ( defined $di->design->phase ) {
                    $well_data{ phase } = $di->design->phase;
                }
                elsif ( $di->design->is_artificial_intron ) {
                    $well_data{ phase } = 'UNKNOWN';
                }
                else {
                    $well_data{ phase } = $di->design->start_exon->phase;
                }

                
                if ($plate->type eq 'PGG' || $plate->type eq 'PIQ'){
                    # design type
                   $well_data_types{ design_type }++;
                   if ( defined $di->design->design_type ){
                       if ($di->design->design_type =~ 'Del' ){
                           $well_data{ design_type } = 'Deletion';
                       }elsif($di->design->design_type =~ 'Ins'){
                           $well_data{ design_type } = 'Insertion';
                       }else{
                           $well_data{ design_type } = 'KO';
                       }
                   }else{
                       $well_data{ design_type } = 'KO';
                   }
                }
                # change this bit to draw data from mgi_gene , mgi_sanger & project table
                # Gene id's (Otter / Ensembl / MGI Symbol)
                my $otter_id;
                my $ensembl_id;
                my $source;

                eval {

                    my @projects = $c->model( 'HTGTDB::Project' )->search( { design_instance_id => $well->design_instance_id } );

                    # only choose first project for now
                    my $mgi_gene       = $projects[ 0 ]->mgi_gene;
                    my $priority_count = scalar( $mgi_gene->gene_user_links );

                    #$c->log->debug("mgi_gene: ".$mgi_gene->marker_symbol." here's the priority: $priority_count");
                    $well_data{ priority_count } = $priority_count;
                    $well_data_types{ priority_count }++;

                    $well_data{ gene_name } = $mgi_gene->marker_symbol;

                    # get ensembl id
                    $ensembl_id = $mgi_gene->ensembl_gene_id || "";
                    if ( $ensembl_id eq "" ) {

                        # look for mgi_sanger table
                        my @mgi_sanger_genes = $mgi_gene->mgi_sanger_genes;
                        foreach my $gene ( @mgi_sanger_genes ) {
                            if ( $gene->origin eq "ensembl" ) {
                                $ensembl_id = $gene->sanger_gene_id;
                            }
                        }
                    }
                    $well_data_types{ ensembl_id }++;
                    $well_data{ ensembl_id } = $ensembl_id;

                    # get otter id
                    $otter_id = $mgi_gene->vega_gene_id || "";
                    if ( $otter_id eq "" ) {

                        # look for mgi_sanger table
                        my @mgi_sanger_genes = $mgi_gene->mgi_sanger_genes;
                        foreach my $gene ( @mgi_sanger_genes ) {
                            if ( $gene->origin eq "vega" ) {
                                $otter_id = $gene->sanger_gene_id;
                            }
                        }
                    }
                    $well_data_types{ otter_id }++;
                    $well_data{ otter_id } = $otter_id;

                    # get the KOMP-Regeneron gene status
                    $well_data_types{regeneron_status}++;
                    if ( $regeneron_status ) {
                        $well_data{regeneron_status}
                            = $regeneron_status->status_for( $mgi_gene->mgi_accession_id ) || '';
                    }
                    else {
                        $well_data{regeneron_status} = 'ERROR: lookup failed!';
                    }

                    $well_data_types{ project }++;
                    $well_data{ project } = $projects[ 0 ]->sponsor;
                };
            }
            else { $dodgy_design_instance{ $well->well_name }++; }
        }

        # If we have a parent well - gather and store relevant information depending on the plate type
        if ( my $pw = $well->parent_well ) {

            # Deal with the parent well info...
            $well_data_types{ parent_well }++;
            $well_data{ parent_well }               = $pw->well_name;
            $well_data{ parent_well_id }            = $pw->well_id;
            $well_data{ parent_design_instance_id } = $pw->design_instance_id;
            $well_data{ parent_plate }              = $pw->plate->name;

            # Do we need to display the parent plate?
            if ( length( $pw->well_name ) < 5 ) { $well_data_types{ parent_plate }++; }
            $well_data{ parent_plate_id } = $pw->plate->plate_id;

            # Extra info for FP plates...
            if ( $plate->type eq 'FP' and $pw->parent_well_id ) {

                # ES Cell line
                my @es_cell_line
                    = $pw->parent_well->plate->plate_data->search( data_type => 'es_cell_line' )->get_column( 'data_value' )->all;
                if ( @es_cell_line ) { $well_data_types{ es_cell_line }++; $well_data{ es_cell_line } = \@es_cell_line; }

                # Prefetch the needed well data (one lookup as opposed to 12)
                my $well_data_rs = $c->model( 'HTGTDB::WellData' )->search(
                    {
                        well_id => [ $pw->well_id, $pw->parent_well->parent_well_id ],
                        data_type => [ 'qctest_result_id', 'pass_level','distribute', 'targeted_trap', 'COMMENTS', 'PG_CLONE', 'clone_name' ,'do_not_ep' ]
                    }
                );
                
                # Add the parent (EPD) QC calls
                if ( $c->check_user_roles("edit") ) {
                  $well_data{ "3' arm" } = $pw->three_arm_pass_level;
                  $well_data{ "loxP" }   = $pw->loxP_pass_level;
                  $well_data{ "5' arm" } = $pw->five_arm_pass_level;
                  
                  $well_data_types{ "3' arm" }++;
                  $well_data_types{ "loxP" }++;
                  $well_data_types{ "5' arm" }++;
                }
                
                # Stash the info we need
                while ( my $well_data_obj = $well_data_rs->next ) {
                    if ( $well_data_obj->well_id == $pw->well_id ) {
                        if ( $well_data_obj->data_type eq 'qctest_result_id' ) {
                            $well_data_types{ qctest_result_id }++;
                            $well_data{ qctest_result_id } = $well_data_obj->data_value;
                        }
                        elsif($well_data_obj->data_type eq 'targeted_trap'){
                           $well_data_types{ targeted_trap }++;
                           $well_data{ targeted_trap } = $well_data_obj->data_value;
                        }
                        elsif ( $well_data_obj->data_type eq 'distribute' ) {
                           $well_data_types{ parent_distribute }++;
                           $well_data{ parent_distribute } = $well_data_obj->data_value;
                        }
                        elsif ( $well_data_obj->data_type eq 'COMMENTS' ) {
                            $well_data_types{ parent_comments }++;
                            $well_data{ parent_comments } = $well_data_obj->data_value;
                        }
                    }
                    elsif ( $well_data_obj->well_id == $pw->parent_well->parent_well_id ) {
                        if ( $well_data_obj->data_type eq 'qctest_result_id' ) {
                            $well_data_types{ vector_qc }++;
                            $well_data{ vector_qc } = $well_data_obj->data_value;
                        }
                        elsif ( $well_data_obj->data_type eq 'pass_level' ) {
                            $well_data_types{ vector_qc_result }++;
                            $well_data{ vector_qc_result } = $well_data_obj->data_value;
                        }
                        elsif ( $well_data_obj->data_type eq 'clone_name' ) {
                            $well_data_types{ pg_clone }++;
                            $well_data{ pg_clone } = $well_data_obj->data_value;
                        }
                    }
                }
            }

            # Extra info for GRD plates...
            elsif ( $plate->type eq 'GRD' ) {
                my $well_data_rs = $c->model( 'HTGTDB::WellData' )
                    ->search( { well_id => [ $pw->well_id ], data_type => [ 'qctest_result_id', 'pass_level' ] } );

                while ( my $well_data_obj = $well_data_rs->next ) {
                    if ( $well_data_obj->data_type eq 'qctest_result_id' ) { $well_data{ gr_qc_id } = $well_data_obj->data_value; }
                    elsif ( $well_data_obj->data_type eq 'pass_level' ) {
                        $well_data_types{ gr_qc }++;
                        $well_data{ gr_qc } = $well_data_obj->data_value;
                    }
                }
            }

            # Extra info for PGG plates...
            elsif ( $plate->type eq 'PGG' ) {
                my $well_data_rs = $c->model( 'HTGTDB::WellData' )
                    ->search( { well_id => [ $pw->well_id ], data_type => [ 'qctest_result_id', 'pass_level' ] } );

                while ( my $well_data_obj = $well_data_rs->next ) {
                    if ( $well_data_obj->data_type eq 'qctest_result_id' ) { $well_data{ pgs_qc_id } = $well_data_obj->data_value; }
                    elsif ( $well_data_obj->data_type eq 'pass_level' ) {
                        $well_data_types{ pgs_pass_level }++;
                        $well_data{ pgs_pass_level } = $well_data_obj->data_value;
                    }
                }
            }
            
            # Extra info for GRQ alternate clone recovery plates...
            elsif ( $plate->type eq 'GRQ' and $plate->plate_data_value('alternate_clone_recovery') ) {
                $well_data_types{$_}++ for qw( sequencing_plate_label sequencing_archive_label sequencing_384_well_location);
                $well_data{sequencing_plate_label}       = $pw->plate->plate_data_value( 'plate_label' );
                $well_data{sequencing_384_well_location} = $pw->to384;
                $well_data{sequencing_archive_label}     = $pw->plate->plate_data_value( 'archive_label' );
            }

            elsif ( $plate->name =~ /^LOA/ ) {
                $well_data{ taqman_assays } = get_taqman_assay_information( $well ); 
                $well_data_types{ taqman_assays }++;
            }

            elsif ( $plate->type eq 'SBDNA' || $plate->type eq 'QPCRDNA' ) {
                $well_data{ taqman_assays } = get_taqman_assay_information( $well ); 
                $well_data_types{ taqman_assays }++;

                $well_data{ piq_well } = $self->get_piq_well( $c, $pw );
                $well_data_types{ piq_well }++;
            }

            # Extra info for EPD plates...
            elsif ( $plate->type eq 'EPD' && $c->check_user_roles( 'edit' ) ) {
                # 5'/3'/loxP QC calls
                $well_data{ "3' arm" } = $well->three_arm_pass_level;
                $well_data{ "loxP" }   = $well->loxP_pass_level;
                $well_data{ "5' arm" } = $well->five_arm_pass_level;
                
                # add LOA info here
                my $repository_qc = $well->repository_qc_result;
                if ( $repository_qc ) {
                    $well_data{ loa } = $repository_qc->loss_of_allele ;
                    $well_data_types{ loa }++;
                    $well_data{ threep_loxp_taqman } = $repository_qc->threep_loxp_taqman;
                    $well_data_types{ threep_loxp_taqman }++;
                }
               
                my $loa_qc_result = get_repd_well_qc_results($well, 'loa_qc_result');
                if ($loa_qc_result) {
                    if ( $well_data{ loa } ) {
                        #we have both davis and our loa results, ours takes priority
                        $well_data{ loa } = $loa_qc_result;
                    }
                    else {
                        $well_data{ loa } = $loa_qc_result;
                        $well_data_types{'loa'}++;
                    }
                }
                
                my $threep_loxp_taqman = get_repd_well_qc_results($well, 'taqman_loxp_qc_result');
                if ($threep_loxp_taqman) {
                    if ( $well_data{ threep_loxp_taqman } ) {
                        #we have both davis and our threep_loxp_taqman results, ours takes priority
                        $well_data{ threep_loxp_taqman } = $threep_loxp_taqman;
                    }
                    else {
                        $well_data{ threep_loxp_taqman } = $threep_loxp_taqman;
                        $well_data_types{'threep_loxp_taqman'}++;
                    }
                }
                
                # Fetch grandparent (PGS) data
                if ( my $gpw = $pw->parent_well ) {
                    $well_data_types{ grand_parent_well }++;
                    $well_data_types{ grand_parent_plate }++;
                    $well_data{ grand_parent_well }               = $gpw->well_name;
                    $well_data{ grand_parent_well_id }            = $gpw->well_id;
                    $well_data{ grand_parent_design_instance_id } = $gpw->design_instance_id;
                    $well_data{ grand_parent_plate }              = $gpw->plate->name;
                    $well_data{ grand_parent_plate_id }           = $gpw->plate->plate_id;
                }
                
            }
            elsif ( $plate->type =~ /^PIQ/ && $c->check_user_roles( 'edit' )  ) {
                my ($epd_well, $epd_plate) = $well->ancestor_well_plate_of_type('EPD');
                my ($fp_well, $fp_plate)   = $well->ancestor_well_plate_of_type('FP');
                
                $well_data_types{ clone_number }++;
                $well_data{ es_cell_line } = $well->es_cell_line;
                
                if ( $epd_well ) {
                    $well_data_types{ es_cell_line }++;
                    $well_data{ clone_number } = $epd_well->well_name;
                }

                if ( $fp_well ) {
                    $well_data_types{ FP_well }++;
                    $well_data{ FP_well }      = $fp_well->well_name;
                }

                if ( $plate->type eq 'PIQ' ) {
                    $well_data{ taqman_assays } = get_taqman_assay_information( $well ); 
                    $well_data_types{ taqman_assays }++;

                    $well_data{ sbdna } = get_dna_plate_qc( $epd_well, 'SBDNA' );
                    $well_data_types{ sbdna }++;

                    $well_data{ qpcrdna } = get_dna_plate_qc( $epd_well, 'QPCRDNA' );
                    $well_data_types{ qpcrdna }++;
                }

                if ( $plate->type eq 'PIQFP' ) {
                    $well_data_types{ lab_number }++;
                    $well_data{ lab_number } = $pw->well_data_value('lab_number');
                }
                
                if ( $plate->type eq 'PIQS' ) {
                    my ($piq_well, $piq_plate) = $well->ancestor_well_plate_of_type('PIQ');
                    my @piq_data_types = (
                        'loa_pass','loxp_pass', 'lacz_pass', 'chr1_pass',  
                        'chr8a_pass' ,'chr11a_pass','chr8b_pass', 'chr11b_pass', 
                        'chry_pass', 'lrpcr_pass', 'sb_pass', 
                        'lab_number', 'thaw_well_size', 'targeting_pass', 'chromosome_fail'
                    );
                    if ( $piq_well ) {
                        for my $piq_data_type ( @piq_data_types ) {
                            $well_data_types{ $piq_data_type }++;
                            $well_data{ $piq_data_type } = $piq_well->well_data_value($piq_data_type);
                        }
                    }
                    
                    my ($piqfp_well, $piqfp_plate)   = $well->ancestor_well_plate_of_type('PIQFP');
                    my @piqfp_data_types = (
                        'ship_to',               'freeze_data_serum', 'freeze_location_serum', 'passage_serum',
                        'well_to_thaw_to_serum', 'freeze_date_2i',    'freeze_location_2i',    'passage_2i',    'well_to_thaw_to_2i'
                    );
                    if ( $piqfp_well ) {
                        for my $piqfp_data_type ( @piqfp_data_types ) {
                            $well_data_types{ $piqfp_data_type }++;
                            $well_data{ $piqfp_data_type } = $piqfp_well->well_data_value($piqfp_data_type);
                        }
                    }
                }
            }

            # check for design instance mismatch
            if ( my $di_id = $well->design_instance_id ) {
                $mismatch_design_instance{ $well->well_name }++ if ( $di_id != $pw->design_instance_id );
            }
        }

        # On PGS/PGD/PGG plates, check for sibling wells already being electroporated...
        # (this info was prefetched above for speed - just processing/storing here per well)
        # ...and flag SP/TM genes (data also prefetched for speed)
        if ( $plate->type =~ /PG[D|S|G]/ ) {            
            if ( my $well_set = $electroporated_wells{ $well->design_instance_id } ) {
                ### already electroporated wells: $well_set
                $well_data_types{ 'already_electroporated' }++;
                $well_data{ 'already_electroporated' } = $well_set;
            }

            $well_data{ epd_distribute_count } = $total_epd_dist_count_for_gene{ $well->well_id };
            $well_data_types{ epd_distribute_count }++;

            $well_data{ SP } = $sp_tm_for_gene{ $well->well_id }{SP};
            $well_data_types{ SP }++;
            $well_data{ TM } = $sp_tm_for_gene{ $well->well_id }{TM};
            $well_data_types{ TM }++;
        }
       
        if( $plate->type =~ /PCS|EP/){
            $well_data{ epd_distribute_count } = $total_epd_dist_count_for_gene{ $well->well_id };
            $well_data_types{ epd_distribute_count }++;
        }
        
        # If this is a 384 well plate, store the 384 well names
        my $is_384_data = $well->plate->plate_data->find( { data_type => 'is_384' }, { key => 'plate_id_data_type' } );
        eval {
            if ( $is_384_data->data_value and $is_384_data->data_value eq 'yes' )
            {
                $well_data_types{ '384_well_name' }++;
                $well_data{ '384_well_name' } = $well->to384;
            }
        };

        # If we have child wells - gather and store relevant info depending on the plate type
        my $child_well_rs = $well->child_wells;
        if ( $child_well_rs->count > 0 ) {

            my @child_well_ids = $child_well_rs->get_column( 'well_id' )->all();

            # We need to record REPD passes on EPD wells...
            my %child_well_pass_r;
            if ( $plate->type eq 'EPD' ) {
                my $well_data_rs = $c->model( 'HTGTDB::WellData' )->search( { well_id => \@child_well_ids, data_type => 'pass_r' } );

                while ( my $well_data = $well_data_rs->next ) {
                    $child_well_pass_r{ $well_data->well_id } = $well_data->data_value;
                }

                my $pass_r_count = $well_data_rs->count;
                if ( $pass_r_count > 0 ) {
                    $well_data_types{ pass_r_count }++;
                    $well_data{ pass_r_count } = $pass_r_count;
                }
            }

            # Finally, record the general info on the child wells...
            my @cws;
            foreach my $cw ( $child_well_rs->all() ) {
                if ( length( $cw->well_name ) < 5 ) {
                    push @cws,
                        {
                        name               => $cw->plate->name . '_' . $cw->well_name,
                        id                 => $cw->well_id,
                        design_instance_id => $cw->design_instance_id,
                        parent_did         => $well->design_instance_id,
                        pass_r             => $child_well_pass_r{ $cw->well_id },
                        design_instance_jumps => ( $cw->design_instance_jump ? 1 : 0 )
                        };
                }
                else {
                    push @cws,
                        {
                        name               => $cw->well_name,
                        id                 => $cw->well_id,
                        design_instance_id => $cw->design_instance_id,
                        parent_did         => $well->design_instance_id,
                        pass_r             => $child_well_pass_r{ $cw->well_id },
                        design_instance_jumps => ( $cw->design_instance_jump ? 1 : 0 )
                        };
                }
            }

            $well_data_types{ child_wells }++;
            $well_data{ child_wells } = \@cws;

        }

     
        # add do_not_ep flag to GRD/Q plate
        if ( $plate->type =~ /GR[D|Q]/ ){
            my @wds = $well->well_data;
            foreach my $wd ( @wds ){
                if ( $wd->data_type eq 'do_not_ep'){
                    if ( $wd->data_value eq 'yes'){
                        $well_data{ 'do_not_ep' } = 'DO_NOT_EP';
                        $well_data_types{ 'do_not_ep' }++;
                    }
                }
            }
        }

        # display parent well's do_not_ep flag in PGG plate
        if ( $plate->type =~ /PGG/ ){
            my $parent_well = $c->model('HTGTDB::Well')->find( { well_id => $well->parent_well_id } );
            
            if ($parent_well){
                my @pwds = $parent_well->well_data;
                foreach my $wd ( @pwds ){
                    if ( $wd->data_type eq 'do_not_ep'){
                        if ( $wd->data_value eq 'yes'){
                            $well_data{ 'do_not_ep' } = 'DO_NOT_EP';
                            $well_data_types{ 'do_not_ep' }++;
                        }
                    }
                }
            }
        }
        ##
        ## Now add the 'well_data' into the 'plate_wells' hash
        ##

        $repeated_wellname{ $well->well_name }++;
        $plate_wells{ $well->well_name } = \%well_data;
    }

    # Check for any errors and report them to the user...
    my @repeated_data_type_well = sort keys %repeated_data_type_well;
    my $error_msg               = $c->stash->{ error_msg };
    $error_msg
        .= " Data truncated due to repeated datatype(s) "
        . join( ", ", sort keys %repeated_data_type )
        . " found in "
        . ( @repeated_data_type_well < 6 ? join( ", ", @repeated_data_type_well ) : scalar( @repeated_data_type_well ) . " wells" ) . ". "
        if @repeated_data_type_well;
    {
        my %h;
        while ( my ( $k, $v ) = each %repeated_wellname ) { $h{ $k } = $v if $v > 1; }
        %repeated_wellname = %h;
    }
    $error_msg .= " Data truncated due to repeated wellnames " . join( ", ", sort keys %repeated_wellname ) . ". "
        if keys %repeated_wellname;
    my @dodgy_design_instance = sort keys %dodgy_design_instance;
    $error_msg
        .= " Problem design instances for "
        . ( @dodgy_design_instance > 5 ? scalar( @dodgy_design_instance ) . " wells" : join ", ", @dodgy_design_instance )
        if @dodgy_design_instance;
    my @mismatch_design_instance = sort keys %mismatch_design_instance;
    $error_msg
        .= " Parent design instance mismatchs for "
        . ( @mismatch_design_instance > 5 ? scalar( @mismatch_design_instance ) . " wells" : join ", ", @mismatch_design_instance )
        if @mismatch_design_instance;
    if ( $error_msg ) {
        $c->stash->{ error_msg } .= $error_msg;
        $c->log->warn( $error_msg );
    }

    my @data_types = sort keys %well_data_types;

    return ( \%plate_wells, \@data_types );
}

sub get_repd_well_qc_results {
    my ($well, $result_type) = @_;

    my $child_repd_wells
        = $well->child_wells->search_rs( { 'plate.type' => 'REPD' }, { join => 'plate' } );

    my @qc_results;
    while ( my $child_well = $child_repd_wells->next ) {
        my $qc_result = $child_well->well_data_value($result_type);
        next unless $qc_result;
        push @qc_results, $qc_result;
    }
    return unless scalar(@qc_results);

    if ( scalar(@qc_results) == 1 ) {
        return $qc_results[0];
    }
    else {
        my @sorted_qc_results = sort { $RANKED_QC_RESULTS{lc($a)} <=> $RANKED_QC_RESULTS{lc($b)}} @qc_results;
        return $sorted_qc_results[0];
    }
    return;
}

=head2 order_datatypes

Utility method taking context, a plate type and known data types and return a suitably ordered list of data types to be displayed as column headers

=cut

sub order_datatypes : Private {
    my ( $c, $platetype, @data_types ) = @_;

    # Use the method 'get_well_data_types' to get the important well data_types
    # for this plate type...
    my @important_data_types = (
        qw(COMMENTS project priority_count gene_name otter_id ensembl_id design phase),
        @{ get_well_data_types()->{ $platetype } || [] }
    );
    foreach ( @data_types ) {
        if ( /384_well_name/ ) { unshift( @important_data_types, "384_well_name" ); }
    }
    my %done_data_types = map { $_ => 1 } @important_data_types;

    # Now re-order the data_types to have specific details first and avoid repeats...
    if ( $c and $c->check_user_roles( 'edit' ) ) {
        return ( @important_data_types, grep { not $done_data_types{ $_ }++ } @data_types );
    }
    else {
        return HTGTDB::Plate::omit_well_data_types_for_noedit( @important_data_types, grep { not $done_data_types{ $_ }++ } @data_types );
    }
}

=head2 create_well_data_array

Utility method taking context, plate type (optionally), refs to hashes containing 
well to data hash, array(s) of data types. Returns an arrayref of hashes 
of well data per wellname, and an array ref of data types, array ref of 
well names, and a user readable string describing any data problems.

=cut

sub create_well_data_array {
    my $c = shift;
    my %well_data;
    my @wellnames;
    my %found_well_data_types;
    my %clashing_data_wells;
    my $platetype = ref $_[ 0 ] ? undef : shift;

    #@wellnames = HTGTDB::Plate::get_default_well_names($platetype);

    while ( @_ and ref $_[ 0 ] eq "HASH" ) {    #merge multiple data hashes passed as references
        my $wdh = shift @_;

        while ( my ( $wn, $wd ) = each %$wdh ) {    #get well name and data from input hash
            $wn = HTGTDB::Plate::parse_well_name( $wn )->{ well };

            my $ewd = $well_data{ $wn };
            $ewd = $well_data{ $wn } = {} unless $ewd;

            while ( my ( $dt, $dv ) = each %$wd ) {
                $found_well_data_types{ $dt }++;
                if ( exists( ${ $ewd }{ $dt } ) ) { $clashing_data_wells{ $wn }->{ $dt }++ unless $ewd->{ $dt } == $dv; }
                else                              { $ewd->{ $dt } = $dv; }
            }

        }

    }

    #Note remaining @_ should be compulsory data types in required order (after plate type specific)
    @wellnames = sort keys %{ { map { $_ => 1 } ( keys %well_data, @wellnames ) } };

    my @cdw = sort keys %clashing_data_wells;

    #my $daily_wtf++
    # Argh argh argh ... oh no ... what does this mean?  What kind of mind does this ... yes, another Daily WTF?
    return [
        map {
            {    # 1st return value is array ref, the array contains hashrefs
                well_name => $_,    # (where the hash contains well_name
                    %{ $well_data{ $_ } || {} }    #  + well data )
            }
            } @wellnames    # for each wellname from the  wellnames array
        ],
        [
        order_datatypes( $c, $platetype, @_ )    # The 2nd value returned is an array ref
        ],                                       # this array contains the order of well data types to be used in display
        \@wellnames,                             # The 3rd value arrayref for wellnames
        ( @cdw
        ? join( " ", "Clashing data for", @cdw, "wells" )
        : undef );                               #And finally a clashing data string if cdw exists or an undefined variable
}

=head2 get_well_data_types

Short method to return the essential well data_types (in the 'well_data' table) 
that must be present for a given plate type.

=cut

sub get_well_data_types {
  return {
    PCS => [ 'backbone', 'validated_by_annotation' ],
    PGD => [ 'cassette', 'backbone', 'DNA_STATUS', 'DNA_QUALITY', 'validated_by_annotation' ],
    PGR => [ 'cassette', 'backbone', 'validated_by_annotation' ],
    RS  => [ 'cassette', 'backbone', 'gateway_colony_number', 'pcs_growth' ],
    GR  => [ 'cassette', 'backbone', 'distribute', 'DNA_QUALITY', 'validated_by_annotation' ],
    GRD =>
     [ 'best', 'cassette', 'backbone', 'DNA_STATUS', 'DNA_QUALITY', 'DNA_QUALITY_COMMENTS', 'validated_by_annotation', 'do_not_ep', 'UG_DNA', 'NG_UL_DNA', 'gene_ident_qc' ],
    PGG => [ 'cassette', 'backbone', 'DNA_STATUS', 'DNA_QUALITY', 'validated_by_annotation', 'design_type' ],
    EP =>
     [ 'cassette', 'backbone', 'TOTAL_COLONIES', 'REMAINING_UNSTAINED_COLONIES', 'COLONIES_PICKED', 'validated_by_annotation' ],
    EPD => [
       'cassette',       'backbone',              'distribute',      q(5' arm),         'loxP',                q(3' arm),  'loa', 'threep_loxp_taqman', 'vec_int',
      'targeted_trap',   'pass_from_recovery_QC', 'exp_design_id',   'obs_design_id',   'pass_level',         'primer_band_tr_pcr',
      'primer_band_gf3', 'primer_band_gf4',       'primer_band_gr3', 'primer_band_gr4', 'synthetic_allele_id', 'child_wells',
      'pass_r_count',    'validated_by_annotation',
    ],
    REPD => [
      'cassette',        'backbone',        'exp_design_id',   'obs_design_id',   'pass_level',               'primer_band_tr_pcr',
      'primer_band_gf3', 'primer_band_gf4', 'primer_band_gr3', 'primer_band_gr4', 'target_region_pass_level', 'pass_r',
      'synthetic_allele_id', 'loa_qc_result', 'taqman_loxp_qc_result'
    ],
    FP => [
      'cassette', 'backbone',  'parent_distribute',  q(5' arm), 'loxP',  q(3' arm),
      'targeted_trap', 'parent_comments',  'qctest_result_id',
      'pg_clone', 'vector_qc', 'vector_qc_result',  'validated_by_annotation'
    ],
    PIQ => [
        'design_type', 'cassette', 'backbone', 'lab_number', 'FP_well', 'es_cell_line', 
        'loa_pass', 'lacz_pass', 'loxp_pass', 'chry_pass', 'chr1_pass',
        'chr8a_pass', 'chr8b_pass', 'chr11a_pass', 'chr11b_pass', 
        'primer_band_gf3', 'primer_band_gf4', 'primer_band_gr3', 'primer_band_gr4', 'lrpcr_pass',
        'sb_pass', 'targeting_pass', 'chromosome_fail', 'thaw_well_size','re-grow_requested', 'clone_number' 
    ],
    PIQFP => [
        'cassette', 'backbone', 'lab_number', 'clone_number', 'FP_well', 'es_cell_line', 'ship_to', 'freeze_data_serum',
        'freeze_location_serum', 'passage_serum', 'well_to_thaw_to_serum', 'freeze_date_2i', 'freeze_location_2i',
        'passage_2i', 'well_to_thaw_to_2i'
    ],
    PIQS => [
        'cassette', 'backbone', 'lab_number', 'clone_number', 'FP_well', 'es_cell_line', 'ship_to', 'freeze_data_serum',
        'passage_serum', 'well_to_thaw_to_serum', 'freeze_date_2i', 'passage_2i', 'well_to_thaw_to_2i', 
        'loa_pass', 'lacz_pass', 'loxp_pass', 'chry_pass', 'chr1_pass',
        'chr8a_pass', 'chr8b_pass', 'chr11a_pass', 'chr11b_pass', 'lrpcr_pass', 'sb_pass',
        'targeting_pass', 'chromosome_fail', 
    ],
    VTP => [
        'cassette', 'backbone'
    ]
  };
}

=head2 view

Subroutine to display the view/edit page for a given plate.

INPUT: plate_id

=cut

sub view : Local {
    my ( $self, $c ) = @_;

    $c->log_request();

    if ( $c->req->param( 'show_children' ) ) {
        $c->session->{ show_children } = $c->req->param( 'show_children' );
    }

    if ( $c->req->param( 'hide_plate_inheritance' ) ) {
        $c->stash->{ hide_plate_inheritance } = $c->req->param( 'hide_plate_inheritance' );
    }

    #Dan added for plate hack
    if ( $c->req->param( 'recombineering' ) and $c->req->param( 'recombineering' ) eq 'true' ) {
        my $plate = $self->find( $c, { prefetch => 'wells', order_by => { -asc => 'wells.well_name' } } );
        $c->stash->{ plate } = $plate;

        if ( !$c->check_user_roles( 'edit' ) ) {
            $c->flash->{ error_msg } = "Sorry, you are not authorised to use the recombineering page.";
            $c->response->redirect( $c->uri_for( '/' ) );
        }

        if ( $plate->type !~ /design/i ) {
            $c->flash->{ error_msg } = "Sorry, you can only edit recombineering information for design plates";
            $c->response->redirect( $c->uri_for( '/' ) );
        }

        $c->stash->{ recombineering } = 'true';
        my %rec_well_data = ();
        my %headers       = (
            pcr_u        => 0,
            pcr_d        => 0,
            pcr_d        => 0,
            pcr_g        => 0,
            rec_u        => 0,
            rec_d        => 0,
            rec_g        => 0,
            rec_ns       => 0,
            postcre      => 0,
            comment      => 0,
            'rec-result' => 0,
        );
        for my $pwell ( $plate->wells ) {
            for my $well_data ( $pwell->well_data ) {
                $rec_well_data{ $pwell->well_id }{ $well_data->data_type } = $well_data->data_value
                    if exists $headers{ $well_data->data_type };
            }
        }
        $c->stash->{ rec_well_data } = \%rec_well_data;
    }
    else {
        $self->wells( $c );
    }

    # Special case for plate blobs - fetch these seperately so that we avoid
    # recalling the whole blob on each page view...

    if ( my $plate = $c->stash->{ plate } ) {
        my @plate_blobs = $plate->plate_blobs->search(
            {},
            {
                columns => [
                    'plate_blob_id', 'plate_id',  'binary_data_type', 'image_thumbnail', 'file_name', 'file_size',
                    'description',   'is_public', 'edit_user',        'edit_date'
                ]
            }
        );
        $c->stash->{ plate_blobs } = \@plate_blobs;

        $c->audit_info( $plate->name );
    }
}

=head2 qc_view

subroutine to get phase1 phase2 qc view of each well

=cut

sub qc_view : Local {
    my ($self, $c) = @_;
    
    my $plate_name = $c->req->param( 'plate_name' );
    my $plate_id = $c->req->param( 'plate_id' );
   
    my $plate;
    
    if ($plate_name){
        $plate = $c->model('HTGTDB::Plate')->find( { name => $plate_name });
    }
    if ($plate_id) {
        $plate = $c->model('HTGTDB::Plate')->find( { plate_id => $plate_id });
    }
  
    unless ( defined $plate ) {
        if ($plate_name){
            $c->flash->{ error_msg } = 'Sorry, plate "' . $plate_name . '" was not found.';
        }else{
            $c->flash->{ error_msg } = 'Sorry, plate "' . $plate_id . '" was not found.';
        }
        
        $c->response->redirect( $c->uri_for( '/plate/list' ) );
        return;
    }
    
    $plate_name = $plate->name;
    my @wells = $plate->wells;
    my @qc_results;
    $c->log->debug("how many wells: ".scalar(@wells));
    foreach my $w (@wells){
        my $data;
        $data->{well_id} = $w->well_id;
        $data->{well_name} = $w->well_name;
        $data->{three_arm_pass_level} = $w->three_arm_pass_level;
        $data->{five_arm_pass_level} = $w->five_arm_pass_level;
        $data->{loxp_pass_level} = $w->loxP_pass_level;
        if ($w->distribute eq 'distribute'){
            $data->{distribute} = 'Yes';
        }elsif($w->distribute eq 'targeted_trap'){
            $data->{targeted_trap} = 'Yes';
        }
        
        my @well_data = $w->well_data;
        foreach my $wd (@well_data){
            if ($wd->data_type eq 'vec_int'){
                $data->{vec_int} = $wd->data_value;
            }
        }
        $data->{design_instance_id} = $w->design_instance_id;
        $data->{cassette} = $w->cassette;
        $data->{backbone} = $w->backbone;
        
        # GET the gene symbol
        my $project = $c->model('HTGTDB::Project')->search(  { design_instance_id => $w->design_instance_id } )->first();
        if ($project){            
            $data->{design_id} =  $project->design_id;
            if($project->design_id){
                $data->{phase} = $project->design->phase;
            }
            
            $data->{project} = $project->sponsor;
            
            my $mgi_gene = $c->model('HTGTDB::MGIGene')->find( { mgi_gene_id => $project->mgi_gene_id });
            if ($mgi_gene){
                $c->log->debug("found the mgi_gene.".$mgi_gene->marker_symbol);
                $data->{gene_symbol} = $mgi_gene->marker_symbol;
                $data->{ensembl_gene_id} = $mgi_gene->ensembl_gene_id;
                $data->{vega_gene_id} = $mgi_gene->vega_gene_id;
                $data->{priority_count} = scalar($mgi_gene->gene_user_links);
            }else{
                $c->log->debug("no mgi gene.");
            }
        }else{
            $c->log->debug("no project.");
        }
       
        # get repository qc result
        my $rep_qc_result = $w->repository_qc_result;
       
        if ($rep_qc_result){
          $data->{first_test_start_date} = $rep_qc_result->first_test_start_date;
          $data->{latest_test_completion_date} = $rep_qc_result->latest_test_completion_date;
          $data->{karyotype} = $rep_qc_result->karyotype_low."-".$rep_qc_result->karyotype_high;
          $data->{copy_number_equals_one} = $rep_qc_result->copy_number_equals_one;
          $data->{threep_loxp_srpcr} = $rep_qc_result->threep_loxp_srpcr;
          $data->{fivep_loxp_lrpcr} = $rep_qc_result->fivep_loxp_srpcr;
          $data->{vector_integrity} = $rep_qc_result->vector_integrity;
          $data->{loa} = $rep_qc_result->loss_of_allele;
          $data->{threep_loxp_taqman} = $rep_qc_result->threep_loxp_taqman;
        }else{
            $c->log->debug("no rep qc result...");
        }
        
        # get user qc result
        my $user_qc_result = $w->user_qc_result;
        if($user_qc_result){
            $data->{five_lrpcr} = $user_qc_result->five_lrpcr;
            $data->{three_lrpcr} = $user_qc_result->three_lrpcr;
        }else{
            $c->log->debug("no user qc result...");
        }
        
        push @qc_results, $data;
    }
    @qc_results = sort {($a->{well_name} cmp $b->{well_name})} @qc_results;
   
    $c->stash->{ qc_results } =\@qc_results;
    $c->stash->{ plate_name } = $plate_name;
    $c->stash->{ plate_id } = $plate_id;
    $c->stash->{ template } = 'plate/qc_view';
    
    my %csv_params = ( view => 'csvdl' );
    $csv_params{file}    = "repository_qc_result.csv";
    $csv_params{plate_id} = $plate_id;
    $csv_params{plate_name} = $plate_name;
    
    $c->stash->{csv_uri} = $c->uri_for( $c->action, \%csv_params );
}

=head2

subroutine to display a GRD plate view

=cut

sub grd_plate_view : Local {
    my ($self, $c) = @_;
    
    my $plate_name = $c->req->param( 'plate_name' );
    my $plate_id = $c->req->param( 'plate_id' );
   
    my $plate;
    if ($plate_name){
        $plate = $c->model('HTGTDB::Plate')->find( { name => $plate_name });
    }
    if ($plate_id) {
        $plate = $c->model('HTGTDB::Plate')->find( { plate_id => $plate_id });
    }
    
    unless ( defined $plate ) {
        if ($plate_name){
            $c->flash->{ error_msg } = 'Sorry, plate "' . $plate_name . '" was not found.';
        }else{
            $c->flash->{ error_msg } = 'Sorry, plate "' . $plate_id . '" was not found.';
        }
        
        $c->response->redirect( $c->uri_for( '/plate/list' ) );
        return;
    }
    
    $plate_name = $plate->name;
    my @wells = $plate->wells;
    my @all_data;
    
    foreach my $w (@wells){
        my $data;
        # get gene info
        $data->{well_name} = $w->well_name;
        $data->{design_instance_id} = $w->design_instance_id;
        $data->{cassette} = $w->cassette;
        $data->{backbone} = $w->backbone;
        $data->{well_id} = $w->well_id;
        
         # GET the gene symbol
        my $project = $c->model('HTGTDB::Project')->search({
            design_instance_id => $w->design_instance_id
        })->first();
        
        if ($project){            
            if($project->design_id){
                $data->{phase} = $project->design->phase;
            }
                         
            $data->{project} = $project->sponsor;
                            
            my $mgi_gene = $c->model('HTGTDB::MGIGene')->find( { mgi_gene_id => $project->mgi_gene_id });
            if ($mgi_gene){
                $data->{gene_symbol} = $mgi_gene->marker_symbol;
            }else{
                $c->log->debug("no mgi gene.");
            }
        }else{
            $c->log->debug("no project.");
        }
        
        my @well_data = $w->well_data;
        
        foreach my $wd (@well_data){
            if ($wd->data_type eq 'qctest_result_id'){
                $data->{qctest_result_id} = $wd->data_value;
            }
            if ($wd->data_type eq 'pass_level'){
                $data->{pass_level} = $wd->data_value;
            }
            if ( $wd->data_type eq 'do_not_ep') {
                if($wd->data_value eq 'yes'){
                    $data->{do_not_ep} = 'DO_NOT_EP';
                }
            }
        }
        
        # parent well
        my $parent_well = $c->model('HTGTDB::Well')->find( { well_id => $w->parent_well_id } ); 
        $data->{parent_well_name} = $parent_well->well_name;
        
        my $parent_plate = $c->model('HTGTDB::Plate')->find( { plate_id => $parent_well->plate_id } );
        $data->{parent_plate_name} = $parent_plate->name;
          
        # grand parent
        my $grandparent_well = $c->model('HTGTDB::Well')->find( { well_id => $parent_well->parent_well_id } );
        $data->{grandparent_well_name} = $grandparent_well->well_name;
        
        my $grandparent_plate = $c->model('HTGTDB::Plate')->find( { plate_id => $grandparent_well->plate_id } );
        $data->{grandparent_plate_name} = $grandparent_plate->name;
        
        # child wells
        my @child_wells = $c->model('HTGTDB::Well')->search( { parent_well_id => $w->well_id });
       
        foreach my $child (@child_wells){
            my $plate = $c->model('HTGTDB::Plate')->find( { plate_id => $child->plate_id } );
            my $child_plate_well = $plate->name."-".$child->well_name;
            $data->{child_wells} = $data->{child_wells}." ".$child_plate_well;
        }
        
        my @qc_results = $c->model('ConstructQC::QctestResult')->search(
            {
                'me.qctest_result_id'  => $data->{qctest_result_id},
                'qctestPrimers.is_valid'  => 1
            },
            {
                prefetch => [ qw/ expectedSyntheticVector matchedSyntheticVector qctestPrimers / ]
            }
        );
        
        if (scalar(@qc_results) >0) {
            foreach my $result (@qc_results){
               foreach my $primer ($result->qctestPrimers){
                  $data->{good_primers} = $data->{good_primers}." ".$primer->primer_name;
               }
            }
    
            my $exp_design_plate = $qc_results[0]->expectedSyntheticVector->design_plate;
            my $exp_design_well = $qc_results[0]->expectedSyntheticVector->design_well;
            $data->{exp_design} = $exp_design_plate."_".$exp_design_well;
    
            my $obs_design_plate = $qc_results[0]->matchedSyntheticVector->design_plate;
            my $obs_design_well = $qc_results[0]->matchedSyntheticVector->design_well;
            $data->{obs_design} = $obs_design_plate."_".$obs_design_well;
            
            if($data->{exp_design} ne $data->{obs_design}){
                $data->{match} = 'not as expected';
            }
        }
        
        push @all_data, $data;
    }
    
    $c->stash->{ all_data } =\@all_data;
    $c->stash->{ plate_name } = $plate_name;
    $c->stash->{ plate_id } = $plate_id;
    $c->stash->{ template } = 'plate/grd_plate_view';
    
}

=head2

Subroutine to get well data associated with a plate.

=cut

sub wells : Local {
    my ( $self, $c ) = @_;
    my $plate = $self->find( $c );

    unless ( defined $plate ) {
        $c->flash->{ error_msg } = 'Sorry, plate "' . $c->req->params->{ plate_name } . '" was not found.';
        $c->response->redirect( $c->uri_for( '/plate/list' ) );
        return;
    }

    my ( $well_data, $well_data_types ) = fetch_wells( $self, $c, $plate, { prefetch => 'wells' } );

    my $errstr;

    my $pqc = $c->req->param( 'PQC' ) || $c->session->{htgt_pqc} || 'false';
    $c->session->{ htgt_pqc } = $pqc;
    my $qctest_run_id = $c->req->param('qctest_run_id');
    my $plate_id = $c->req->param('plate_id');
    

    if ( $pqc eq 'true' ) {
        my ( $qcwell_data, $qcwell_data_types ) = fetch_wells_potentialQC( $self, $c, $plate, $qctest_run_id );
        ( @{ $c->stash }{ qw(wells well_data_types wellnames) }, $errstr )
            = create_well_data_array( $c, $plate->type, $well_data, $qcwell_data, @$well_data_types, @$qcwell_data_types );
        $c->session->{ htgt_pqc } = 'true';
    }
    else {
        #NOTE
        ( @{ $c->stash }{ qw(wells well_data_types wellnames) }, $errstr )
            = create_well_data_array( $c, $plate->type, $well_data, @$well_data_types );

        #WTF? perl syntax (from perldata): @days{'a','c'} same as ($days{'a'},$days{'c'})

    }

    use HTGTDB::WellData;
    $c->stash->{ cassettes } = HTGTDB::WellData::get_all_cassettes();
    $c->stash->{ backbones } = HTGTDB::WellData::get_all_backbones();
    

    my @phase_cassettes = uniq map { $CASSETTES{$_}{phase_match_group} }
        grep { exists $CASSETTES{$_}{phase_match_group} } keys %CASSETTES;
        
    my @non_phase_matched_cassettes = uniq 
        grep { !exists $CASSETTES{$_}{phase_match_group} } keys %CASSETTES;
    
    $c->stash->{phase_cassettes}     = \@phase_cassettes;
    $c->stash->{non_phase_cassettes} = \@non_phase_matched_cassettes;
    
    my @qc_results = keys %RANKED_QC_RESULTS;
    $c->stash->{ qc_results } = \@qc_results;

    # Dave's check for the mismatch design_instance_id must be done prior to this
    $c->flash->{ error_msg } .= $errstr if $errstr;
}

=head2 nanodrop

Method for creating page used in uploading and processing nanodrop reports

=cut

sub nanodrop : Local {
    my ( $self, $c ) = @_;
    unless ( $c->check_user_roles( q(edit) ) ) {
        $c->flash->{ error_msg } = "You are not authorised to use this function";
        $c->response->redirect( $c->uri_for( '/' ) );
        return 0;
    }
    $c->stash->{ template } = 'plate/nanodrop.tt';
}

=head2 nanodrop_print

Simple page that shows a table of wells and the needed data off of the nanodrop 
spreadsheet so that it can get printed for the lab.

INPUT: plate_id

=cut

sub nanodrop_print : Local {
    my ( $self, $c ) = @_;
    my $plate_id = $c->req->params->{ plate_id };

    # Get the plate object...
    my $plate = $self->find( $c, { prefetch => { wells => q(well_data) } } );

    # Get all of the wells for the plate and all of the associated 'well_data'...
    my %plate_wells;
    foreach ( $plate->wells ) {
        my %well_data;

        my $result_set = $c->model( 'HTGTDB::WellData' )->search( { well_id => $_->well_id } );

        while ( my $data = $result_set->next ) {

            # Filter numbers and text.
            # If int or text, leave alone.
            # If float, do some manipulation.
            if ( $data->data_value =~ /^$RE{num}{real}$/
                and not $data->data_value =~ /^\d+$/ )
            {

                # Apply specific formatting to the following datatypes:
                #  - ug DNA => 1 decimal place
                #  - Vol {DNA,mix,water} => 0 decimal places
                #
                # All others => 3 decimal places

                if ( $data->data_type =~ /UG_DNA/ or $data->data_type =~ /NG_UL_DNA/ ) {
                    $well_data{ $data->data_type } = sprintf( "%.1f", $data->data_value );
                }
                elsif ( $data->data_type =~ /VOL_/ ) {
                    $well_data{ $data->data_type } = sprintf( "%.0f", $data->data_value );
                }
                else {
                    $well_data{ $data->data_type } = sprintf( "%.3f", $data->data_value );
                }
            }
            else {
                $well_data{ $data->data_type } = $data->data_value;
            }
        }

        # Now add the 'well_data' into the 'plate_wells' hash
        $plate_wells{ $_->well_name } = \%well_data;
    }

    # Now send this to page...
    $c->stash->{ wells }     = [ HTGTDB::Plate::get_default_well_names( 'PGD' ) ];
    $c->stash->{ well_data } = \%plate_wells;
    $c->stash->{ template }  = 'plate/nanodrop_print.tt';
}

=head2 picking_print

Simple page that shows a table of wells and the needed data off of the PCS/PGD 
spreadsheet so that it can get printed for the lab.

INPUT: plate_id

=cut

sub picking_print : Local {
    my ( $self, $c ) = @_;

    my $plate = $c->model( 'HTGTDB::Plate' )
        ->find( { plate_id => $c->req->params->{ plate_id } }, { prefetch => { wells => { design_instance => 'design' } } } );

    my %well_data;
    foreach my $well ( $plate->wells ) {

        # Get the easy well_data first...
        for ( qw( cassette backbone clone_name ) ) {
            $well_data{ $well->well_name }->{ $_ } = $well->well_data_value( $_ );
        }

        # Now the slightly more 'fiddly' data...
        $well_data{ $well->well_name }->{ plate } = $well->plate->name;

        if ( defined $well_data{ $well->well_name }->{ clone_name } ) {
            my $three_eight_four_well = HTGTDB::Plate::parse_well_name( $well_data{ $well->well_name }->{ clone_name }, '1' );
            $well_data{ $well->well_name }->{ three_eight_four_well } = $three_eight_four_well->{ well };
        }

        if ( defined $well->design_instance_id ) {            
            if ( defined $well->design_instance->design->sp ) {
                $well_data{ $well->well_name }->{ sp } = $well->design_instance->design->sp;
            }
            else {
                eval {
                    $well_data{ $well->well_name }->{ sp }
                        = $well->design_instance->projects->first->mgi_gene->sp;
                };
            }

            if ( defined $well->design_instance->design->tm ) {
                $well_data{ $well->well_name }->{ tm } = $well->design_instance->design->tm;
            }
            else {
                eval {
                    $well_data{ $well->well_name }->{ tm }
                        = $well->design_instance->projects->first->mgi_gene->tm;
                };
            }            

            if ( defined $well->design_instance->design->phase ) {
                $well_data{ $well->well_name }->{ phase } = $well->design_instance->design->phase;
            }
            elsif ( $well->design_instance->design->is_artificial_intron ) {
                $well_data{ $well->well_name }->{ phase } = 'UNKNOWN';
            }
            else {
                $well_data{ $well->well_name }->{ phase } = $well->design_instance->design->start_exon->phase;
            }
        }
    }    

    $c->stash->{ plate }     = $plate;
    $c->stash->{ wells }     = [ HTGTDB::Plate::get_default_well_names( 'PGD' ) ];
    $c->stash->{ well_data } = \%well_data;
    $c->stash->{ template }  = 'plate/picking_print.tt';
}

=head2 ep_print

Simple page that shows a table of wells and the needed data off an EP plate 
so that it can get printed for the lab.

INPUT: plate_id

=cut

sub ep_print : Local {
    my ( $self, $c ) = @_;

    my $plate = $c->model( 'HTGTDB::Plate' )->find( { plate_id => $c->req->params->{ plate_id } }, { prefetch => 'wells' } );

    my %well_data;
    foreach my $well ( $plate->wells ) {

        my $symbol;
        if ( defined $well->design_instance_id ) { $symbol = $well->mgi_gene; }

        my $pw_name;
        my $parent_plate;
        my %pw_well_data;
        if ( defined $well->parent_well_id ) {
            $pw_name      = HTGTDB::Well::well_name_spp( $well->parent_well );
            $parent_plate = $well->parent_well->plate->name;

            foreach ( $well->parent_well->well_data ) {
                $pw_well_data{ $_->data_type } = $_->data_value;
            }
        }

        my $obs_design;

        #my $exp_design;
        # If we have a PG qctest_result_id - look up the obs_design on that
        if ( defined $pw_well_data{ 'qctest_result_id' } ) {
            eval {
                my $qc_result = $c->model( 'ConstructQC::QctestResult' )->find( 
                    { qctest_result_id => $pw_well_data{ 'qctest_result_id' } },
                    { prefetch         => [ 'matchedSyntheticVector', 'expectedSyntheticVector' ] }
                );

                my $matchedSynVec = $qc_result->matchedSyntheticVector;
                my $obs_di        = $c->model( 'HTGTDB::DesignInstance' )
                    ->find( { plate => $matchedSynVec->design_plate, well => $matchedSynVec->design_well } );
                $obs_design = $obs_di->plate . $obs_di->well . '_' . $obs_di->design_id;

                #my $expectedSynVec = $qc_result->expectedSyntheticVector;
                #my $exp_di = $c->model('HTGTDB::DesignInstance')->find(
                #    { plate => $expectedSynVec->design_plate, well => $expectedSynVec->design_well }
                #);
                #$exp_design = $exp_di->plate . $exp_di->well . '_' . $exp_di->design_id;

            };

            # If not, try to use the clone_name and pass_level
        }
        elsif ( ( defined $pw_well_data{ 'clone_name' } ) && ( defined $pw_well_data{ 'pass_level' } ) ) {
            eval {
                my $qc_rs = $c->model( 'ConstructQC::QctestResult' )->search(
                    {
                        'constructClone.name' => $pw_well_data{ 'clone_name' },
                        -or                   => [
                            pass_status   => $pw_well_data{ 'pass_level' },
                            chosen_status => $pw_well_data{ 'pass_level' },
                        ],
                        -or => [
                            is_best_for_construct_in_run => 1,
                            is_best_for_engseq_in_run    => 1
                        ]
                    },
                    {
                        join     => [ 'constructClone' ],
                        distinct => 1,
                        order_by => { -desc => 'qctest_result_id' },
                    }
                );

                if ( $qc_rs->count > 0 ) {
                    my $matchedSynVec = $qc_rs->first->matchedSyntheticVector;
                    my $obs_di        = $c->model( 'HTGTDB::DesignInstance' )
                        ->find( { plate => $matchedSynVec->design_plate, well => $matchedSynVec->design_well } );
                    $obs_design = $obs_di->plate . $obs_di->well . '_' . $obs_di->design_id;

                    #my $expectedSynVec = $qc_rs->first->expectedSyntheticVector;
                    #my $exp_di = $c->model('HTGTDB::DesignInstance')->find(
                    #    { plate => $expectedSynVec->design_plate, well => $expectedSynVec->design_well }
                    #);
                    #$exp_design = $exp_di->plate . $exp_di->well . '_' . $exp_di->design_id;
                }
            };
        }

        my $tmp = {
            symbol     => $symbol,
            obs_design => $obs_design,

            #exp_design   => $exp_design,
            parent_plate => $parent_plate,
            parent_well  => $pw_name
        };

        $well_data{ $well->well_name } = $tmp;

    }

    $c->stash->{ plate }     = $plate;
    $c->stash->{ wells }     = [ sort( keys %well_data ) ];
    $c->stash->{ well_data } = \%well_data;
}

sub recombineering : Local {
    my ( $self, $c ) = @_;
}

=head2 _do_alter_parent_well_update

   method for updating parent well

=cut

sub _do_alter_parent_well_update : Local {
    my ( $self, $c ) = @_;
    
    unless( $c->check_user_roles("edit") ){
        $c->flash->{error_msg} =
           "You are not authorised to perform this function";
        $c->response->redirect( $c->uri_for('/plate/list') );
    }
    
    my $child_well_id = $c->req->param( 'child_well_id' );
    my $new_parent_well_id = $c->req->param( 'new_parent_well_id' );
    my $comment = $c->req->param( 'comment' );
    my $edit_user = $c->user->id;
    
    my $child_well = $c->model('HTGTDB::Well')->find( { well_id => $child_well_id } );
    my $previous_design_instance_id = $child_well->design_instance_id;
    my $previous_parent_well_id = $child_well->parent_well_id;
    my $new_parent_well = $c->model('HTGTDB::Well')->find( { well_id => $new_parent_well_id } );
    
    my $count = 0;
    $c->model('HTGTDB')->schema->txn_do( sub {
        eval {
            $count = HTGT::Utils::AlterParentWell::alter_parent_well($child_well, $new_parent_well, $edit_user);
            # add insertion to well-di-jump
            $c->model('HTGTDB::WellDesignInstanceJump')->create({
                well_id => $child_well->well_id,
                previous_design_instance_id => $previous_design_instance_id,
                previous_parent_well_id => $previous_parent_well_id,
                edit_user => $edit_user,
                edit_timestamp => \'current_timestamp',
                edit_comment => $comment
            });
        };
    });
    
    my $message;
    
    if ($@){
         $message = "Error occured: $@";
         $c->stash->{error_msg} = $message;
    }else{
         $message = $count. " wells updated.";
         $c->stash->{message} = $message;
    }

    $c->res->body($message);
}

=head2 _pop_suggest_parent_wells
  
   method for listing all wells for a given plate

=cut

sub _pop_suggest_parent_wells : Local {
    my ( $self, $c ) = @_;

    my $plate_id = $c->req->param( 'plate_id' );
    my $plate = $c->model('HTGTDB::Plate')->find( { plate_id => $plate_id } );
 
    my @well_data;
    foreach my $well ($plate->wells){
        my $project = $c->model('HTGTDB::Project')->search({design_instance_id => $well->design_instance_id})->first;
        my $gene_symbol = $project->mgi_gene->marker_symbol;
        my $design = $project->design_plate_name.$project->design_well_name."_".$project->design_id;
        
        push @well_data, [ $well->well_id , $well->well_name, $gene_symbol, $design ];
    }    
    @well_data = sort { $a->[1] cmp $b->[1] } @well_data;

    $c->stash->{well_data} = \@well_data;
    $c->stash->{template}  = 'plate/new_parent_well.tt';
}

=head2 alter_parent_well

  method to display the reparent page

=cut

sub alter_parent_well : Local {
    my ($self, $c) = @_;
   
    my $plate_id = $c->req->param('plate_id');
    my $well_id = $c->req->param('well_id');
    
    my $plate = $c->model('HTGTDB::Plate')->find( { plate_id => $plate_id } );
    my $well = $c->model('HTGTDB::Well')->find( { well_id => $well_id } );
    my $project = $c->model('HTGTDB::Project')->search({design_instance_id => $well->design_instance_id})->first;
    my $gene_symbol = $project->mgi_gene->marker_symbol;
    my $design = $project->design_plate_name.$project->design_well_name."_".$project->design_id;
    my $plate_name = $plate->name;
    my $well_name = $well->well_name;
    my $current_parent_plate = $well->parent_well->plate->name;
    my $current_parent_well = $well->parent_well->well_name;
    
    $c->stash->{child_plate} = $plate_name;
    $c->stash->{child_well} = $well_name;
    $c->stash->{current_parent_plate} = $current_parent_plate;
    $c->stash->{current_parent_well} = $current_parent_well;
    $c->stash->{design} = $design;
    $c->stash->{gene_symbol} = $gene_symbol;
    $c->stash->{child_well_id} = $well_id;
}

=head2 bulk_plate_update

  List of links to bulk plate update pages

=cut

sub bulk_data_update : Local {
    my ($self, $c) = @_;
}

=head2 refresh_5_3_loxp_calls

Update the cached 5' Arm, LoxP, and 3' Arm calls for this plate. Only works for a plate of type EPD.

=cut

sub refresh_5_3_loxp_calls : Local {
    my ( $self, $c ) = @_;

    my $plate_id = $c->request->param( 'plate_id' );
    unless ( defined $plate_id ) {
        $c->flash->{error_msg} = "No plate_id specified";
        return $c->response->redirect( $c->uri_for( '/plate/list' ) );
    }

    my $plate = $c->model( 'HTGTDB' )->resultset( 'Plate' )->find( { plate_id => $plate_id } );
    unless ( defined $plate ) {
        $c->flash->{error_msg} = "Plate $plate_id not found";
        return $c->response->redirect( $c->uri_for( '/plate/list' ) );
    }

    unless ( $plate->type eq 'EPD' ) {
        $c->flash->{error_msg} = "Refresh 5' Arm, LoxP, and 3' Arm calls is only supported for EPD plates";
        return $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $plate_id } ) );
    }

    $c->model( 'HTGTDB' )->schema->txn_do(
        sub {
            for my $well ( $plate->wells ) {
                $c->log->debug( "Updating 5' arm, 3' arm, and LoxP pass levels for $well" );
                for ( qw( three_arm_pass_level five_arm_pass_level loxP_pass_level ) ) {
                    $well->$_( 'recompute' );         
                }
            }            
        }
    );

    $c->flash->{status_msg} = "5' Arm, LoxP, and 3' Arm calls updated";
    return $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $plate_id } ) );        
}
    
=head2 get_taqman_assay_information

For given well return taqman assay information for the design linked to well.
Information returned : plate_name, well_name, assay_id

=cut

sub get_taqman_assay_information {
    my ( $well ) = @_;

    my @taqman_info;
    my $taqman_rs = $well->design_instance->design->taqman_assays;

    while ( my $taqman = $taqman_rs->next ) {
        push @taqman_info, {
            plate_name => $taqman->taqman_plate->name,
            well_name  => $taqman->well_name, 
            assay_id   => $taqman->assay_id,
        };
    }
    return \@taqman_info;
}

sub get_dna_plate_qc {
    my ( $epd_well, $dna_plate_type ) = @_;

    my @dna_qc_wells = $epd_well->child_wells->search(
        {
            'plate.type' => $dna_plate_type,
        },
        {
            join => 'plate',
        }
    );
    return unless @dna_qc_wells;

    return join ' : ', map{ "$_" } @dna_qc_wells;
}

=head2 get_piq_well

Given a SBDNA or QPCRDNA well return the PIQ well linked to it

=cut

sub get_piq_well {
    my ( $self, $c, $parent_well ) = @_;

    my @piq_wells = $c->model('HTGTDB::Well')->search(
        {
            design_instance_id => $parent_well->design_instance_id,
            'plate.type'       => 'PIQ',
        },
        {
            join => 'plate',
        }
    );

    my @linked_piq_wells;
    for my $piq_well ( @piq_wells ) {
        my ($epd_well, $epd_plate) = $piq_well->ancestor_well_plate_of_type('EPD');
        if ( $parent_well->well_id == $epd_well->well_id ) {
            push @linked_piq_wells, $piq_well;
        }
    }

    if ( scalar(@linked_piq_wells) == 1 ) {
        my $well = pop @linked_piq_wells;
        return {
            plate_id   => $well->plate_id,
            well_name  => $well->well_name,
            well_id    => $well->well_id,
        };
    }
    else {
        $c->log->warn( "Multiple PIQ wells linked to epd well: " . $parent_well->well_name );
    }
    return;
}

sub delete_piq_well : Local {
    my ($self, $c) = @_;
   
    my $well_id = $c->req->param('well_id');
    my $plate_id = $c->req->param('plate_id');
    
    my $well = $c->model('HTGTDB::Well')->find( { well_id => $well_id } );

    unless ( $well ) {
        $c->flash->{error_msg} = "Unable to find well ID $well_id";
        return $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $plate_id } ) ); 
    }
    my $well_name = $well->well_name;

    unless( $well->plate->type eq 'PIQ' ) {
        $c->flash->{error_msg} = "Well $well_name belongs to a " . $well->plate->type . " plate, will not delete";
        return $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $plate_id } ) ); 
    }

    if( $well->child_wells->count ) {
        $c->log->warn("Well $well_name has child wells, can not delete");
        $c->flash->{error_msg} = "Well $well_name has child wells, can not delete";
        return $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $plate_id } ) ); 
    }

    $c->model('HTGTDB')->schema->txn_do(
        sub {
            my $wd = $well->well_data->delete;
            $well->delete;
            $c->log->info("Deleted $wd well_data rows and the well");
        }
    );
    
    $c->flash->{status_msg} = "PIQ well $well_name deleted";
    return $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $well->plate->id } ) );     
}

=head1 AUTHORS

David Jackson <dj3@sanger.ac.uk>, 
Darren Oakley <do2@sanger.ac.uk>,
Dan Klose     <dk3@sanger.ac.uk>
Wanjuan Yang  <wy1@sanger.ac.uk>
=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
