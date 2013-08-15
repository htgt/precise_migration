package HTGTDB::Design;

use strict;
use warnings;
use HTGTDB::DisplayExon;
our ($tagname) = '$Name:  $' =~ /^\$Name:  $$/;    #Don't let PerlTidy screw this up....

=head1 AUTHOR

Vivek Iyer
David K. Jackson <david.jackson@sanger.ac.uk>

=cut

use base qw/DBIx::Class/;
require HTGT::Utils::Design::Info;
require TargetedTrap::IVSA::SyntheticConstruct;
use Bio::Perl;
use Carp 'confess';
require Bio::SeqUtils;
require Bio::SeqFeature::Generic;
require Bio::Annotation::DBLink;
require Bio::Annotation::Comment;
use RecombinantUtils qw(recombineer gateway);

__PACKAGE__->load_components(qw/InflateColumn::DateTime PK::Auto Core/);

__PACKAGE__->table('design');

__PACKAGE__->sequence('S_98_1_DESIGN');

#__PACKAGE__->add_columns(
#    qw/
#      design_id
#      target_id
#      build_id
#      design_name
#      pseudo_plate
#      final_plate
#      well_loc
#      design_parameter_id
#      locus_id
#      start_exon_id
#      end_exon_id
#      gene_build_id
#      random_name
#      created_user
#      sp
#      tm
#      atg
#      phase
#      pi
#      design_type
#      subtype
#      subtype_description
#      validated_by_annotation
#      edited_date
#      edited_by
#      has_ensembl_image
#      /,
#      created_date => { data_type => 'date' }
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_98_1_design",
    size => [10, 0],
  },
  "target_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "build_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_name",
  { data_type => "varchar2", is_nullable => 1, size => 45 },
  "pseudo_plate",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "final_plate",
  { data_type => "varchar2", is_nullable => 1, size => 45 },
  "well_loc",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "design_parameter_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "locus_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "random_name",
  { data_type => "varchar2", is_nullable => 1, size => 125 },
  "start_exon_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "end_exon_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gene_build_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lr_status",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "created_date",
  {
    data_type     => "datetime",
    default_value => \"systimestamp",
    is_nullable   => 1,
    original      => { data_type => "date" },
  },
  "sp",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "tm",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "atg",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "phase",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "pi",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "created_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "design_type",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "subtype",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "subtype_description",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
  "validated_by_annotation",
  { data_type => "varchar2", is_nullable => 1, size => 10 },
  "edited_date",
  {
    data_type     => "datetime",
    default_value => \"systimestamp",
    is_nullable   => 1,
  },
  "edited_by",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "has_ensembl_image",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('design_id');

__PACKAGE__->has_many( design_bacs => 'HTGTDB::DesignBAC', 'design_id' );
__PACKAGE__->many_to_many( bacs => 'design_bacs', 'bac_clone_id' );

__PACKAGE__->has_many( statuses             => "HTGTDB::DesignStatus",       'design_id' );
__PACKAGE__->has_many( features             => "HTGTDB::Feature",            'design_id' );
__PACKAGE__->has_many( notes                => "HTGTDB::DesignNote",         'design_id' );
__PACKAGE__->has_many( design_statuses      => "HTGTDB::DesignStatus",       'design_id' );
__PACKAGE__->has_many( design_notes         => "HTGTDB::DesignNote",         'design_id' );
__PACKAGE__->has_many( design_design_group  => 'HTGTDB::DesignDesignGroup',  'design_id' );
__PACKAGE__->has_many( design_instances     => 'HTGTDB::DesignInstance',     'design_id' );
__PACKAGE__->has_many( design_user_comments => 'HTGTDB::DesignUserComments', 'design_id' );
__PACKAGE__->has_many( projects             => 'HTGTDB::Project',            'design_id' );
__PACKAGE__->has_many( design_annotations   => 'HTGTDB::DesignAnnotation',   'design_id' );


__PACKAGE__->belongs_to( design_parameter => 'HTGTDB::DesignParameter', 'design_parameter_id' );
__PACKAGE__->belongs_to( locus            => 'HTGTDB::GnmLocus',        'locus_id' );
__PACKAGE__->belongs_to( start_exon       => 'HTGTDB::GnmExon',         'start_exon_id' );
__PACKAGE__->belongs_to( end_exon         => 'HTGTDB::GnmExon',         'end_exon_id' );
__PACKAGE__->belongs_to( gene_build       => 'HTGTDB::GnmGeneBuild',    'gene_build_id' )
  ;    #ditch this as unused/misleading?
__PACKAGE__->belongs_to( design_parameter => "HTGTDB::DesignParameter", 'design_parameter_id' );

__PACKAGE__->has_many( taqman_assays => "HTGTDB::DesignTaqmanAssay",  'design_id' );

__PACKAGE__->mk_group_accessors( simple => '_design_info' );

sub info {
    my $self = shift;

    unless ( $self->_design_info ) {
        $self->_design_info( HTGT::Utils::Design::Info->new( design => $self ) );
    }

    $self->_design_info;
}

sub is_recovery_design {
    my $self = shift;

    return $self->design_user_comments_rs->search(
        {
            'category.category_name' => 'Recovery design'
        },
        {
            join => 'category'
        }
    )->count;
}

=head2 is_insertion

Simple method to check if design type is a deletion.

=cut

sub is_insertion {
    my $self = shift @_;
    return ( defined( $self->design_type ) and $self->design_type =~ /^ins/i );
}

=head2 is_deletion

Simple method to check if design type is a deletion.

=cut

sub is_deletion {
    my $self = shift @_;
    return ( defined( $self->design_type ) and $self->design_type =~ /^del/i );
}

=head2 is_artificial_intron

Returns true if design has a comment in the 'Artificial intron design' category, otherwise false.

=cut

sub is_artificial_intron {
    my $self = shift;

    $self->search_related_rs( 'design_user_comments',
                              {
                                  'category.category_name' => 'Artificial intron design'
                              },
                              {
                                  join => 'category'
                              }
                          )->count > 0;
}

=head2 is_intron_replacement

Returns true if design has a comment in the 'Intron replacement' category, otherwise false.

=cut

sub is_intron_replacement {
    my $self = shift;

    $self->search_related_rs( 'design_user_comments',
                              {
                                  'category.category_name' => 'Intron replacement'
                              },
                              {
                                  join => 'category'
                              }
                          )->count > 0;
}

=head2 find_or_create_name

If the design has a design_name, return it. Otherwise update the
design with a name provided via the S_DESIGN_NAME sequence and return
the newly-generated name.

=cut

sub find_or_create_name {
    my $self = shift;

    my $name = $self->design_name;

    if ( ! $name ) {
        my ( $num ) = $self->result_source->schema->storage->dbh_do(
            sub {
                $_[1]->selectrow_array( "SELECT S_DESIGN_NAME.NEXTVAL FROM DUAL" );
            }
        );
        confess "Failed to retrieve S_DESIGN_NAME.NEXTVAL" unless $num;
        $name = 'EUCTV' . $num;
        $self->update( { design_name => $name } );
    }

    return $name;
}

=head2 validated_features

Get resultset of features which have a validated feature data type - the "valid" features hopefully....

=cut

sub validated_features {
    my $d = shift;
    return $d->features->search(
        { q(feature_data.feature_data_type.description) => q(validated) },
        { join => { q(feature_data) => q(feature_data_type) }, distinct => 1 }
    );
}


=head2 validated_display_features

Return a hash, keyed on feature type description, of validated display features for this design.

=cut

sub validated_display_features {
    my $design = shift;

    my $validated_features = $design->search_related(
        features => {
            'feature_data_type.description' => 'validated'
        },
        {
            join => {
                feature_data => 'feature_data_type'
            }
        }
    );

    my $validated_display_features = $validated_features->search_related(
        display_features => {
            assembly_id => 101,
            label       => 'construct'
        },
        {
            prefetch => [
                {
                   feature => 'feature_type'
                },
                'chromosome',
            ]
        }
    );

    my %display_feature_for;

    while ( my $df = $validated_display_features->next ) {
        my $type = $df->feature->feature_type->description;
        die "Multiple $type features\n" if exists $display_feature_for{ $type };
        $display_feature_for{ $type } = $df;
    }

    return \%display_feature_for;
}

=head2 wildtype_seq

Return a BioSeq object of the region of interest annotated appropriately (with the primers we'll use for recombineering and genotyping, exons, etc). Also returns coordinates for G5_U5, U3_D5 and D3_G3 on this sequence.

=cut

sub wildtype_seq {
    my $d   = shift;
    my @res = $d->_wildtype_seq_without_seq_annotation;
    $d->_add_design_annotation_to_seq( $res[0] );
    return @res;
}

sub _add_design_annotation_to_seq {
    my ( $d, $seq ) = @_;
    $seq->annotation->add_Annotation(
        "dblink",
        Bio::Annotation::DBLink->new(
            -database   => "HTGT",
            -authority  => "sanger.ac.uk",
            -primary_id => "design_id=" . $d->design_id,
            -url => "http://www.sanger.ac.uk/htgt/design/designedit/refresh_design?design_id="
              . $d->design_id
        )
    );
    $seq->annotation->add_Annotation( 'comment',
        Bio::Annotation::Comment->new( '-text' => "design_id : " . $d->design_id ) );
    return $seq;
}

sub _wildtype_seq_without_seq_annotation {

#Note that sequences for recombineering primers [GUD][53] are Gospel, there are off by ones on their coordinates however.
#(For plates 13 and 1 the sequences may be the revcom wrt convention in this DB)
#These coordinates are used for retrieving U5_15 G5_U5 U3_D5 D3_G3 D3_15 sequences - which therefore have their sequences
#and coordinates wrong by a base (though coordinates and sequence are consistent).
#The above sequences are all chromosome forward strand - there is a flag indicating whether they should rev comp'd for use.
#Some _15 arms have completely wrong coordinates.

#TODO: the above assuptions are incorrect - it seems the recomb primers have right coordinates - other stuff is wrong....
    my $d      = shift;
    my $strand = $d->locus->chr_strand;    # 1 or -1
    my $frs    = $d->validated_features;
    my $chr_name;

    #print STDERR "\n".$d->id." $strand\n";

    #Get recombineering primers and associated sequence sections
    my %seq_strings;                                #sequence strings
    my %sf;                                #sequence "features"
    my %fo;                                #feature orientation relative to gene
    my %fs;                                #feature gene oriented start position in chr coord
    my %display_feature_starts;             #feature starts in NCBIM37 coordinates

    # Populate the array of seqfeatures, strings, orientations and start positions
    foreach (
        qw(U5_15 G5 G5_U5 U5 U3 U3_D5 D5 D3 D3_G3 G3 D3_15 15_E_15 U5_D3 D5_D3)
    ){
        if ( $d->is_deletion or $d->is_insertion ) {
            next if ( $_ eq 'U3' or $_ eq 'D5' or $_ eq 'U3_D5' or $_ eq 'D5_D3');
        }

        my $feature = $frs->search( { q(feature_type.description) => $_ }, { join => q(feature_type) } )->first;

        if ($feature) {
            my $string = $feature->get_seq_str;
            $string = revcom_as_string($string) if $strand < 0;    #seq in sense of gene
            my $orient = ( { map { $_ => 1 } qw(G5 U3 D3) }->{$_} ? -1 : 1 );

            warn "dodgy orientation info for $_ on design "
              . $d->id
              . " (strand $strand, is_mrc:"
              . ( $feature->is_mrc ? "y" : "n" ) . ")"
              if ( $strand * $orient * ( $feature->is_mrc ? -1 : 1 ) ) < 0;

            $sf{$_} = $feature;
            $seq_strings{$_} = $string;
            $fo{$_} = $orient;
            $fs{$_} = ( $strand < 0 ) ? $feature->feature_end : $feature->feature_start;
            if($_ eq 'G5' || $_ eq 'U5' || $_ eq 'D3' || $_ eq 'G3'){
                my $display_feature = $feature->display_features->search( { assembly_id => 101 } )->first;
                $chr_name = $display_feature->chromosome->name;
                $display_feature_starts{$display_feature->display_feature_type} = $display_feature->feature_start;
            }
        }
    }

#correct for potential off by one on recombineering primers' locii (and dodgy orientation of primer - conventionally in forward strand of chr):
    foreach ( [qw(G5 G5_U5)], ( ( $d->is_deletion or $d->is_insertion ) ? () : ( [qw(U3 U3_D5)] ) ),
        [qw(D3 D3_G3)] )
    {
        my $p    = substr( $seq_strings{ $_->[0] }, 1 );                   #all but first base of primer
        my $g    = substr( $seq_strings{ $_->[1] }, 0, length($p) + 2 );
        my $toff = index( $g,              $p );
        if ( $toff < 0 ) {    #lets check to see if primer seq is in unconventionally
            $p = substr( revcom_as_string( $seq_strings{ $_->[0] } ), 1 );
            $toff = index( $g, $p );
            if ( $toff >= 0 ) {
                $seq_strings{ $_->[0] } = revcom_as_string( $seq_strings{ $_->[0] } );
                warn "Primer "
                  . $_->[0]
                  . " sequence for design "
                  . $d->id
                  . " found in DB in unconventional orientation";
            }
        }    #note when primer is aligned exactly at the end toff is 1
        if ( $toff >= 0 ) {  # set location of primer from offset in genomic and location of genomic
            my $corr = $fs{ $_->[1] } + ( $toff - 1 ) * $strand - $fs{ $_->[0] };
            $fs{ $_->[0] } += $corr;
            die "Coordinates for "
              . $_->[0] . " and "
              . $_->[1]
              . " conflicting by more than 1bp for design "
              . $d->id
              if ( $corr * $corr ) > 1;
        } else {
            die "Cannot align " . $_->[0] . " within " . $_->[1] . " for design " . $d->id;
        }
    }
    foreach ( [qw(U5 G5_U5)], ( ( $d->is_deletion or $d->is_insertion ) ? () : ( [qw(D5 U3_D5)] ) ),
        [qw(G3 D3_G3)] )
    {
        my $p
          = substr( $seq_strings{ $_->[0] }, 0, length( $seq_strings{ $_->[0] } ) - 1 );  #all but last base of primer
        my $g = substr( $seq_strings{ $_->[1] }, -1 * ( length($p) + 2 ) );
        my $toff = index( $g, $p );
        if ( $toff < 0 ) {    #lets check to see if primer seq is in unconventionally
            $p = substr( revcom_as_string( $seq_strings{ $_->[0] } ), 0, length( $seq_strings{ $_->[0] } ) - 1 );
            $toff = index( $g, $p );
            if ( $toff >= 0 ) {
                $seq_strings{ $_->[0] } = revcom_as_string( $seq_strings{ $_->[0] } );
                warn "Primer "
                  . $_->[0]
                  . " sequence for design "
                  . $d->id
                  . " found in DB in unconventional orientation";
            }
        }
        if ( $toff >= 0 ) {  # set location of primer from offset in genomic and location of genomic
            my $corr
              = $fs{ $_->[1] }
              + ( length( $seq_strings{ $_->[1] } ) - length( $seq_strings{ $_->[0] } ) + $toff - 1 ) * $strand
              - $fs{ $_->[0] };
            $fs{ $_->[0] } += $corr;
            die "Coordinates for "
              . $_->[0] . " and "
              . $_->[1]
              . " conflicting by more than 1bp for design "
              . $d->id
              if ( $corr * $corr ) > 1;
        } else {
            die "Cannot align " . $_->[0] . " within " . $_->[1] . " for design " . $d->id;
        }
    }

    #correct for dodgy _15 coordinates
    if ( $seq_strings{D3_G3} eq substr( $seq_strings{D3_15}, 0, length( $seq_strings{D3_G3} ) ) ) {
        $fs{D3_15} = $fs{D3_G3} if ( $fs{D3_15} != $fs{D3_G3} );
    } elsif ( $seq_strings{D3} eq substr( $seq_strings{D3_15}, 0, length( $seq_strings{D3} ) ) ) {
        $fs{D3_15} = $fs{D3} if ( $fs{D3_15} != $fs{D3} );
    } elsif (
        (   my $toff
            = index( substr( $seq_strings{D3_15}, 0, length( $seq_strings{D3_G3} ) + 1 ), substr( $seq_strings{D3_G3}, 1 ) )
        ) >= 0
      )
    {    #check for off by one on _15 coord (trust D3_G3)
        $fs{D3_15} = $fs{D3_G3} + ( 1 - $toff ) * $strand;
    } else {
        die "D3_15 seq not matching D3_G3 or D3 for design " . $d->id;
    }
    if ( $seq_strings{G5_U5} eq substr( $seq_strings{U5_15}, -1 * length( $seq_strings{G5_U5} ) ) ) {
        $fs{U5_15} = $fs{G5_U5} + $strand * ( length( $seq_strings{G5_U5} ) - length( $seq_strings{U5_15} ) )
          if ( ( $fs{U5_15} + $strand * length( $seq_strings{U5_15} ) )
            != ( $fs{G5_U5} + $strand * length( $seq_strings{G5_U5} ) ) );
    } elsif ( $seq_strings{U5} eq substr( $seq_strings{U5_15}, -1 * length( $seq_strings{U5} ) ) ) {
        $fs{U5_15} = $fs{U5} + $strand * ( length( $seq_strings{U5} ) - length( $seq_strings{U5_15} ) )
          if ( ( $fs{U5_15} + $strand * length( $seq_strings{U5_15} ) )
            != ( $fs{U5} + $strand * length( $seq_strings{U5} ) ) );
    } elsif (
        (   my $toff = index(
                substr( $seq_strings{U5_15}, -1 * ( length( $seq_strings{G5_U5} ) + 1 ) ),
                substr( $seq_strings{G5_U5}, 0, length( $seq_strings{G5_U5} ) - 1 )
            )
        ) >= 0
      )
    {    #check for off by one on _15 coord (trust G5_U5)
        $fs{U5_15}
          = $fs{G5_U5} + ( length( $seq_strings{G5_U5} ) - length( $seq_strings{U5_15} ) + 1 - $toff ) * $strand;
    } else {
        die "U5_15 seq not matching G5_U5 or U5 for design " . $d->id;
    }

    #assemble sequence from components
    my @fs = sort { $a <=> $b } values %fs;    #print STDERR $fs[0].",".$fs[-1];
    my %fs0;                                   #zero based feature start in coord in sense of gene
    if ( $strand < 0 ) {
        $fs0{$_} = $fs[-1] - $fs{$_} foreach keys %fs;
    } else {
        $fs0{$_} = $fs{$_} - $fs[0] foreach keys %fs;
    }
    my ($seqlen) = sort { $b <=> $a } map { $fs0{$_} + length( $seq_strings{$_} ) } keys %fs0;
    my $seqstr = q(X) x $seqlen;               #any regions we don't have sequence for will be XXX
    foreach ( sort { $fs0{$a} <=> $fs0{$b} } keys %fs0 ) {
        my $s = $seq_strings{$_};
        substr( $seqstr, $fs0{$_}, length($s) ) = $s;
    }
    foreach ( keys %fs0 ) {
        next if ( $_ eq '15_E_15' );
        my $s = $seq_strings{$_};
        die "Conflicting sequence overlapping $_ in design " . $d->id
          unless substr( $seqstr, $fs0{$_}, length($s) ) eq $s;
    }

    #annotate primers, sections?
    my $display_id = "allele_" . $d->id;
    if ( my $se = $d->start_exon ) {
        $display_id .= "_" . $se->primary_name;
        if ( my $ee = $d->end_exon ) {
            if ( $ee->id != $se->id ) { $display_id .= "-" . $ee->primary_name; }
        }
    }
    $display_id .= "_wt";
    my %fh;    #hash of features
    my $seq = new Bio::Seq( -circular => 0, -alphabet => q(dna), -seq => $seqstr,
        -display_id => $display_id );


    foreach ( qw(G5 U5), ( ( $d->is_deletion or $d->is_insertion ) ? () : qw(U3 D5) ), qw(D3 G3) ) {
        my $f = new Bio::SeqFeature::Generic(
            -start        => $fs0{$_} + 1,
            -end          => $fs0{$_} + length( $seq_strings{$_} ),
            -strand       => $fo{$_},
            -primary_tag  => q(rcmb_primer),
            -display_name => "$_ recombineering primer",
            -tag          => { note => $_, type => $_, label => $_ },
        );
        $seq->add_SeqFeature($f);
        $fh{$_} = $f;
    }

    #get seq from from these features - check consistent
    foreach ( grep { $_->primary_tag eq q(rcmb_primer) } $seq->get_SeqFeatures() ) {
        my ($type) = $_->get_tag_values(q(type));
        die "internal $type primer sequence mismatch: " . $_->seq->seq . " != " . $seq_strings{$type}
          unless (
            $_->seq->seq eq ( $fo{$type} < 0 ? revcom_as_string( $seq_strings{$type} ) : $seq_strings{$type} ) );
    }

    $d->annotate_display_exons($seq, $chr_name, $strand, \%fs0, \%display_feature_starts, \%seq_strings);

    #annotate exons
#    my $te = 0;
#    foreach my $e (
#        sort {
#            $strand * (
#                     $a->locus->chr_start <=> $b->locus->chr_start
#                  or $b->locus->chr_end <=> $a->locus->chr_end
#              )
#        } $d->start_exon->transcript->exons
#      )
#    {
#
#        my $l = $e->locus->chr_end - $e->locus->chr_start + 1;
#        my $fs0 = $strand < 0 ? $fs[-1] - $e->locus->chr_end : $e->locus->chr_start - $fs[0];
#        next if ( $fs0 < 0 or ( $fs0 + $l ) > $seq->length );   #avoid features hanging off the ends
#        $te = 1 if $e->primary_name eq $d->start_exon->primary_name;
#        $seq->add_SeqFeature(
#            new Bio::SeqFeature::Generic(
#                -start        => $fs0 + 1,
#                -end          => $fs0 + $l,
#                -strand       => 1,
#                -primary_tag  => q(exon),
#                -display_name => $e->primary_name,
#                -tag          => {
#                    note => ( $te ? [ "target exon $te", $e->primary_name ] : $e->primary_name ),
#                    ( $te ? ( type => q(targeted) ) : () ),
#                    db_xref => q(ens:) . $e->primary_name
#                },
#            )
#        );
#        $te++ if $te;
#        $te = 0 if $e->primary_name eq $d->end_exon->primary_name;
#    }

    #
    #align and annotate custom lrpcr primers  - no position info stored so need to align
    foreach (
        $frs->search(
            { q(feature_type.description) => { q(like), [ q(G__), q(EX__) ] } },
            { join => q(feature_type) }
        )
      )
    {
        my $type = $_->feature_type->description;
        my $ss   = $_->get_seq_str;
        my $fs0  = index( $seqstr, $ss );
        my $fo   = 1;
        if ( $fs0 < 0 ) {    #not aligned on forward strand (gene orientation)
            $ss  = revcom_as_string($ss);
            $fs0 = index( $seqstr, $ss );
            $fo  = -1;
            warn "unable to align on sequence associated with design " . $d->id if ( $fs0 < 0 );
        }
        $seq->add_SeqFeature(
            new Bio::SeqFeature::Generic(
                -start        => $fs0 + 1,
                -end          => $fs0 + length($ss),
                -strand       => $fo,
                -primary_tag  => q(LRPCR_primer),
                -display_name => "$type LRPCR primer",
                -tag          => { note => $type, type => $type },
            )
        );
    }

    #annotate 5' homology arm, target region, 3' homology arm
    $seq->add_SeqFeature(
        new Bio::SeqFeature::Generic(
            -start        => $fs0{G5} + 1,
            -end          => $fs0{U5} + length( $seq_strings{U5} ),
            -strand       => 1,
            -primary      => 'genomic',
            -source_tag   => 'synthetic_construct',
            -display_name => '5_arm',
            -tag          => { note => '5 arm' }
        )
    );
    unless ( $d->is_deletion or $d->is_insertion ) {
        $seq->add_SeqFeature(
            new Bio::SeqFeature::Generic(
                -start        => $fs0{U3} + 1,
                -end          => $fs0{D5} + length( $seq_strings{D5} ),
                -strand       => 1,
                -primary      => 'genomic',
                -source_tag   => 'synthetic_construct',
                -display_name => 'target_region',
                -tag          => { note => 'target region' }
            )
        );
    }
    $seq->add_SeqFeature(
        new Bio::SeqFeature::Generic(
            -start        => $fs0{D3} + 1,
            -end          => $fs0{G3} + length( $seq_strings{G3} ),
            -strand       => 1,
            -primary      => 'genomic',
            -source_tag   => 'synthetic_construct',
            -display_name => '3_arm',
            -tag          => { note => '3 arm' }
        )
    );

    return $seq, $fs0{G5} + 1, $fs0{U5} + length( $seq_strings{U5} ),
      (   ( $d->is_deletion or $d->is_insertion )
        ? ( undef, undef )
        : ( $fs0{U3} + 1, $fs0{D5} + length( $seq_strings{D5} ) ) ), $fs0{D3} + 1,
      $fs0{G3} + length( $seq_strings{G3} ), \%fs, \%fh;

    #note that the return of \%fs should be considered "at risk"
}

our %appends_for_KO_artificial_intron = (
    "G3" => "CCACTGGCCGTCGTTTTACA",
    "G5" => "TCCTGTGTGAAATTGTTATCCGC",
    "D3" => "TGAACTGATGGCGAGCTCAGACC",
    "D5" => "GAGATGGCGCAACGCAATTAATG",
    # Mamta added 4bp onto this append in Sept 2012 - won't change synvecs at all.
    "U3" => "CTGAAGGAAATTAGATGTAAGGAGC",
    "U5" => "GTGAGTGTGCTAGAGGGGGTG",
);

our %appends_for_KO = (
    "G3" => "CCACTGGCCGTCGTTTTACA",
    "G5" => "TCCTGTGTGAAATTGTTATCCGC",
    "D3" => "TGAACTGATGGCGAGCTCAGACC",
    "D5" => "GAGATGGCGCAACGCAATTAATG",
    "U3" => "CCGCCTACTGCGACTATAGA",
    "U5" => "AAGGCGCATAACGATACCAC",
);
our %appends_for_Block_specified = (
    "G3" => "CCACTGGCCGTCGTTTTACA",
    "G5" => "TCCTGTGTGAAATTGTTATCCGC",
    "U5" => "AAGGCGCATAACGATACCAC",
    "D3" => "CCGCCTACTGCGACTATAGA",
);
our %appends_for_location_specified = (
    "G3" => "CCACTGGCCGTCGTTTTACA",
    "G5" => "TCCTGTGTGAAATTGTTATCCGC",
    "D3" => "TGAACTGATGGCGAGCTCAGACC",
    "D5" => "GAGATGGCGCAACGCAATTAATG",
    "U3" => "CCGCCTACTGCGACTATAGA",
    "U5" => "AAGGCGCATAACGATACCAC",
);

# NorComm construct is different from normal one, it swap G3/G5.
our %appends_for_KO_for_NorComm = (
    "G5" => "CCACTGGCCGTCGTTTTACA",
    "G3" => "TCCTGTGTGAAATTGTTATCCGC",
    "D3" => "TGAACTGATGGCGAGCTCAGACC",
    "D5" => "GAGATGGCGCAACGCAATTAATG",
    "U3" => "CCGCCTACTGCGACTATAGA",
    "U5" => "AAGGCGCATAACGATACCAC",
);

our %appends_for_Block_specified_for_NorComm = (
    "G5" => "CCACTGGCCGTCGTTTTACA",
    "G3" => "TCCTGTGTGAAATTGTTATCCGC",
    "U5" => "AAGGCGCATAACGATACCAC",
    "D3" => "CCGCCTACTGCGACTATAGA",
);

=head2 annotate_display_exons

Add SeqFeatures onto the input bioseq, where the seq-features
are the display-exons held in the display_exon table.

=cut

sub annotate_display_exons {
    my ($self,  $bioseq, $chr_name, $strand, $zero_offset_starts, $display_feature_starts, $sequences) = @_;
    my $schema = $self->result_source->schema;

    my $primer_length = 50;

     #Note the way zero_offset_starts has been constructed: regardless of strand, it  starts at 0,
     #and proceeds to increase until it hits the G5 start, then proceeds till it finishes at G3 start.

     #By contrast, the display_feature_starts are in genomic coordinates. BUT they do take into account that
     #the start of the display-feature on a negative strand is a _bigger_ number than its end.

    #First get the beginning and end of the bioseq in reference assembly coordinates.
    my $offset_of_g5_into_bioseq = $zero_offset_starts->{G5};
    my $genomic_start_of_g5 = $display_feature_starts->{G5};
    my $g5_seq_string = $sequences->{G5};
    my $genomic_end_of_g5 = $genomic_start_of_g5 + length($g5_seq_string) - 1;

    #my $genomic_end_of_u5 = $display_feature_starts->{U5} + $strand * ($primer_length - 1);
    #my $genomic_start_of_u3 = $display_feature_starts->{U3};
    #my $genomic_end_of_d3 = $display_feature_starts->{D3} + $strand * ($primer_length - 1);
    #my $genomic_start_of_d5 = $display_feature_starts->{D5};

    my $lower_exon_bound;
    my $upper_exon_bound;

    if($strand > 0){
        $lower_exon_bound = $genomic_start_of_g5 - $offset_of_g5_into_bioseq;
        $upper_exon_bound = $genomic_start_of_g5 + length($bioseq->seq) - $offset_of_g5_into_bioseq + 1;
    }else{
        $upper_exon_bound = $genomic_start_of_g5 + $offset_of_g5_into_bioseq;
        $lower_exon_bound = $genomic_start_of_g5 - length($bioseq->seq) - $offset_of_g5_into_bioseq + 1;
    }

    #print STDERR "searching for exons between: $chr_name, $lower_exon_bound, $upper_exon_bound\n";
    my @visible_display_exons =
        $schema->resultset('HTGTDB::DisplayExon')->search({
            chr_name => $chr_name,
            chr_start => {'>', $lower_exon_bound},
            chr_end => {'<', $upper_exon_bound},
            chr_strand => $strand
        });

    #print STDERR "returned ".@visible_display_exons." exons\n";

    #annotate exons
    my $target_exon_count = 0;
    foreach my $exon ( sort { $strand * ($a->chr_start <=> $b->chr_start) } @visible_display_exons ) {

        my $exon_length = $exon->chr_end - $exon->chr_start + 1;
        my $exon_offset_into_bioseq;
        my $tag = { note => $exon->ensembl_exon_stable_id, db_xref => 'ens:'.$exon->ensembl_exon_stable_id };
        if($strand > 0){
            $exon_offset_into_bioseq = $offset_of_g5_into_bioseq + ($exon->chr_start - $genomic_start_of_g5);
            if($exon->chr_start >= $display_feature_starts->{U5} && $exon->chr_end <= $display_feature_starts->{D3}){
                $target_exon_count++;
                $tag->{type} = 'targeted';
                $tag->{note} = "target exon $target_exon_count ".$exon->ensembl_exon_stable_id;
            }
        }else{
            $exon_offset_into_bioseq = $offset_of_g5_into_bioseq + ($genomic_end_of_g5 - $exon->chr_end);
            if($exon->chr_start >= $display_feature_starts->{D3} && $exon->chr_end <= $display_feature_starts->{U5}){
                $target_exon_count++;
                $tag->{type} = 'targeted';
                $tag->{note} = "target exon $target_exon_count ".$exon->ensembl_exon_stable_id;
            }
        }


        my $exon_start;
        my $exon_end;

        # the offset-into-bioseq is independent of gene strand, so end = offset + length, regardless of strand
        $exon_start = $exon_offset_into_bioseq + 1;
        $exon_end = $exon_offset_into_bioseq + $exon_length;

        $bioseq->add_SeqFeature(
            new Bio::SeqFeature::Generic(
                -start        => $exon_start,
                -end          => $exon_end,
                -strand       => 1,
                -primary_tag  => 'exon',
                -display_name => $exon->ensembl_exon_stable_id,
                -tag          => $tag
            )
        );
    }
}

=head2 default_recombination_oligo_suffix

Default DNA seq appended to design specific recombination oligos.

=cut

sub default_recombination_oligo_suffix {
    my ( $d, $oligo_type ) = @_;
    my %h;
    if ( $d->is_deletion or $d->is_insertion ) {
        %h = %appends_for_Block_specified;
    } else {
        %h = %appends_for_KO;
    }
    my $r = $h{$oligo_type};
    die "No default $oligo_type oligo for design " . $d->id unless $r;
    return $r;
}

=head2 allele_seq

Returns Bio::SeqI object for allele - mutant if cassette is given, else wildtype.

=cut

# change to include targeted_trap flag.
sub allele_seq {
    my ( $self, $cs, $tt ) = @_;
    return $self->_common_seq( $cs, undef, 'allele', $tt );
}

sub allele_seq_old {
    my ( $self, $cs ) = @_;
    my ( $wt, $Us, $Ue, $Ts, $Te, $Ds, $De ) = $self->_wildtype_seq_without_seq_annotation;
    my $a;
    if ($cs) {
        my $U = Bio::SeqUtils->trunc_with_features( $wt, 1, $Ue );
        $U->add_SeqFeature(
            new Bio::SeqFeature::Generic(
                -start        => 1,
                -end          => $U->length,
                -strand       => 1,
                -primary      => 'genomic',
                -source_tag   => 'synthetic_construct',
                -display_name => '5_arm',
                -tag          => { note => '5 arm' }
            )
        );
        my $T;
        if ( not( $self->is_deletion or $self->is_insertion ) ) {
            $T = Bio::SeqUtils->trunc_with_features( $wt, $Ts, $Te );
            $T->add_SeqFeature(
                new Bio::SeqFeature::Generic(
                    -start        => 1,
                    -end          => $T->length,
                    -strand       => 1,
                    -primary      => 'genomic',
                    -source_tag   => 'synthetic_construct',
                    -display_name => 'target_region',
                    -tag          => { note => 'target region' }
                )
            );
        }
        my $D = Bio::SeqUtils->trunc_with_features( $wt, $Ds, $wt->length );
        $D->add_SeqFeature(
            new Bio::SeqFeature::Generic(
                -start        => 1,
                -end          => $D->length,
                -strand       => 1,
                -primary      => 'genomic',
                -source_tag   => 'synthetic_construct',
                -display_name => '3_arm',
                -tag          => { note => '3 arm' }
            )
        );
        my $sc = new TargetedTrap::IVSA::SyntheticConstruct;
        $sc->synth_stage('allele');
        $sc->gateway_cassette_tag($cs);
        $a = $sc->create_allele_v1( $U, $T, $D );
        $a->annotation->add_Annotation( 'comment',
            Bio::Annotation::Comment->new( '-text' => "cassette : " . $cs ) );
        my $id = $wt->display_id;
        $id =~ s/_wt$/_$cs/;
        $a->display_id($id);
    } else {
        $a = $wt;
    }
    $self->_add_design_annotation_to_seq($a);
    return $a;
}

=head2 vector_seq

Returns Bio::SeqI object for vector - targeting vector if cassette is given, else intermediate.

=cut

sub vector_seq {
    my ( $self, $cs, $bb ) = @_;
    return $self->_common_seq( $cs, $bb, 'vector' );
}

# change to inclue targeted_trap flag, 1 or 0. 04/06/09 wy1
sub _common_seq {
    my ( $self, $cs, $bb, $stage, $targeted_trap ) = @_;
    my ( $seq, $Us, $Ue, $Ts, $Te, $Ds, $De, $fsh, $featurehash )
      = $self->_wildtype_seq_without_seq_annotation;

    if ( $stage eq 'vector' or $bb or $cs ) {
        my $id = $seq->display_id;

        my $pl1;
        if ( $cs and not( $cs =~ /^L1L2|L2L1/ or ( $cs eq 'default' ) ) ) {
            $pl1 = TargetedTrap::IVSA::SyntheticConstruct::get_cassette_vector_seq($cs);
        } else {    #default recombineering
            $pl1 = TargetedTrap::IVSA::SyntheticConstruct::rich_r1r2_zp();
        }
        if ( $self->is_deletion or $self->is_insertion ) {
            ###1st U recombineer - deletion/insertion (normally gateway ready) cassette
            # no 2nd recombineer step
            $seq = recombineer(
                $seq, $pl1,
                $featurehash->{U5},

  #revcom_as_string($self->default_recombination_oligo_suffix('U5')), #alternative to location below
                Bio::Location::Simple->new( -start => 1, -end => 20, strand => -1 ),
                $featurehash->{D3},

  #revcom_as_string($self->default_recombination_oligo_suffix('D3')), #alternative to location below
                Bio::Location::Simple->new(
                    -start => ( $pl1->length - 19 ),
                    -end   => $pl1->length,
                    strand => +1
                ),
            );
            $seq->display_id("$id-U");
        } else {
            ###1st U recombineer - upstream (normally gateway ready) cassette
            $seq = recombineer(
                $seq, $pl1,
                $featurehash->{U5},

  #revcom_as_string($self->default_recombination_oligo_suffix('U5')), #alternative to location below
                Bio::Location::Simple->new( -start => 1, -end => 20, strand => -1 ),
                $featurehash->{U3},

  #revcom_as_string($self->default_recombination_oligo_suffix('U3')), #alternative to location below
                Bio::Location::Simple->new(
                    -start => ( $pl1->length - 19 ),
                    -end   => $pl1->length,
                    strand => +1
                ),
            );
            $seq->display_id("$id-U");

            if ( not defined $targeted_trap ) {
                ###2nd D recombineer - downstream loxP insertion
                my ( $d5, $d3 ) = map {
                    my $p = $_;
                    (   grep {
                            scalar( grep {/\b$p\b/} $_->get_tagset_values('note') )
                          } grep {
                            $_->primary_tag eq 'rcmb_primer'
                          } $seq->get_SeqFeatures
                      )[0]
                } qw(D5 D3);
                my $pl2 = TargetedTrap::IVSA::SyntheticConstruct::rich_loxp();
                $seq = recombineer(
                    $seq, $pl2,
                    $d5,

  #revcom_as_string($self->default_recombination_oligo_suffix('D5')), #alternative to location below
                    Bio::Location::Simple->new( -start => 1, -end => 20, strand => -1 ),
                    $d3,

  #revcom_as_string($self->default_recombination_oligo_suffix('D3')), #alternative to location below
                    Bio::Location::Simple->new(
                        -start => ( $pl2->length - 19 ),
                        -end   => $pl2->length,
                        strand => +1
                    ),
                );
                $seq->display_id("$id-UD");
            }
        }
        if ( $stage eq 'vector' ) {
            ###Gap recovery G recombineer
            my ( $g5, $g3 ) = map {
                my $p = $_;
                (   grep {
                        scalar( grep {/\b$p\b/} $_->get_tagset_values('note') )
                      } grep {
                        $_->primary_tag eq 'rcmb_primer'
                      } $seq->get_SeqFeatures
                  )[0]
            } qw(G5 G3);
            if ( $bb and not( $bb =~ /^L3L4|L4L3/ or $bb eq 'default' ) ) {
                my $pl3 = TargetedTrap::IVSA::SyntheticConstruct::get_backbone_seq($bb);
                $seq = recombineer(
                    $pl3,                                                                $seq,
                    revcom_as_string( $self->default_recombination_oligo_suffix('G5') ), $g5,
                    revcom_as_string( $self->default_recombination_oligo_suffix('G3') ), $g3,
                );
            } else {    #default gap recovery
                my $pl3a = TargetedTrap::IVSA::SyntheticConstruct::rich_r3r4_asis1_U();
                my $pl3b = Bio::PrimarySeq->new( -alphabet => 'dna', -seq => 'N' x 100 )
                  ;     #we should never see this - recombineered away....
                my $pl3c = TargetedTrap::IVSA::SyntheticConstruct::rich_r3r4_asis1_D();
                my $pl3 = Bio::Seq->new( -alphabet => 'dna', is_circular => 1 );
                Bio::SeqUtils->cat( $pl3, $pl3a, $pl3b, $pl3c );
                $seq = recombineer(
                    $pl3, $seq,

                    #revcom_as_string($self->default_recombination_oligo_suffix('G5')),
                    Bio::Location::Simple->new(
                        -start => ( $pl3a->length - 19 ),
                        -end   => $pl3a->length,
                        strand => +1
                    ),
                    $g5,

                    #revcom_as_string($self->default_recombination_oligo_suffix('G3')),
                    Bio::Location::Simple->new(
                        -start => ( $pl3a->length + 101 ),
                        -end   => ( $pl3a->length + 120 ),
                        strand => -1
                    ),
                    $g3,
                );
            }
            $seq->display_id("$id-UDG");

#optional extra recombineer - typically to put toxin in backbone - primers not normally design specific
#should go here really instead of bunging different sequence in at gap recombineer

            #Any Gateway steps required here....
            if ( $bb =~ /^L3L4|L4L3/ ) {
                $seq
                  = gateway( $seq, TargetedTrap::IVSA::SyntheticConstruct::get_backbone_seq($bb) );
                $seq->display_id("$id-UD-bbgw");
            }
        }    #end of vector only stage
             #more (cassette) Gateway stuff now....
        if ( $cs =~ /^L1L2|L2L1/ ) {
            $seq = gateway( $seq,
                TargetedTrap::IVSA::SyntheticConstruct::get_cassette_vector_seq($cs) );
            $seq->display_id("$id-UD-cgw");
        }

        #Ensure seq comes out conventional way round....
        my ($f_tmp) = grep {
            scalar grep { $_ eq 'G5' } $_->get_tagset_values('note')
          } grep {
            $_->primary_tag eq 'rcmb_primer'
          } $seq->all_SeqFeatures;
        $seq = Bio::SeqUtils->revcom_with_features($seq) if ( $f_tmp and ( $f_tmp->strand == 1 ) );

        #annotate and label....
        if ($cs) {
            $id =~ s/_wt$/_$cs/;
            $id =~ s/^allele_/vector_/ if ( $stage eq 'vector' );
            $seq->annotation->add_Annotation( 'comment',
                Bio::Annotation::Comment->new( '-text' => "cassette : " . $cs ) );
        } else {
            $id =~ s/_wt$//;
            $id =~ s/^allele_/interm_/ if ( $stage eq 'vector' );
        }
        if ($bb) {
            $id .= "_$bb";
            $seq->annotation->add_Annotation( 'comment',
                Bio::Annotation::Comment->new( '-text' => "backbone : " . $bb ) );
        }
        $seq->display_id($id);

    }
    $self->_add_design_annotation_to_seq($seq);
    return $seq;
}

sub vector_seq_old {
    my ( $self, $cs, $bb ) = @_;
    my ( $wt, $Us, $Ue, $Ts, $Te, $Ds, $De ) = $self->_wildtype_seq_without_seq_annotation;
    my $U = Bio::SeqUtils->trunc_with_features( $wt, $Us, $Ue );
    $U->add_SeqFeature(
        new Bio::SeqFeature::Generic(
            -start        => 1,
            -end          => $U->length,
            -strand       => 1,
            -primary      => 'genomic',
            -source_tag   => 'synthetic_construct',
            -display_name => '5_arm',
            -tag          => { note => '5 arm' }
        )
    );
    my $T;
    if ( not( $self->is_deletion or $self->is_insertion ) ) {
        $T = Bio::SeqUtils->trunc_with_features( $wt, $Ts, $Te );
        $T->add_SeqFeature(
            new Bio::SeqFeature::Generic(
                -start        => 1,
                -end          => $T->length,
                -strand       => 1,
                -primary      => 'genomic',
                -source_tag   => 'synthetic_construct',
                -display_name => 'target_region',
                -tag          => { note => 'target region' }
            )
        );
    }
    my $D = Bio::SeqUtils->trunc_with_features( $wt, $Ds, $De );
    $D->add_SeqFeature(
        new Bio::SeqFeature::Generic(
            -start        => 1,
            -end          => $D->length,
            -strand       => 1,
            -primary      => 'genomic',
            -source_tag   => 'synthetic_construct',
            -display_name => '3_arm',
            -tag          => { note => '3 arm' }
        )
    );
    my $sc = new TargetedTrap::IVSA::SyntheticConstruct;
    $sc->gateway_backbone_tag($bb) if $bb;
    my $a;
    my $id = $wt->display_id;
    if ($cs) {
        $sc->synth_stage('gateway');
        $id =~ s/_wt$/_$cs/;
        $id =~ s/^allele_/vector_/;
        $sc->gateway_cassette_tag($cs);
        $a = $sc->create_final_v1( $U, $T, $D );
        $a->annotation->add_Annotation( 'comment',
            Bio::Annotation::Comment->new( '-text' => "cassette : " . $cs ) );
    } else {
        $sc->synth_stage('intermediate');
        $id =~ s/_wt$//;
        $id =~ s/^allele_/interm_/;
        $a = $sc->create_intermediate_v1( $U, $T, $D );
    }
    if ($bb) {
        $id .= "_$bb";
        $a->annotation->add_Annotation( 'comment',
            Bio::Annotation::Comment->new( '-text' => "backbone : " . $bb ) );
    }
    $a->display_id($id);
    $self->_add_design_annotation_to_seq($a);
    return $a;
}

sub repair_offset_sequences {
    my $self       = shift;
    my $strand     = $self->locus->chr_strand;    # 1 or -1
    my $feature_rs = $self->validated_features;

    my $g5 = $feature_rs->search( 'feature_type.description' => 'G5', { join => q(feature_type) } )
      ->first;
    my $u5 = $feature_rs->search( 'feature_type.description' => 'U5', { join => q(feature_type) } )
      ->first;
    my $u3 = $feature_rs->search( 'feature_type.description' => 'U3', { join => q(feature_type) } )
      ->first;
    my $d5 = $feature_rs->search( 'feature_type.description' => 'D5', { join => q(feature_type) } )
      ->first;
    my $d3 = $feature_rs->search( 'feature_type.description' => 'D3', { join => q(feature_type) } )
      ->first;
    my $g3 = $feature_rs->search( 'feature_type.description' => 'G3', { join => q(feature_type) } )
      ->first;

    my $u5_15
      = $feature_rs->search( 'feature_type.description' => 'U5_15', { join => q(feature_type) } )
      ->first;
    my $g5_u5
      = $feature_rs->search( 'feature_type.description' => 'G5_U5', { join => q(feature_type) } )
      ->first;
    my $u5_d3
      = $feature_rs->search( 'feature_type.description' => 'U5_D3', { join => q(feature_type) } )
      ->first;
    my $u3_d5
      = $feature_rs->search( 'feature_type.description' => 'U3_D5', { join => q(feature_type) } )
      ->first;
    my $d3_g3
      = $feature_rs->search( 'feature_type.description' => 'D3_G3', { join => q(feature_type) } )
      ->first;
    my $d3_15
      = $feature_rs->search( 'feature_type.description' => 'D3_15', { join => q(feature_type) } )
      ->first;

    if ( $strand == 1 ) {

        $self->left_fix( $g5, $g5_u5 );
        $self->right_fix( $u5, $g5_u5 );
        $self->right_fix( $u5, $u5_15 );

        $self->left_fix( $u5, $u5_d3 );
        $self->right_fix( $d3, $u5_d3 );
        $self->left_fix( $u3, $u3_d5 );
        $self->right_fix( $d5, $u3_d5 );

        $self->left_fix( $d3, $d3_15 );
        $self->left_fix( $d3, $d3_g3 );
        $self->right_fix( $g3, $d3_g3 );
        my $e_15 = $feature_rs->search(
            'feature_type.description' => '15_E_15',
            { join => q(feature_type) }
        )->first;

        if ($e_15) {
            print "FIXING 15_E_15 coords\n";
            my $offset_of_U5_into_e_15 = index( $e_15->get_seq_str, $u5->get_seq_str );
            print "existing feature start: " . $e_15->feature_start . "\n";
            my $implicit_feature_start = $u5->feature_start - $offset_of_U5_into_e_15;
            if ( $e_15->feature_start != $implicit_feature_start ) {
                print "implicit feature start: " . $implicit_feature_start . "\n";
                print "implicit feature end : "
                  . ( $implicit_feature_start + length( $e_15->get_seq_str ) - 1 ) . "\n";
                $e_15->update(
                    {   feature_start => $implicit_feature_start,
                        feature_end   => $implicit_feature_start + length( $e_15->get_seq_str ) - 1
                    }
                );
            }
        }

    } else {

        $self->right_fix( $g5, $g5_u5 );
        $self->left_fix( $u5, $g5_u5 );
        $self->left_fix( $u5, $u5_15 );

        $self->right_fix( $u5, $u5_d3 );
        $self->left_fix( $d3, $u5_d3 );
        $self->left_fix( $d5, $u3_d5 );
        $self->right_fix( $u3, $u3_d5 );

        $self->right_fix( $d3, $d3_15 );
        $self->right_fix( $d3, $d3_g3 );
        $self->left_fix( $g3, $d3_g3 );
        my $e_15 = $feature_rs->search(
            'feature_type.description' => '15_E_15',
            { join => q(feature_type) }
        )->first;
        if ($e_15) {
            print "FIXING 15_E_15 coords\n";
            my $offset_of_U5_into_e_15 = index( $e_15->get_seq_str, $u5->get_seq_str );
            print "U5 seq: " . $u5->get_seq_str . "\n";
            print "start of e15 seq: " . substr( $e_15->get_seq_str, 0, 100 ) . "\n";
            print "size of e15: " . length( $e_15->get_seq_str ) . "\n";
            print "offset of U5 into e15: $offset_of_U5_into_e_15\n";
            print "existing feature start: " . $e_15->feature_start . "\n";
            my $implicit_feature_start = $u5->feature_start - $offset_of_U5_into_e_15;

            if ( $e_15->feature_start != $implicit_feature_start ) {
                print "implicit feature start: " . $implicit_feature_start . "\n";
                print "implicit feature end : "
                  . ( $implicit_feature_start + length( $e_15->get_seq_str ) - 1 ) . "\n";
                $e_15->update(
                    {   feature_start => $implicit_feature_start,
                        feature_end   => $implicit_feature_start + length( $e_15->get_seq_str ) - 1
                    }
                );
            }
        }
    }

}

sub left_fix {
    my ( $self, $primer, $big_seq ) = @_;

    # Get out unless both the primer and the big seq are present
    return unless ( $primer && $big_seq );
    my $primer_name  = $primer->feature_type->description;
    my $big_seq_name = $big_seq->feature_type->description;

    my $design_id     = $self->design_id;
    my $primer_length = length( $primer->get_seq_str );
    my $big_seq_data
      = $big_seq->feature_data->find( { q(feature_data_type.description) => q(sequence) },
        { join => q(feature_data_type) } );
    my $big_seq_length = length( $big_seq->get_seq_str );

    my $update_coords = 1;
    if ( $primer->get_seq_str eq substr( $big_seq->get_seq_str, 0, $primer_length ) ) {

        # G5    ABCD
        # G5_U5 ABCD
        print "LEFT: $design_id: $primer_name - $big_seq_name match\n";
    } elsif ( $primer->get_seq_str eq substr( $big_seq->get_seq_str, 1, $primer_length ) ) {

        # G5     ABCD
        # G5_U5 XABCD  (OLD)
        # G5_U5  ABCD  (NEW)
        print
          "LEFT: $design_id: $big_seq_name extends one left from $primer_name - trimming $big_seq_name from left\n";
        $big_seq_data->update( { data_item => substr( $big_seq_data->data_item, 1 ) } );
        $big_seq_length--;
        $update_coords = 1;
    } elsif (
        substr( $primer->get_seq_str, 1 ) eq substr( $big_seq->get_seq_str, 0, $primer_length - 1 )
      )
    {

        # G5     ABCD
        # G5_U5   BCD (OLD)
        # G5_U5  ABCD (NEW)
        my $append_char = substr( $primer->get_seq_str, 0, 1 );
        print
          "LEFT: $design_id: $primer_name extends one left from $big_seq_name - prepend $append_char onto $big_seq_name\n";
        $big_seq_data->update( { data_item => ${append_char} . $big_seq_data->data_item } );
        $big_seq_length++;
        $update_coords = 1;
    } else {
        die "LEFT: $design_id: unexpected $primer_name $big_seq_name relation\n";
    }

    if ($update_coords) {
        $big_seq->update(
            {   chr_id        => $big_seq->chr_id,
                feature_start => $primer->feature_start,
                feature_end   => $primer->feature_start + $big_seq_length - 1
            }
        );
        print "LEFT: updated $big_seq_name (via $primer_name) to: "
          . $big_seq->feature_start . ":"
          . $big_seq->feature_end . "\n";
    }
}

sub right_fix {
    my ( $self, $primer, $big_seq ) = @_;

    # Get out unless both the primer and the big seq are present
    return unless ( $primer && $big_seq );
    my $primer_name  = $primer->feature_type->description;
    my $big_seq_name = $big_seq->feature_type->description;

    my $design_id     = $self->design_id;
    my $primer_length = length( $primer->get_seq_str );
    my $big_seq_data
      = $big_seq->feature_data->find( { q(feature_data_type.description) => q(sequence) },
        { join => q(feature_data_type) } );
    my $big_seq_length = length( $big_seq->get_seq_str );

    my $update_coords = 1;
    if ( $primer->get_seq_str eq substr( $big_seq->get_seq_str, -1 * $primer_length ) ) {

        # G5    ABCD
        # G5_U5 ABCD
        print "RIGHT: $design_id: $primer_name - $big_seq_name match\n";

    } elsif ( $primer->get_seq_str eq
        substr( $big_seq->get_seq_str, -1 * ( $primer_length + 1 ), $primer_length ) )
    {

        # U5     ABCD
        # G5_U5  ABCDX  (OLD)
        # G5_U5  ABCD  (NEW)
        print
          "RIGHT: $design_id: $big_seq_name extends one right from $primer_name - trimming $big_seq_name from right\n";
        $big_seq_data->update(
            { data_item => substr( $big_seq_data->data_item, 0, $big_seq_length - 1 ) } );
        $big_seq_length--;
        $update_coords = 1;

    } elsif (
        substr( $primer->get_seq_str, 0, $primer_length - 1 ) eq
        substr( $big_seq->get_seq_str, -1 * ( $primer_length - 1 ) ) )
    {

        # U5     ABCD
        # G5_U5  ABC (OLD)
        # G5_U5  ABCD (NEW)
        my $append_char = substr( $primer->get_seq_str, -1 );
        print
          "RIGHT: $design_id: $primer_name extends one right from $big_seq_name - appending $append_char onto $big_seq_name\n";
        $big_seq_data->update( { data_item => $big_seq_data->data_item . $append_char } );
        $big_seq_length++;
        $update_coords = 1;

    } else {
        die "RIGHT: $design_id: unexpected $primer_name $big_seq_name relation\n";
    }

    if ($update_coords) {
        $big_seq->update(
            {   chr_id        => $big_seq->chr_id,
                feature_start => $primer->feature_end - $big_seq_length + 1,
                feature_end   => $primer->feature_end
            }
        );
        print "RIGHT: updated $big_seq_name (via $primer_name) to: "
          . $big_seq->feature_start . ":"
          . $big_seq->feature_end . "\n";
    }
}

sub check_design {
    my ( $self, $assembly, $build_id ) = @_;
    require HTGT::Utils::DesignCheckRunner;

    if( !$assembly || !$build_id ) {
        die( 'Must specify both assembly and build when running check_design' );
    }

    my $design_checker = HTGT::Utils::DesignCheckRunner->new(
        schema             => $self->result_source->schema,
        design             => $self,
        assembly_id        => $assembly,
        build_id           => $build_id,
        update_annotations => 1,
    );

    $design_checker->check_design;
}

return 1;

