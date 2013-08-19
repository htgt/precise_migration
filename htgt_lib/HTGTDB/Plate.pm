package HTGTDB::Plate;
use strict;
use warnings;
use List::MoreUtils qw/any/;

=head1 AUTHOR

Vivek Iyer

David K Jackson <david.jackson@sanger.ac.uk>

Darren Oakley <do2@sanger.ac.uk>

=cut

use base 'DBIx::Class', 'Exporter';
__PACKAGE__->load_components(qw/InflateColumn::DateTime PK::Auto Core/);

our @EXPORT;
our @EXPORT_OK;

__PACKAGE__->table('plate');

#__PACKAGE__->add_columns(
#  "plate_id",
#  {
#    data_type => "numeric",
#    is_auto_increment => 1,
#    is_nullable => 0,
#    original => { data_type => "number" },
#    sequence => "s_plate",
#    size => [10, 0],
#  },
#  "name",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "description",
#  { data_type => "varchar2", is_nullable => 1, size => 4000 },
#  "created_user",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "created_date",
#  {
#    data_type     => "datetime",
#    default_value => \"current_timestamp",
#    is_nullable   => 1,
#    original      => { data_type => "date", default_value => \"sysdate" },
#  },
#  "edited_user",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "edited_date",
#  {
#    data_type     => "datetime",
#    default_value => \"current_timestamp",
#    is_nullable   => 1,
#    original      => { data_type => "date", default_value => \"sysdate" },
#  },
#  "type",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "is_locked",
#  { data_type => "char", is_nullable => 1, size => 1 },
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "plate_id",
  {
#    data_type => "numeric", -- not for SQLite
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_plate",
    size => [10, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "created_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "created_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "edited_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edited_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "is_locked",
  { data_type => "char", is_nullable => 1, size => 1 },
);
# End of dbicdump add_columns data

#__PACKAGE__->add_columns(
#    'plate_id',
#    'name',
#    'description',
#    'created_user',
#    'edited_user',
#    'type',
#    'created_date' => { data_type => 'date' },
#    'edited_date',
#    'is_locked',
#);

__PACKAGE__->set_primary_key(qw/plate_id/);
__PACKAGE__->sequence('S_PLATE');

__PACKAGE__->add_unique_constraint( name_type => [qw/name type/] );

__PACKAGE__->has_many( plate_comments      => "HTGTDB::PlateComment", 'plate_id' );
__PACKAGE__->has_many( plate_data          => 'HTGTDB::PlateData',    'plate_id' );
__PACKAGE__->has_many( plate_blobs         => 'HTGTDB::PlateBlob',    'plate_id' );
__PACKAGE__->has_many( wells               => 'HTGTDB::Well',         'plate_id' );
__PACKAGE__->has_many( child_plate_plates  => 'HTGTDB::PlatePlate',   'parent_plate_id' );
__PACKAGE__->has_many( parent_plate_plates => 'HTGTDB::PlatePlate',   'child_plate_id' );

__PACKAGE__->many_to_many( parent_plates => 'parent_plate_plates', 'parent_plate' );
__PACKAGE__->many_to_many( child_plates  => 'child_plate_plates',  'child_plate' );

#Extra methods...:

use overload '""' => \&stringify;

sub stringify {
    my ($self) = @_;
    $self->name;
}

=head2 plate_data_value

Returns the value of this plate's plate_data for the specified data type

=cut

sub plate_data_value {
    my ( $self, $data_type ) = @_;
    if ( my $pd = $self->related_resultset('plate_data')->find( { data_type => $data_type } ) ) {
        return $pd->data_value;
    }
    return;
}

=head2 parent_plates_from_parent_wells

Returns resultset of the parent plates identified from the wells' parent wells' plates.

=cut

sub parent_plates_from_parent_wells {
    return shift->wells->related_resultset('parent_well')->related_resultset('plate')->search( {}, { distinct => 1 } );
}

=head2 ancestor_plates

Returns resultset of all ancestor plates including self.

=cut

sub ancestor_plates {
    my ( $plate, $max_rec ) = @_;
    $max_rec = 12 unless defined $max_rec;
    my @ids  = ( $plate->plate_id );
    my $p_rs = $plate->parent_plates_from_parent_wells;
    my $s    = $plate->result_source->schema;
    while ( $max_rec-- and $p_rs and $p_rs->count ) {
        push @ids, $p_rs->get_column(q(plate_id))->all;
        my @n;
        while ( my $p = $p_rs->next() ) { push @n, $p->parent_plates_from_parent_wells->get_column(q(plate_id))->all; }
        $p_rs = @n ? $s->resultset('Plate')->search_rs( { 'me.plate_id' => \@n }, { distinct => 1 } ) : undef;
    }
    die "Supposed max depth of descendants exceeded!" unless $max_rec >= 0;
    return $s->resultset('Plate')->search_rs( { 'me.plate_id' => \@ids }, { distinct => 1 } );
}

=head2 child_plates_from_child_wells

Returns resultset of the child plates identified from the wells' child wells' plates.

=cut

sub child_plates_from_child_wells {
    return
        shift->wells->related_resultset(q(child_wells))->related_resultset(q(plate))->search( {}, { distinct => 1 } );
}

#Utility functions:
push @EXPORT, qw(get_default_well_names parse_well_name );

BEGIN {
    push @EXPORT_OK,
        qw(&get_default_well_names parse_well_name &omit_well_data_types_for_noedit convert_std384_to_96well_name);
}

=head2 omit_well_data_types_for_noedit

Short method to purge  well data_types (in the 'well_data' table)
that should be omitted for non edit role users. Takes a list, returns purged list.

=cut

our $omitted_well_data_types_for_noedit = {
    map { $_ => 1 } 'pass_level', 'qctest_result_id',
    'pg_clone',                   'vector_qc',
    'vector_qc_result',           'primer_band_tr_pcr',
    'exp_design_id',              'obs_design_id',
    'primer_band_gf3',            'primer_band_gf4',
    'primer_band_gr3',            'primer_band_gr4',
    'pass_r',                     'pass_r_count',
    'pass_from_recovery_QC',      'synthetic_allele_id',
    'target_region_pass_level',   'three_arm_pass_level',
    'five_arm_pass_level',        'target_region_qctest_result_id',
    'three_arm_qctest_result_id', 'five_arm_qctest_result_id',
};

sub omit_well_data_types_for_noedit {
    my @r = grep { not $omitted_well_data_types_for_noedit->{$_} } @_;
    @r = grep { not /^cell_/ } @r;
    return @r;
}

=head2 get_default_well_names

Short method to return the default well names expected for a given plate type.

=cut

sub get_default_well_names {
    my ( $pt, $sort_by_row ) = @_;
    my $wells;

    if ( defined $sort_by_row ) {    # Wells sorted by row...
        if ( $pt eq 'EP' ) {
            my @wells;
            foreach my $col ( 1 .. 5 ) {
                foreach my $row ( q(A) .. q(E) ) {
                    my $name = $row . ( sprintf "%02d", $col );
                    push( @wells, $name );
                }
            }
            return @wells;
        }
        elsif ( $pt eq 'PIQ' ) { # 24 well plate
            my @wells;
            foreach my $col ( 1 .. 6 ) {
                foreach my $row ( q(A) .. q(D) ) {
                    my $name = $row . ( sprintf "%02d", $col );
                    push( @wells, $name );
                }
            }
            return @wells;
        }
        elsif ( $pt eq 'PIQFP' || $pt eq 'PIQS' ){
            return map{ sprintf("%02d", $_) } (1..96);
        }
        else {
            my @wells;
            foreach my $col ( 1 .. 12 ) {
                foreach my $row ( q(A) .. q(H) ) {
                    my $name = $row . ( sprintf "%02d", $col );
                    push( @wells, $name );
                }
            }
            return @wells;
        }
    }
    else {    # Wells sorted by column...
        return map {
            my $r = $_;
            map { $r . $_ } map { sprintf "%02d", $_ } 1 .. 5
        } q(A) .. q(E) if $pt eq q(EP);

        return map {
            my $r = $_;
            map { $r . $_ } map { sprintf "%02d", $_ } 1 .. 6
        } q(A) .. q(D) if $pt eq q(PIQ);

        return map{ sprintf("%02d", $_) } (1..96) if $pt eq 'PIQS' || $pt eq 'PIQFP';

        foreach (qw(DESIGN REPD EPD RS GR GRD PGD PGG FP PCS PGR PIQFP PIQS VTP)) {
            return map {
                my $r = $_;
                map { $r . $_ } map { sprintf "%02d", $_ } 1 .. 12
            } q(A) .. q(H) if $pt eq $_;
        }
    }

    return ();
}

=head2 parse_well_name

Parses well_name to return hash containing plate name, well name, row, column,

INPUT: well name, special team87 384 well name parsing

=cut

#c.f. parseWell in
sub parse_well_name {
    my $wn     = shift;
    my $wellRE = qr/((?:\S*[^A-Z])?)([A-P])(?:0)?(\d\d?)(?!\d)(_\d\d?)?\b/i;
    if ( $wn =~ /$wellRE/ ) {
        my %r;
        $r{plate} = $1;
        $r{row}   = uc $2;
        $r{col}   = $3;
        if ( shift && $4 && length($4) > 0 ) {    #96 based 384 well nomenclature
            my $i = substr( $4, 1 ) - 1;          #skip initial understore
            $r{plate} .= "(" . ( int( $i / 4 ) + 1 ) . ")";
            $i = $i % 4;
            $r{col} = 1 + ( $r{col} - 1 ) * 2 + $i % 2;
            $r{row} = chr( 65 + ( ord( $r{row} ) - 65 ) * 2 + int( $i / 2 ) );
        }
        $r{well} = $r{row} . ( length( $r{col} ) == 1 ? "0" : "" ) . $r{col};
        return \%r;
    }
    else {
        return { well => $wn };
    }
}

=head2 convert_std384_to_96well_name

Takes standard 384 plate well name and converts to 96. Returns 96 wellname string and quadrant.

'use HTGTDB::Plate qw(convert_std384_to_96well_name); print join(", ",$_, convert_std384_to_96well_name $_) foreach qw(A01 A02 A03 A04 B01 B02 B03 B04 C01 C02 C03 C04)'
A01, A01, 1
A02, A01, 2
A03, A02, 1
A04, A02, 2
B01, A01, 3
B02, A01, 4
B03, A02, 3
B04, A02, 4
C01, B01, 1
C02, B01, 2
C03, B02, 1
C04, B02, 2

=cut

sub convert_std384_to_96well_name {
    my $wn = shift;
    if ( $wn =~ /([A-Z])(\d\d)/ ) {
        my $col = int( ( $2 - 1 ) / 2 ) + 1;
        my $row = chr( int( ( ord($1) - 65 ) / 2 ) + 65 );
        my $q = 1 + ( $2 - 1 ) % 2 + 2 * ( ( ord($1) - 65 ) % 2 );
        return ( $row . sprintf( "%02d", $col ), $q );
    }
}

=head2 load_qc

Generic QC loading function - will happily load the QC data for a plate
if the 'design_plate' used in the QctestRun entry (in the QC system) matches
the name of the plate in HTGT, otherwise a 'clone_plate' will need to
be specified.

B<Input:>
 * $options          Hashref containing the following:
    - qc_schema         DBIx::Schema for the QC database
    - stage             The QC test 'stage' to load - i.e. 'allele' etc.
    - clone_plate       The QC 'clone_plate' to match up to (optional).
    - qctest_run_id     The actual QC TestRun to load (optional).
    - user              The username to attribute this data entry to
    - log               Reference to a logging function (optional)
    - override          Flag to override the existing QC data - to use, set as '1' (optional)
    - ignore_well_slop  Flag to stop any well parentage rejigging - set as '1' (to ignore well
                        slop) or 'undef' to rejig the plate to cope with well slop - does not
                        affect "allele" plates

=cut

sub load_qc {
    my ( $plate, $options ) = @_;

    my $qc_schema        = $options->{qc_schema};
    my $stage            = $options->{stage};
    my $clone_plate      = $options->{clone_plate};
    my $qctest_run_id    = $options->{qctest_run_id};
    my $user             = $options->{user};
    my $log              = $options->{log} ? $options->{log} : sub { };
    my $override         = $options->{override};
    my $ignore_well_slop = $options->{ignore_well_slop};
    my $dont_transfer_results_with_well_slop = $options->{dont_transfer_results_with_well_slop};

    &$log("---");
    &$log( "[HTGTDB::Plate::load_qc] " . $plate->name . " - Starting 'load_qc'" );

    # Check that someone isn't trying to pass us a 384 well plate
    my $is_384 = $plate->plate_data->find( { data_type => 'is_384' }, { key => 'plate_id_data_type' } );

    if ( defined $is_384 and $is_384->data_value eq 'yes' ) {
        die "[HTGTDB::Plate::load_qc] " . $plate->name . " is a flagged as a 384-well plate, can't process - DIED.";
    }

    # Pre-fetch all of the wells/well_data on this plate...
    my $schema = $plate->result_source->schema;
    $plate = $schema->resultset('Plate')
        ->find( { plate_id => $plate->plate_id }, { prefetch => { 'wells' => 'well_data' }, cache => 1 } );

    # Now we need to look up all of the QC Runs carried out on this plate - due
    # to the joys of the decoupled nature of our QC/LIMS system the name of the plate
    # in HTGT is not necessarily the name of the plate in the QC system. (If only
    # things were that simple).
    #
    # In recent times the HTGT plate has been used as the 'design_plate'  in the QC
    # system for 96 well plates so we can now use this to look up our QC Run info.
    # So that means that this WILL NOT work on older plates, the 'clone_plate' is needed.

    my $qctest_run_rs = undef;
    if ( defined $qctest_run_id ) {
        $qctest_run_rs
            = $qc_schema->resultset('QctestRun')->search( { qctest_run_id => $qctest_run_id }, { cache => 1 } );
    }
    elsif ( defined $clone_plate ) {
        $qctest_run_rs = $qc_schema->resultset('QctestRun')
            ->search( { clone_plate => $clone_plate, stage => $stage }, { order_by => 'run_date asc', cache => 1 } );
    }
    else {
        $qctest_run_rs = $qc_schema->resultset('QctestRun')
            ->search( { design_plate => $plate->name, stage => $stage }, { order_by => 'run_date asc', cache => 1 } );
    }

    # Check we have some test runs to work through...
    if ( $qctest_run_rs->count == 0 ) {
        my $error_msg = "[HTGTDB::Plate::load_qc] " . $plate->name . " - ERROR: No QctestRun's found";
        if ( defined $clone_plate ) { $error_msg .= " for clone plate $clone_plate"; }
        &$log( "---\n\n" . $error_msg . "---\n\n" );
    }

    # Set up a stash for qctest_run_ids - this is used to cope for
    # well slop if needed.
    my %qctest_run_ids;

    # Now work through each test run
    while ( my $qctest_run = $qctest_run_rs->next ) {

        # And the test results...
        my $qctest_result_rs = $qctest_run->qctestResults->search( { is_best_for_construct_in_run => 1 },
            { prefetch => ['constructClone'], cache => 1 } );

        if ( $stage =~ /allele/ ) {

            # Pre-fetch a bunch of extra data too
            $qctest_result_rs = $qctest_run->qctestResults->search(
                { is_best_for_construct_in_run => 1 },
                {   prefetch => [
                        'constructClone',
                        { 'qctestPrimers'        => 'seqAlignFeature' },
                        { 'matchedEngineeredSeq' => 'syntheticVector' }
                    ],
                    cache => 1
                }
            );
        }
        else {

            # Stash the qctestRun id so we can account for well slop later
            $qctest_run_ids{ $qctest_run->qctest_run_id } = 1;
        }

        &$log(    "[HTGTDB::Plate::load_qc] "
                . $plate->name
                . " - Working with QctestRun "
                . $qctest_run->qctest_run_id . " ("
                . $qctest_result_rs->count
                . " results)" );

    QCTEST_RESULT: while ( my $qc = $qctest_result_rs->next ) {

            # Find our target well (pre-fetching well data)...
            # But first, clean up our ConstructClone well name (some can be borked)

            my $clone_well = substr( $qc->constructClone->well, -3 );

            my $well = $plate->wells->find( { well_name => $clone_well },
                { key => 'plate_id_well_name', prefetch => ['well_data'], cache => 1 } );

            unless ($well) {
                $well = $plate->wells->find( { well_name => $plate->name . '_' . $clone_well },
                    { key => 'plate_id_well_name', prefetch => ['well_data'], cache => 1 } );
            }

            unless ($well) {
                die "[HTGTDB::Plate::load_qc] "
                    . $plate->name
                    . " - DIED: unable to find well '"
                    . $clone_well . "'...";

            }

            &$log(    "[HTGTDB::Plate::load_qc] $well (QctestRun: "
                    . $qctest_run->qctest_run_id
                    . " - QctestResult: "
                    . $qc->qctest_result_id
                    . ")" );

            if ( $qc->matchedEngineeredSeq->is_genomic ) {
                &$log(   "[HTGTDB::Plate::load_qc] $well (QctestRun: "
                       . $qctest_run->qctest_run_id
                       . " - QctestResult: "
                       . $qc->qctest_result_id
                       . ") ignoring genomic hit" );
                next QCTEST_RESULT;
            }

            # Do any required updates/inserts...
            if ( $stage =~ /allele/ ) {

                # Working with 'allele' data.

                if($dont_transfer_results_with_well_slop){
                    if($qc->engineered_seq_id != $qc->expected_engineered_seq_id){
                        &$log( "skipping transfer of ".$well->well_name." because expected engseq doesn't match expected and we are skipping in this case\n");
                        next QCTEST_RESULT;
                    }
                }

                my $qc_data_to_insert = {
                    stage    => $stage,
                    user     => $user,
                    log      => $log,
                    override => $override
                };

                # Obtain the required well data and primer data...
                my $qc_data_options = {
                    qctest_result => $qc,
                    stage         => $stage,
                    log           => $log
                };
                $qc_data_to_insert->{well_data}    = $well->prepare_allele_well_data($qc_data_options);
                $qc_data_to_insert->{primer_reads} = $well->prepare_primer_reads($qc_data_options);

                # Run the check/insert...
                $well->insert_update_qc_data($qc_data_to_insert);
                $well->insert_update_primer_reads($qc_data_to_insert);

                #trigger recomputing of pass levels when qc data loaded for EPD plates
                if ($plate->type eq 'EPD') {
                    for ( qw( three_arm_pass_level five_arm_pass_level loxP_pass_level ) ) {
                        $well->$_( 'recompute' );
                    }
                }

            }
            else {

                # Working with 'vector' data - assume 'postcre' or 'postgateway'.
                if($dont_transfer_results_with_well_slop){
                    if($qc->engineered_seq_id != $qc->expected_engineered_seq_id){
                        &$log( "skipping transfer of ".$well->well_name." because expected engseq doesn't match expected and we are skipping in this case\n");
                        next QCTEST_RESULT;
                    }
                }

                my $qc_data = {
                    stage     => $stage,
                    user      => $user,
                    log       => $log,
                    override  => $override,
                    well_data => {
                        pass_level => $qc->chosen_status || $qc->pass_status,
                        clone_name => $qc->constructClone->name,
                        qctest_result_id => $qc->qctest_result_id
                    }
                };
                $well->insert_update_qc_data($qc_data);
            }

        }

    }


    # Finally, if required, adjust for well slop...
    unless ( defined $ignore_well_slop ) {
        if ( keys %qctest_run_ids ) {
            if ( scalar( keys %qctest_run_ids ) > 1 ) {
                &$log(    "[HTGTDB::Plate::load_qc] "
                              . $plate->name
                                  . " - More than one QC Test Run, can't accomodate well slop!!!" );
            }
            else {
                my @keys    = keys %qctest_run_ids;
                my $options = {
                    qc_schema     => $qc_schema,
                    qctest_run_id => $keys[0],
                    user          => $user,
                    log           => $log
                };
                $plate->adjust_for_well_slop($options);
            }
        }
    }
}

=head2 load_384well_qc

More specialised QC loading function - will load the QC data for 384 well
plates (but the actual 384 well plates only - PC or PG - not the 96 condensment
plates i.e. PCS, PGS etc.)

B<Input:>
 * $options           Hashref containing the following:
    - qc_schema       DBIx::Schema for the QC database
    - qctest_run_id   The actual QC TestRun to load (optional).
    - user            The username to attribute this data entry to
    - log             Reference to a logging function (optional)
    - override        Flag to override the existing QC data - to use, set as '1' (optional)

=cut

sub load_384well_qc {
    my ( $plate, $options ) = @_;

    my $qc_schema     = $options->{qc_schema};
    my $qctest_run_id = $options->{qctest_run_id};
    my $user          = $options->{user};
    my $log           = $options->{log} ? $options->{log} : sub { };
    my $override      = $options->{override};

    ##
    ## Safety checks first...
    ##

    # First, check that this plate is a 384 well plate...
    my $is_384 = $plate->plate_data->find( { data_type => 'is_384' }, { key => 'plate_id_data_type' } );

    unless ( defined $is_384 and $is_384->data_value eq 'yes' ) {
        die "[HTGTDB::Plate::load_384well_qc] "
            . $plate->name
            . " is not correctly flagged as a 384-well plate - DIED.";
    }

    # Also check the formatting of the plate name...
    unless ( $plate->name =~ /^(\D+)(\d+)_(\D)_(\d+)$/ ) {
        die "[HTGTDB::Plate::load_384well_qc] "
            . $plate->name
            . " is not a correctly formatted 384-well plate name - DIED.";
    }

    # Check if any qc results have already been loaded
    my @wells = $plate->wells;
    foreach my $w (@wells) {
        if ( any { $_->data_type eq 'qctest_result_id' } $w->well_data ) {
            die "[HTGTDB::Plate::load_384well_qc] " . $plate->name . ": qc results have already been loaded - DIED.";
        }
    }

    ##
    ## Now to bussiness...
    ##

    # Pre-fetch all of the wells/well_data on this plate...
    my $schema = $plate->result_source->schema;
    $plate = $schema->resultset('Plate')
        ->find( { plate_id => $plate->plate_id }, { prefetch => { 'wells' => 'well_data' }, cache => 1 } );

    # Get the name of clone plate...
    my ( $clone_plate, $clone_number ) = $plate->name =~ m/^(\D+\d+_\D)_(\d+)$/;

    # Get the qc results from the qctest_run_id (if defined), otherwise from the clone plate name
    my $clones_rs;
    if ( defined $qctest_run_id ) {
        &$log("[HTGTDB::Plate::load_384well_qc] looking for clones for qctest_run_id $qctest_run_id" );
        $clones_rs = $qc_schema->resultset('ConstructClone')->search_rs(
            { 'qctestResults.qctest_run_id' => $qctest_run_id },
            { 'distinct'                    => 1, 'join' => 'qctestResults' }
        );
    }
    else {
        &$log("[HTGTDB::Plate::load_384well_qc] looking for clone_plate: $clone_plate / $clone_number" );
        $clones_rs = $qc_schema->resultset('ConstructClone')->search( { plate => $clone_plate } );
    }

    # Set up a stash for qctest_run_ids - this is used to cope for well slop
    my %qctest_run_ids;

    # Foreach of the clone qc results, insert into HTGT well data table
    while ( my $clone = $clones_rs->next ) {

        # Make sure we're working with the right clone iteration
        if ( $clone->clone_number == $clone_number ) {

            my $qc_result_rs = $qc_schema->resultset('QctestResult')->search(
                {   construct_clone_id           => $clone->construct_clone_id,
                    is_best_for_construct_in_run => 1
                },
                { prefetch => 'qctestRun' }
            );

            # Trim down the results to a specific test run if asked...
            if ( defined $qctest_run_id ) {
                $qc_result_rs
                    = $qc_result_rs->search( { 'qctestRun.qctest_run_id' => $qctest_run_id }, { join => 'qctestRun' } );
            }

        QCTEST_RESULT:
            while ( my $qc = $qc_result_rs->next ) {

                # Stash the qctestRun id
                $qctest_run_ids{ $qc->qctestRun->qctest_run_id } = 1;

                &$log(    "[HTGTDB::Plate::load_384well_qc] Working on QctestResult "
                        . $qc->qctest_result_id . " ("
                        . $qc->qctestRun->stage
                        . ")" );

                if ( $qc->matchedEngineeredSeq->is_genomic ) {
                    &$log(   "[HTGTDB::Plate::load_qc] (QctestRun: "
                           . $qctest_run_id
                           . " - QctestResult: "
                           . $qc->qctest_result_id
                           . ") ignoring genomic hit" );
                    next QCTEST_RESULT;
                }

                # Find our target well (pre-fetching well data)...

                &$log( "[HTGTDB::Plate::load_384well_qc] Loading well " . $plate->name . '[' . $clone->well . ']' );
                my $well = $plate->wells->find( { well_name => $clone->well },
                    { key => 'plate_id_well_name', prefetch => ['well_data'], cache => 1 } );

                &$log( "[HTGTDB::Plate::load_384well_qc] Found well: " . $plate->name . "_" . $well->well_name );

                # Stash some info ready for insertion...
                my $qc_data = {
                    stage     => $qc->qctestRun->stage,
                    user      => $user,
                    log       => $log,
                    override  => $override,
                    well_data => {
                        pass_level => $qc->chosen_status || $qc->pass_status,
                        clone_name => $clone->name,
                        qctest_result_id => $qc->qctest_result_id
                    }
                };

                if ($well) {

                    # Do any required updates/inserts...
                    $well->insert_update_qc_data($qc_data);
                }
                else {
                    die "[HTGTDB::Plate::load_384well_qc] "
                        . $plate->name
                        . " - DIED: unable to find well '"
                        . $clone->well . "'...";
                }

            }
        }
    }

    # Finally, adjust for well slop...
    if ( keys %qctest_run_ids ) {
        if ( scalar( keys %qctest_run_ids ) > 1 ) {
            &$log(    "[HTGTDB::Plate::load_384well_qc] "
                    . $plate->name
                    . " - More than one QC Test Run, can't accomodate well slop!!!" );
        }
        else {
            my @keys = keys %qctest_run_ids;
            &$log(    "[HTGTDB::Plate::load_384well_qc] "
                    . $plate->name
                    . " - adjusting wells for well slop using QC Test Run "
                    . $keys[0] );

            my $options = {
                qc_schema     => $qc_schema,
                qctest_run_id => $keys[0],
                user          => $user,
                log           => $log
            };
            $plate->adjust_for_well_slop($options);

        }
    }

}

=head2 adjust_for_well_slop

Function to be used to re-jig a plate following QC loading to adjust
the design instance and parentage of the wells to account for well slop.
This is meant for things such as 384 well PG plates and pooled recovery
activities.

B<Input:>
 * $options           Hashref containing the following:
    - qc_schema       DBIx::Schema for the QC database
    - qctest_run_id   The ID for the QC Test Run we want to check for slop in
    - user            The username to attribute any data changes to
    - log             Reference to a logging function (optional)

=cut

sub adjust_for_well_slop {
    my ( $plate, $options ) = @_;

    my $qc_schema     = $options->{qc_schema};
    my $qctest_run_id = $options->{qctest_run_id};
    my $user          = $options->{user};
    my $log           = $options->{log} ? $options->{log} : sub { };

    if ( !defined $qctest_run_id || $qctest_run_id eq "" ) {
        die "[HTGTDB::Plate::adjust_for_well_slop] ERROR - unable to run without a qctest_run_id!";
    }

    &$log(    "[HTGTDB::Plate::adjust_for_well_slop] Checking for well slop on "
            . $plate->name
            . " using QC Test Run ID "
            . $qctest_run_id );

    # First, let's grab the slops for this test run...
    # Perhaps we can move this SQL out to its own module and call it using DBIC -- io1

    my $sql = q[
  select
    qctest_result.qctest_result_id,
    qctest_result.engineered_seq_id,
    qctest_result.expected_engineered_seq_id,
    construct_clone.well,
    construct_clone.name,
    synthetic_vector.design_plate,
    synthetic_vector.design_well,
    synthetic_vector.design_instance_id
  from
         qctest_run
    join qctest_result    on qctest_run.qctest_run_id           = qctest_result.qctest_run_id
    join construct_clone  on qctest_result.construct_clone_id   = construct_clone.construct_clone_id
    join synthetic_vector on synthetic_vector.engineered_seq_id = qctest_result.engineered_seq_id
    join engineered_seq   on qctest_result.engineered_seq_id    = engineered_seq.engineered_seq_id
  where
        qctest_run.qctest_run_id                    = ?
    and qctest_result.is_best_for_construct_in_run  = 1
    and qctest_result.expected_engineered_seq_id   != qctest_result.engineered_seq_id
    and ( engineered_seq.is_genomic != 1 OR engineered_seq.is_genomic IS NULL )
  ];
    my $sth = $qc_schema->storage->dbh->prepare($sql);
    $sth->execute($qctest_run_id);

    my %qc_results_with_slop;
    while ( my $jumper = $sth->fetchrow_hashref() ) {
        $qc_results_with_slop{ $jumper->{QCTEST_RESULT_ID} } = $jumper->{DESIGN_INSTANCE_ID};
    }
    $sth->finish();

    # if no %qc_results_with_slop, don't do the following
    if ( keys %qc_results_with_slop > 0 ) {

        # Cache the parent wells to avoid needless lookups as we cycle through
        # the wells...

        my %parent_well_ids;
        foreach my $parent_plate ( $plate->parent_plates ) {
            foreach my $parent_well ( $parent_plate->wells ) {
                if ( defined $parent_well->design_instance_id ) {
                    if ( $parent_well_ids{ $parent_well->design_instance_id } ) {

                        # O_o oops, we have two wells with the same DI...
                        &$log(    "[HTGTDB::Plate::adjust_for_well_slop] ERROR - two parent wells with same DI on "
                                . $plate->name
                                . " - DI: "
                                . $parent_well->design_instance_id );
                    }
                    else {
                        $parent_well_ids{ $parent_well->design_instance_id } = $parent_well->well_id;
                    }
                }
            }
        }

        # Next, look up any wells on this plate that have qctest_result_id's
        # that have well slop and adjust their design instance and parentage
        # accordingly.

        my $well_with_slop_rs = $plate->wells->search(
            {   'well_data.data_type'  => 'qctest_result_id',
                'well_data.data_value' => [ keys %qc_results_with_slop ]
            },
            { join => 'well_data', prefetch => 'plate', cache => 1 }
        );

        while ( my $well = $well_with_slop_rs->next ) {

            my $well_desc = $plate->name . "[" . $well->well_name . "]";

            my $qctest_result_id
                = $well->well_data->find( { data_type => 'qctest_result_id' }, { key => 'well_id_data_type' } )
                ->data_value;

            my $current_di   = $well->design_instance_id;
            my $corrected_di = $qc_results_with_slop{$qctest_result_id};
            unless ($current_di)   { $current_di   = ''; }
            unless ($corrected_di) { $corrected_di = $current_di; }

            my $current_pw   = $well->parent_well_id;
            my $corrected_pw = $parent_well_ids{$corrected_di};
            unless ($current_pw)   { $current_pw   = ''; }
            unless ($corrected_pw) { $corrected_pw = $current_pw; }

            my %update;

            if ( $current_di ne $corrected_di ) {
                &$log(    "[HTGTDB::Plate::adjust_for_well_slop] Updating design instance on $well_desc from "
                        . $current_di . " to "
                        . $corrected_di );
                $update{design_instance_id} = $corrected_di;
            }

            if ( $current_pw ne $corrected_pw ) {
                &$log(    "[HTGTDB::Plate::adjust_for_well_slop] Updating parent well for $well_desc from "
                        . $current_pw . " to "
                        . $corrected_pw );
                $update{parent_well_id} = $corrected_pw;
            }

            if ( keys %update ) {
                use DateTime;
                my $dt   = DateTime->now;
                my $date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;

                $update{edit_user} = $user;
                $update{edit_date} = $date;

                $well->update( \%update );
            }

        }
    }
}

=head2 correct_parentage_by_di

Function to correctly re-parent wells on a plate based on their design_instance_id.
Can help fix problems with orphans created by the HTGT::Controller::Plate::Update::save384
function.  B<NOTE:> will only reparent wells to wells found on plates that are already
deemed parent plates (via the PlatePlate relationship table).

B<Input:>
 * $options           Hashref containing the following:
    - user            The username to attribute any data changes to
    - log             Reference to a logging function (optional)

=cut

sub correct_parentage_by_di {
    my ( $plate, $options ) = @_;

    my $user   = $options->{user};
    my $log    = $options->{log} ? $options->{log} : sub { };
    my $schema = $plate->result_source->schema;

    # Cache the parent wells to avoid needless lookups as we cycle through
    # the wells...

    my %parent_well_ids;
    foreach my $parent_plate ( $plate->parent_plates ) {
        foreach my $parent_well ( $parent_plate->wells ) {
            if ( defined $parent_well->design_instance_id ) {
                if ( $parent_well_ids{ $parent_well->design_instance_id } ) {

                    # O_o oops, we have two wells with the same DI...
                    &$log(    "[HTGTDB::Plate::correct_parentage_by_di] ERROR - two parent wells with same DI on "
                            . $plate->name
                            . " - DI: "
                            . $parent_well->design_instance_id );
                }
                else {
                    $parent_well_ids{ $parent_well->design_instance_id } = $parent_well->well_id;
                }
            }
        }
    }

    # Now fly through the wells and adjust as necessary

    foreach my $well ( $plate->wells ) {

        my $well_desc = $plate->name . "[" . $well->well_name . "]";

        my $parent_di           = '';
        my $current_parent_desc = '';
        if ( $well->parent_well ) {
            $parent_di           = $well->parent_well->design_instance_id;
            $current_parent_desc = $well->parent_well->plate->name . "[" . $well->parent_well->well_name . "]";
        }

        if ( $well->design_instance_id ne $parent_di ) {
            &$log("[HTGTDB::Plate::correct_parentage_by_di] $well_desc has incorrect parentage.");

            if ( defined $parent_well_ids{ $well->design_instance_id } ) {
                my $new_parent_well
                    = $schema->resultset('Well')->find( { well_id => $parent_well_ids{ $well->design_instance_id } } );
                my $new_parent_well_desc = $new_parent_well->plate->name . "[" . $new_parent_well->well_name . "]";

                &$log(    "[HTGTDB::Plate::correct_parentage_by_di] Updating parent for $well_desc from '"
                        . $current_parent_desc . "' to "
                        . $new_parent_well_desc );

                use DateTime;
                my $dt   = DateTime->now;
                my $date = $dt->day . '-' . $dt->month_name . '-' . $dt->year;

                $well->update(
                    {   edit_user      => $user,
                        edit_date      => $date,
                        parent_well_id => $new_parent_well->well_id
                    }
                );
            }
        }
    }

}

=head2 have_i_had_five_arm_qc

Simple helper function to determine if any 5'arm QC tests have been run on this plate.

=cut

sub have_i_had_five_arm_qc {
    my ($plate) = @_;
    my $schema = $plate->result_source->schema;

    # Test for bands...
    my $primer_band_rs = $schema->resultset('WellData')->search(
        {   data_type       => { 'like', 'primer_band_gf%' },
            'well.plate_id' => $plate->plate_id
        },
        { join => 'well' }
    );

    # Test for reads...
    my $primer_read_rs = $schema->resultset('WellPrimerReads')->search(
        {   r1r_loc_status  => { '!=', undef },
            'well.plate_id' => $plate->plate_id
        },
        { join => 'well' }
    );

    if ( $primer_band_rs->count > 0 or $primer_read_rs->count > 0 ) {
        return 1;
    }
    else {
        return undef;
    }
}

1;
