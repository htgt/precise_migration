package HTGTDB::Allele;
use strict;
use warnings;

=head1 AUTHOR
David K. Jackson ( is evil )
Daniel Klose ( he wished he wasn't following DJ3 )

=cut

use base qw/DBIx::Class Exporter/;
our @EXPORT_OK;

__PACKAGE__->load_components( qw/PK::Auto Core/ );
__PACKAGE__->table( 'Allele' );
#__PACKAGE__->add_columns(
#    qw/
#        allele_id
#        design_id
#        bacs
#        cassette
#        esc_strain
#        labcode
#        current_allele_name_id
#        targeted_trap 
#        deletion
#        mgi_gene_id
#        /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "allele_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_allele",
    size => 126,
  },
  "design_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "bacs",
  { data_type => "varchar2", is_nullable => 0, size => 40 },
  "cassette",
  { data_type => "varchar2", is_nullable => 0, size => 80 },
  "esc_strain",
  { data_type => "varchar2", is_nullable => 0, size => 40 },
  "labcode",
  { data_type => "varchar2", is_nullable => 0, size => 40 },
  "current_allele_name_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "targeted_trap",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "deletion",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "mgi_gene_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key( qw/allele_id/ );
__PACKAGE__->add_unique_constraint(
    allele_combination => [ qw/design_id bacs cassette esc_strain labcode targeted_trap deletion/ ]
);
__PACKAGE__->sequence( 'S_ALLELE' );
__PACKAGE__->has_many( designs      => 'HTGTDB::Design',     'design_id' );
__PACKAGE__->has_many( allele_names => 'HTGTDB::AlleleName', 'allele_id' );
__PACKAGE__->belongs_to( current_allele_name => 'HTGTDB::AlleleName', 'current_allele_name_id' );
__PACKAGE__->belongs_to( mgi_gene => 'HTGTDB::MGIGene', 'mgi_gene_id' );
__PACKAGE__->has_many( projects => 'HTGTDB::Project', { 'foreign.design_id' => 'self.design_id',
                                                        'foreign.cassette'  => 'self.cassette' } );

#utility class methods
BEGIN {
    push @EXPORT_OK,
        qw( &esc_cell_line_to_strain &calc_allele_info_for_epd_well &allele_info_for_epd_well
        &setup_allele_for_epd_well &setup_all_alleles);
}

=head2 esc_cell_line_to_strain 

Convert ES cell line string into a strain

=cut

sub esc_cell_line_to_strain {    #Note this logic is also in root/gene/_es_cell_table.tt
    my ( $esc_cell_line ) = @_;
    die "Need a cell line!\n" unless $esc_cell_line;
    return 'C57BL/6N' if $esc_cell_line =~ /JM8/;
    return 'C57BL/6N' if $esc_cell_line =~ /C2/;
    return '129S7'    if $esc_cell_line =~ /AB2\.2/;
    die "Unrecognised es cell line \"$esc_cell_line\"!\n";
}

=head2 calc_allele_info_for_epd_well

Get most of the latest info required for allele name formation.

=cut

sub calc_allele_info_for_epd_well {
    my $w = shift;

    # Do search for targeted trap based on well.
    my $is_trap = "no";
    if ( $w->well_data->find( { data_type => 'targeted_trap' } ) ) {
        $is_trap = "yes";
    }

    # I always want to return a value.  I define design type and then reassign.  As I do for traps above.
    my $design_type = 'KO';
    if ( $w->design_instance->design->design_type ) {
        $design_type = $w->design_instance->design->design_type;
    }

    return (
        $w->design_instance->design_id,
        $w->bacs, $w->cassette,
        esc_cell_line_to_strain( $w->es_cell_line ),
        ( $w->well_name =~ /^H/ ? 'Hmgu' : 'Wtsi' ),
        $is_trap, $design_type
    );
}

=head2 allele_info_for_epd_well

Get all of the cached info required for allele name formation.

=cut

sub allele_info_for_epd_well {
    my $w    = shift;
    my $wsdi = $w->result_source->schema->resultset( 'WellSummaryByDI' )->find(
        { epd_well_id => $w->well_id },
        {
            key      => 'unique_epd_well_id',
            prefetch => [ 'design_instance', { project => 'mgi_gene' } ]
        }
    );
    return unless $wsdi;
    my $p = $wsdi->project;
    my $strain;
    eval { $strain = esc_cell_line_to_strain( $wsdi->es_cell_line ); };

    # Make sure that something is returned rather than a null value (yuck)
    my $is_trap = "no";
    if ( $wsdi->targeted_trap ) { $is_trap = "yes" }

    # Do the same for the design type - just in case (all DelBlocks are del blocks)
    my $design_type = 'KO';
    if ( $wsdi->design_instance->design->design_type ) {
        $design_type = $wsdi->design_instance->design->design_type;
    }

    return (
        $wsdi->design_instance->design_id,
        $wsdi->bac,
        $wsdi->cassette,
        $strain,
        ( $wsdi->epd_well_name =~ /^H/ ? 'Hmgu' : 'Wtsi' ),
        $p->mgi_gene->marker_symbol,
        (
            join ",",
            grep { $_ } ( $p->is_eucomm ? 'EUCOMM' : '' ),
            ( $p->is_komp_csd ? 'KOMP'    : '' ),
            ( $p->is_norcomm  ? 'NORCOMM' : '' )
        ),
        $is_trap,
        $design_type
    );
}

=head2 setup_allele_for_epd_well

Setup or correct allele naming for an EPD well.

=cut

sub setup_allele_for_epd_well {
    my $w = shift;

    die "Allele nomenclature can only be set up for EPD wells\n"
        unless ( $w->plate->type eq 'EPD' );
    my %param = ref $_[ 0 ] eq 'HASH' ? %{ shift @_ } : ();
    my $edit_user = $param{ edit_user } || "" . ( getpwuid( $< ) )[ 0 ];
    my $s = $w->result_source->schema;

    my (
        $design_id, $bacs,    $cassette,      $esc_strain, $labcode,
        $symbol,    $program, $targeted_trap, $design_type
    ) = allele_info_for_epd_well( $w );
    ( $design_id, $bacs, $cassette, $esc_strain, $labcode, $targeted_trap, $design_type )
        = calc_allele_info_for_epd_well( $w );    #latest info rather than overnight cache

    my $name_pre = $symbol . "<sup>tm";
    my $name_suf = "";
    if ( $design_type =~ /Del_Block/i ) {
        $name_suf = "(" . $program . ")" . $labcode . "</sup>";
    }
    else {
        if ( $targeted_trap =~ /yes/i ) { $name_suf = "e(" . $program . ")" . $labcode . "</sup>"; }
        else                            { $name_suf = "a(" . $program . ")" . $labcode . "</sup>"; }
    }

    my $targeted_trap_table_value = undef;
    my $design_type_table_value   = undef;
    if ( $targeted_trap =~ /yes/i )       { $targeted_trap_table_value = $targeted_trap; }
    if ( $design_type   =~ /Del_Block/i ) { $design_type_table_value   = 'yes'; }

    if (   ( ( $targeted_trap_table_value ) && ( $targeted_trap_table_value eq 'yes' ) )
        && ( ( $design_type_table_value ) && ( $design_type_table_value eq 'yes' ) ) )
    {
        warn " well "
            . $w->well_name
            . " is marked as BOTH a deletion design and a targeted trap\n";
        return;
    }

    # The allele either exists (based on the unique combination of di, bac, cassette, labcode, and designtype) or is
    # created. BUT what it's called (the allele name) depends on which _other_ allele this specific allele is paired
    # to. Alleles form pairs based on whether they are targeted traps or not, with all the other parameters held
    # constant
    my $allele = $s->resultset( 'Allele' )->find_or_create(
        {
            design_id     => $design_id,
            bacs          => $bacs,
            cassette      => $cassette,
            esc_strain    => $esc_strain,
            labcode       => $labcode,
            targeted_trap => $targeted_trap_table_value,
            deletion      => $design_type_table_value
        },
    );

    my $allele_name = $allele->current_allele_name;

    unless ($allele_name
        and ( $allele_name->mgi_symbol eq $symbol )
        and ( $allele_name->labcode eq $labcode ) )
    {
        my $allele_name_rs = $s->resultset( 'AlleleName' )
            ->search( { mgi_symbol => $symbol, labcode => $labcode } );
        $allele_name = $allele_name_rs->search( { allele_id => $allele->allele_id } )->first;

        if ( !$allele_name ) {
            print
                "Failed to find allele name, going to create! ( $symbol $labcode $name_pre $name_suf "
                . $allele->allele_id . ")\n";

            # Now we are committed to making a new allele name, we have to find the iteration for it.
            # That iterate depends on whether there's a _paired_ allele for this new one. If this allele is a targeted trap,
            # then the pair is a conditional for the same design, cassette etc, & vice versa.
            my $paired_tt_value;
            if ( $targeted_trap_table_value && ( $targeted_trap_table_value eq 'yes' ) ) {
                $paired_tt_value = undef;
            }
            else {
                $paired_tt_value = 'yes';
            }

            my $paired_allele = $s->resultset( 'Allele' )->find(
                {
                    design_id     => $design_id,
                    bacs          => $bacs,
                    cassette      => $cassette,
                    esc_strain    => $esc_strain,
                    labcode       => $labcode,
                    targeted_trap => $paired_tt_value,
                    deletion      => $design_type_table_value
                }
            );

            my $iteration;
            if ( !$paired_allele ) {
                my $max_iteration = $allele_name_rs->get_column( 'iteration' )->max();
                if ( !$max_iteration ) {
                    $max_iteration = 0;
                }
                print "found NO paired allele - max iterate found: $max_iteration\n";
                $iteration = $max_iteration + 1;
            }
            else {
                print "found A paired allele - cassette: " . $paired_allele->cassette . "\n";
                my $paired_allele_name = $paired_allele->current_allele_name->name;
                print "found A paired allele - name: " . $paired_allele_name . "\n";
                if ( $paired_allele_name =~ /.*<sup>tm(\d+)\w?.*<\/sup>/ ) {
                    $iteration = $1;
                }
                else {
                    die
                        "cant determine current iteration from paired allele name: $paired_allele_name\n";
                }
            }

            my $name = $name_pre . $iteration . $name_suf;
            if ( $targeted_trap_table_value eq 'yes' ) {
                $allele_name = $allele_name_rs->create(
                    {
                        iteration     => $iteration,
                        allele_id     => $allele->allele_id,
                        name          => $name,
                        targeted_trap => 'yes'
                    }
                );
            }
            else {
                $allele_name = $allele_name_rs->create(
                    {
                        iteration     => $iteration,
                        allele_id     => $allele->allele_id,
                        name          => $name,
                        targeted_trap => 'no'
                    }
                );
            }
        }
        else {
            print "Found existing allele name for allele " . $allele_name->name . "\n";
        }

        $allele->update( { current_allele_name_id => $allele_name->allele_name_id } );
    }

    print "Allele name: " . $allele_name->name . "\n";

    my $wd = $w->well_data->find( { data_type => 'allele_name', data_value => $allele_name->name },
        { key => "well_id_data_type" } );

    unless ( $wd ) {
        $wd = $w->well_data->create(
            {
                data_type  => 'allele_name',
                data_value => $allele_name->name,
                edit_user  => $edit_user
            }
        );
        print "Created NEW well data\n";
    }

    if ( $wd ) {

        # If we have well data - check that it's not changed.  If it has, update it.
        unless ( $wd->data_value eq $allele_name->name ) {
            $wd->update( { data_value => $allele_name->name, edit_user => $edit_user } );
        }
    }
    else {

        # If we don't - create one.
        $wd = $w->well_data->create(
            {
                data_type  => 'allele_name',
                data_value => $allele_name->name,
                edit_user  => $edit_user
            }
        );
        print "Updated EXISTING well data\n";
    }
    return $allele;
}

=head2 setup_all_alleles

Setup and recalc allele naming for all distributable EPD wells and those EPD wells already marked with allele names.

=cut

sub setup_all_alleles {
    my $s = shift;

    #my $w_rs = $s->resultset('Well')->search({'well_data.data_type'=>['allele_name','distribute'],'plate.type'=>'EPD'},{join=>['well_data','plate']})->search({},{distinct=>1,order_by=>'well_name'});

    my $w_rs
        = $s->resultset( 'Well' )
        ->search(
        { 'well_data.data_type' => [ 'targeted_trap', 'distribute' ], 'plate.type' => 'EPD' },
        { join                  => [ 'well_data',     'plate' ] } )
        ->search( {}, { distinct => 1, order_by => 'well_name' } );
    while ( my $w = $w_rs->next ) {
        eval {    #hack to check if we can get all the data for this well
                  #esc_cell_line_to_strain($w->es_cell_line);
            my ( $design_id, $bacs, $cassette, $esc_strain, $labcode, $symbol, $program )
                = allele_info_for_epd_well( $w );
            ( $design_id, $bacs, $cassette, $esc_strain, $labcode )
                = calc_allele_info_for_epd_well( $w );    #latest info rather than overnight cache
            die "missing data for allele generation: "
                . join( ",",
                map { defined $_ ? $_ : "" } $design_id,
                $bacs, $cassette, $esc_strain, $labcode, $symbol, $program )
                . "\n"
                if scalar(
                @{
                    [
                        grep { !$_ } $design_id,
                        $bacs, $cassette, $esc_strain, $labcode, $symbol, $program
                    ]
                    }
                );
            $w->cassette;
        };
        unless ( $@ ) {
            setup_allele_for_epd_well( $w );
        }
        else { print $w->well_name . " $@\n"; }
    }
}
return 1;

