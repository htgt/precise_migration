package HTGTDB::GeneTrapWell;

use strict;
use warnings;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('gene_trap_well');

#  Tells DBIx which sequence to use to auto-increment the gene_trap_well_id
__PACKAGE__->sequence('S_GENE_TRAP_WELL');

#__PACKAGE__->add_columns(
#    qw/
#        gene_trap_well_id 
#        gene_trap_well_name
#        five_prime_seq 
#        three_prime_seq
#        five_prime_align_quality
#        three_prime_align_quality
#        five_prime_chr
#        three_prime_chr
#        five_prime_start
#        three_prime_start
#        five_prime_end 
#        three_prime_end
#        five_prime_strand
#        three_prime_strand
#        frt_found
#        frt_lengths
#        frtp_seq 
#        is_paired
#        original_well_name
#        fam_test_result
#    /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "gene_trap_well_id",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "gene_trap_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "five_prime_seq",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "three_prime_seq",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "five_prime_align_quality",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "three_prime_align_quality",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "five_prime_chr",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "three_prime_chr",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "five_prime_start",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "three_prime_start",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "five_prime_end",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "three_prime_end",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "five_prime_strand",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "three_prime_strand",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "frt_found",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "frt_lengths",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "frtp_seq",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "is_paired",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "original_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "fam_test_result",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
);
# End of dbicdump add_columns data


__PACKAGE__->set_primary_key('gene_trap_well_id');

__PACKAGE__->add_unique_constraint( unique_gene_trap_well_name => [ qw/gene_trap_well_name/ ] );

__PACKAGE__->has_many( project_links => 'HTGTDB::ProjectGeneTrapWell', 'gene_trap_well_id' );
__PACKAGE__->many_to_many( projects => 'project_links', 'project');

sub allele_superscript {
    my $self = shift;
    if($self->gene_trap_well_name =~ /(EUC[EFJG])(\d+)(\D\d+)/){
        my $type = $1;
        my $plate_name = $2;
        my $well_name = lc($3);
        if($plate_name =~ /0*(\d+)/){
            $plate_name = $1;
        }
        return "gt(${type}${plate_name}${well_name})Hmgu";
    }
    return 'not defined';
}

sub es_cell_line {
    my $self = shift;
    my $line = 'not specified';
    if( $self->gene_trap_well_name =~ /(EUC[EG])/ ){
        $line = 'E14';
    } elsif ($self->gene_trap_well_name =~ /EUCJ(\d+)\D\d+/) {
        my $plate_name = $1;
        if($plate_name =~ /0*(\d+)/){
            $plate_name = $1;
            if($plate_name < 24 or $plate_name > 136){
                $line = 'JM8.F6';
            }else{
                $line = 'JM8.parental';
            }
        }
    } elsif ($self->gene_trap_well_name =~ /(EUCF)/) {
        $line = 'E14';
    } 
    return $line;    
}

return 1;

=head1 AUTHOR

Dan Klose dk3@sanger.ac.uk

=cut
