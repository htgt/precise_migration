### TargetedTrap::IVSA::Design
#
# Copyright 2005 Genome Research Limited (GRL)
#
# Was Maintained by Lucy Stebbings (las@sanger.ac.uk) 
# Author Lucy Stebbings (las@sanger.ac.uk) 
# Semi destroyed by dj3....
=head1 NAME


=head1 SYNOPSIS

=head1 DESCRIPTION

Object to encapsulate Design information pulled from eucomm_vector, Ensembl, Vega, TRAP
and to manage object relationships within the vector QC system.

=head1 CONTACT

  Contact Jessica Severin on implemetation/design detail: jessica@sanger.ac.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

#three global variables (in a true OO language these would be class private variables)
#keys are a composite of the database and the design_instance_id 
my $__ivsa_design_global_di_id_cache = {};
my $__ivsa_design_global_should_cache = 0;

package TargetedTrap::IVSA::Design;

use strict;
use Bio::Seq;
use Bio::SeqIO;
use Data::Dumper;

use DBD::Oracle qw(:ora_types);

use TargetedTrap::IVSA::QCTest;
use TargetedTrap::IVSA::GenomicRegion;

use TargetedTrap::DBObject;
our @ISA = qw(TargetedTrap::DBObject);


#################################################
# Class methods
#################################################
sub set_cache_behaviour {
  my $class = shift;
  my $mode = shift;
  
  $__ivsa_design_global_should_cache = $mode;
  
  if(defined($mode) and ($mode eq '0')) {
    #if turning off caching, then flush the caches
    $__ivsa_design_global_di_id_cache = {};
  }
}


#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'design_id'} = '';
  $self->{'plate'} = '';
  $self->{'well_loc'} = '';
  $self->{'gene_name'} = '';
  $self->{'exon_name'} = '';
  $self->{'design_name'} = '';
  $self->{'design_type'} = '';
  $self->{'phase'} = '';
  $self->{'recombineering_oligos'} = {};

  $self->{'ensembl_gene'} = undef;
  $self->{'genomic_region_bioseq'} = undef;
  
  $self->{'genomic_region_vector_id'} = undef;
  $self->{'genomic_region_vector_construct_id'} = undef;

  return $self;
}

sub design_id {
  my $self = shift;
  $self->{'design_id'} = shift if @_;
  return $self->{'design_id'};
}
sub design_inst_id {
  my $self = shift;
  return $self->primary_id;
}

sub plate {
  my $self = shift;
  $self->{'plate'} = shift if @_;
  $self->{'plate'} = '' unless defined($self->{'plate'});
  return $self->{'plate'};
}
sub well {
  my $self = shift;
  $self->{'well_loc'} = uc(shift) if @_;
  $self->{'well_loc'} = '' unless defined($self->{'well_loc'});
  return $self->{'well_loc'};
}
sub well_short {
  my $self = shift;
  if($self->{'well_loc'} =~ /(\w)(\d+)/) {
    my $wellname = $1; 
    my $wellnum = $2+0;
    return uc($wellname . $wellnum);
  }
  return $self->{'well_loc'};
}

sub gene_name {
  my $self = shift;
  $self->{'gene_name'} = shift if @_;
  return $self->{'gene_name'};
}
sub exon_name {
  my $self = shift;
  $self->{'exon_name'} = shift if @_;
  return $self->{'exon_name'};
}
sub design_name {
  my $self = shift;
  $self->{'design_name'} = shift if @_;
  return $self->{'design_name'};
}
sub design_type {
  my $self = shift;
  $self->{'design_type'} = shift if @_;
  return $self->{'design_type'};
}
sub is_deletion {
  my $self = shift;
  my $dt = $self->design_type;
  return ($dt and $dt =~ /^del/i);
}
sub is_insertion{
  my $self = shift;
  my $dt = $self->design_type;
  return ($dt and $dt =~ /^ins/i);
}
sub phase {
  my $self = shift;
  $self->{'phase'} = shift if @_;
  return $self->{'phase'};
}
sub sp {
  my $self = shift;
  $self->{'sp'} = shift if @_;
  unless (defined $self->{'sp'}) { $self->fetch_sp_tm_by_design_id(); }
  return $self->{'sp'};
}
sub tm {
  my $self = shift;
  $self->{'tm'} = shift if @_;
  unless (defined $self->{'tm'}) { $self->fetch_sp_tm_by_design_id(); }
  return $self->{'tm'};
}

sub design_tag {
  #unique string identify this design
  my $self = shift;
  print STDERR "making tag with components: ".$self->id."--".$self->plate."--".$self->well."--".$self->exon_name."\n";
  my $str = sprintf("%s_%s_%s_%s",
              $self->id,
              $self->plate, 
              $self->well,
              $self->exon_name);
  return $str;
}


####################################################
# information pulled from Ensembl / GenomicRegion
####################################################

sub five_arm {
  my $self = shift;
  $self->{'arm5_region'} = shift if @_;
  return $self->{'arm5_region'};
}
sub three_arm {
  my $self = shift;
  $self->{'arm3_region'} = shift if @_;
  return $self->{'arm3_region'};
}
sub target_region {
  my $self = shift;
  $self->{'target_region'} = shift if @_;
  return $self->{'target_region'};
}


####################################################
# information pulled from Ensembl / GenomicRegion
####################################################

sub ensembl_gene {
  my $self = shift;
  $self->{'ensembl_gene'} = shift if @_;
  return $self->{'ensembl_gene'};
}

sub genomic_region {
  my ($self, $region) = @_;
  if($region) {
    print STDERR ("passing an undef as a parameter\n") unless($region);
    $self->{'genomic_region'} = $region;
    $region->design($self);
  }
  return $self->{'genomic_region'};
}

sub exon_bioseq {
  my $self = shift;
  $self->{'exon_bioseq'} = shift if @_;
  return $self->{'exon_bioseq'};
}

sub location_info {
  my $self = shift;
  my $str = '';
  if($self->genomic_region) {
    $str = $self->genomic_region->chrom .':'.
           $self->genomic_region->chrom_start .':'.
           $self->genomic_region->chrom_end .':'.
           $self->genomic_region->strand;
  }
  return $str;
}

sub vector_id {
  my $self = shift;
  $self->{'genomic_region_vector_id'} = shift if @_;
  return $self->{'genomic_region_vector_id'};
}
sub vector_construct_id {
  my $self = shift;
  $self->{'genomic_region_vector_construct_id'} = shift if @_;
  return $self->{'genomic_region_vector_construct_id'};
}

#convenience methods
sub chromosome {
  my $self = shift;
  if($self->genomic_region) { return $self->genomic_region->chrom; }
  else { return ''; }
}
sub strand {
  my $self = shift;
  if($self->genomic_region) { return $self->genomic_region->strand; }
  else { return ''; }
}

#############################################

sub display_info {
  my $self = shift;

  printf("Design(db %5s ) %s : %s plate_%s %s (%d) : %s\n", 
    $self->id,
    $self->design_name, 
    $self->design_type, 
    $self->plate, 
    $self->well, 
    $self->phase, 
    $self->exon_name
    );
}

sub description {
  my $self = shift;
  my $str = sprintf("Design[%s](plate_%s %s %s %s %s %s -- %s)", 
          $self->id,
          $self->plate,
          $self->well, 
          $self->design_name, 
          $self->design_type, 
          $self->gene_name, 
          $self->exon_name,
          $self->location_info
          );
  return $str;
}


#################################################
#
# DBObject override methods
#
#################################################

##### DBObject instance override methods #####

sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbh = shift;

  if($__ivsa_design_global_should_cache != 0) {
    my $design = $__ivsa_design_global_di_id_cache->{$self->database . $rowHash->{'DESIGN_INSTANCE_ID'}};
    #replace $self with the cached version
    return $design if(defined($design));
  }
  
  $self->primary_id($rowHash->{'DESIGN_INSTANCE_ID'});
  $self->design_id($rowHash->{'DESIGN_ID'});
  $self->plate($rowHash->{'PLATE'});
  $self->well($rowHash->{'WELL'});
  $self->gene_name($rowHash->{'GENE_NAME'});
  $self->exon_name($rowHash->{'EXON_ID'});
  $self->design_name($rowHash->{'DESIGN_NAME'});
  $self->design_type($rowHash->{'DESIGN_TYPE'});
  $self->phase($rowHash->{'PHASE'});

  $self->fetch_genomic_info_from_design($self->database);
  
  if($__ivsa_design_global_should_cache != 0) {
    $__ivsa_design_global_di_id_cache->{$self->database() . $self->primary_id} = $self;
  }
      
  return $self;
}

sub load_genomic_arms {
  my ($self,$stage) = @_; 
  #if the stage is 'late', then we need the synthetic allele, so load the long design arms

  if($stage){print STDERR "Loading design genomic arms for stage: $stage\n";}
  
  my $sql;
  if($stage && ($stage eq 'allele')){
    $sql = 
      "select chr_id, feature_start, feature_end,
       ft.description as feature_type,
       fd.data_item as feature_seq
            FROM feature f
            join feature_type_dict ft on(f.feature_type_id = ft.feature_type_id) 
            join feature_data fd on(f.feature_id=fd.feature_id)
            join feature_data_type_dict fdt on(fd.feature_data_type_id=fdt.feature_data_type_id)
            WHERE fdt.description='sequence'
            and ft.description in ('U5_15', 'U3_D5', 'D3_15')
            and design_id=?";
  }else{
    $sql = 
      "select chr_id, feature_start, feature_end,
       ft.description as feature_type,
       fd.data_item as feature_seq
            FROM feature f
            join feature_type_dict ft on(f.feature_type_id = ft.feature_type_id) 
            join feature_data fd on(f.feature_id=fd.feature_id)
            join feature_data_type_dict fdt on(fd.feature_data_type_id=fdt.feature_data_type_id)
            WHERE fdt.description='sequence'
            and ft.description in ('G5_U5', 'U3_D5', 'D3_G3')
            and design_id=?";
  }

  my $dbh = $self->database->get_connection;
  my $sth = $dbh->prepare($sql, { ora_auto_lob => 0 });
  $sth->execute($self->design_id);
  while(my $row_hash = $sth->fetchrow_hashref) {
    my $arm_name = $row_hash->{'FEATURE_TYPE'};
    
    # read SEQUENCE CLOB
    my $lob_locator = $row_hash->{'FEATURE_SEQ'}; 
    my $lob_length = $dbh->ora_lob_length($lob_locator);
    my $seq_data = $dbh->ora_lob_read($lob_locator, 1, $lob_length);
    my $bioseq = Bio::Seq->new(-id=>$arm_name, -seq=>$seq_data);
    
    my $region = new TargetedTrap::IVSA::GenomicRegion;
    $region->name($arm_name);
    $region->chrom($row_hash->{'CHR_ID'});
    $region->chrom_start($row_hash->{'FEATURE_START'});
    $region->chrom_end($row_hash->{'FEATURE_END'});
    $region->strand($self->genomic_region->strand);
    
    $region->sequence($bioseq);
    $region->load_exon_features($self->database);

    if($self->genomic_region->strand == -1) {
      $region = $region->revcom;
    }

    if(($arm_name eq 'G5_U5')||($arm_name eq 'U5_15')) { $self->five_arm($region); }
    if($arm_name eq 'U3_D5') { $self->target_region($region); }
    if(($arm_name eq 'D3_G3')||($arm_name eq 'D3_15')) { $self->three_arm($region); }
  }
  
  unless($self->five_arm and $self->target_region and $self->three_arm) {
    print STDERR ("unable to load all genomic arms from database for\n". $self->description ."\n");
  }
  $sth->finish;

  # get the sp/tm status of the design from the gene_info table
  $self->fetch_sp_tm_by_design_id();
  return $self;
}

sub fetch_sp_tm_by_design_id {
  my $self = shift;

  my $sql = " SELECT gi.sp, 
                    gi.tm
             FROM design d,
                  mig.gnm_exon e,
                  --mig.gnm_transcript_2_exon et,
                  mig.gnm_transcript t,
                  mig.gnm_gene_build_gene gbg,
                  mig.gnm_gene_2_gene_build_gene g2gbg,
                  mig.gnm_gene g,
                  gene_info gi
             WHERE d.design_id = ?
             AND d.start_exon_id = e.ID 
             --AND e.id = et.exon_id 
             --AND et.transcript_id = t.id 
             AND e.transcript_id = t.id 
             AND t.build_gene_id = gbg.ID 
             AND g2gbg.gene_build_gene_id = gbg.ID 
             AND g2gbg.gene_id = g.id 
             AND gi.gene_id = g.id ";
 
  my $dbh = $self->database->get_connection;
  my $sth = $dbh->prepare($sql);
  $sth->execute($self->design_id);  
  my $row_hash = $sth->fetchrow_hashref;
  if($row_hash) {
      if ($row_hash->{'SP'}) { $self->sp($row_hash->{'SP'}); }
      else { $self->sp(0); }
      if ($row_hash->{'TM'}) { $self->tm($row_hash->{'TM'}); }
      else { $self->tm(0); }
  }
  
  $sth->finish;
  return $self;
}

sub load_recombineering_oligos {
  my $self = shift;  

  my $sql = 
      "select chr_id, feature_start, feature_end,
             ft.description as feature_type,
             fd.data_item as feature_seq
                  FROM feature f
                  join feature_type_dict ft on(f.feature_type_id = ft.feature_type_id) 
                  join feature_data fd on(f.feature_id=fd.feature_id)
                  join feature_data_type_dict fdt on(fd.feature_data_type_id=fdt.feature_data_type_id)
                  WHERE fdt.description='sequence'
                  and ft.description in ('G5', 'U5', 'U3', 'D5', 'D3', 'G3')
                  and design_id=?
                  AND f.FEATURE_ID IN (
                    SELECT f.FEATURE_ID
                      FROM eucomm_vector.design d,
                           eucomm_vector.feature f,
                           eucomm_vector.feature_data fd
                     WHERE d.design_id = f.design_id
                       AND fd.FEATURE_ID = f.FEATURE_ID
                       AND fd.feature_data_type_id = 3)";
  my $dbh = $self->database->get_connection;
  my $sth = $dbh->prepare($sql, { ora_auto_lob => 0 });
  $sth->execute($self->design_id);  
  while(my $row_hash = $sth->fetchrow_hashref) {
    my $oligo_name = $row_hash->{'FEATURE_TYPE'};
    
    # read SEQUENCE CLOB
    my $lob_locator = $row_hash->{'FEATURE_SEQ'}; 
    my $lob_length = $dbh->ora_lob_length($lob_locator);
    my $seq_data = $dbh->ora_lob_read($lob_locator, 1, $lob_length);
    my $bioseq = Bio::Seq->new(-id=>$oligo_name, -seq=>$seq_data);

    my $oligo = new TargetedTrap::IVSA::Oligo;
    $oligo->sequence($bioseq);
    $oligo->name($oligo_name);
    $oligo->start($row_hash->{'feature_start'});
    $oligo->end($row_hash->{'feature_end'});
    $self->{'recombineering_oligos'}->{$oligo_name} = $oligo;
  }

  $sth->finish;
  return $self;
}


sub fetch_genomic_region {
  my $self = shift;
  my $qc_db = shift;
  
  return undef unless($qc_db);
  my $region = TargetedTrap::IVSA::GenomicRegion->fetch_by_design_id($qc_db, $self->design_id);
  $self->genomic_region($region);
  return $region
}


sub fetch_genomic_region_from_trap {
  my $self = shift;  
  my $trap_db = shift;

  my $genomic_region = new TargetedTrap::IVSA::GenomicRegion;
  
  my $sql = qq/
     SELECT id_vector,
            id_vector_construct,
            v.name, 
            v.description, 
            v.info_location, 
            vc.consensus_seq
     FROM vector v 
     JOIN vector_construct vc using(id_vector)  
     WHERE design_instance_id=?
     AND id_vector_type=10/;

  my $dbh = $trap_db->get_connection;
  my $sth = $dbh->prepare($sql, { ora_auto_lob => 0 });
  $sth->execute($self->design_inst_id);  
  my $row_hash = $sth->fetchrow_hashref;
  if($row_hash) {
    $self->gene_name($row_hash->{'DESCRIPTION'});

    $self->vector_id($row_hash->{'ID_VECTOR'});
    $self->vector_construct_id($row_hash->{'ID_VECTOR_CONSTRUCT'});

    my $chr_info = $row_hash->{'INFO_LOCATION'};
    my ($chr, $start, $end, $strand) = split /:/, $chr_info;    
    $genomic_region->chrom($chr);
    $genomic_region->chrom_start($start);
    $genomic_region->chrom_end($end);
    $genomic_region->strand($strand);
    $genomic_region->name($self->design_name ."_". $self->gene_name ."_genomic_region");
    
    # read SEQUENCE CLOB
    my $name = $self->gene_name ."_". $row_hash->{'NAME'} ."_". $row_hash->{'INFO_LOCATION'};
    my $lob_locator = $row_hash->{'CONSENSUS_SEQ'}; 
    my $lob_length = $dbh->ora_lob_length($lob_locator);
    my $seq_data = $dbh->ora_lob_read($lob_locator, 1, $lob_length);
    my $bioseq = Bio::Seq->new(-id=>$name, -seq=>$seq_data);
    $genomic_region->sequence($bioseq);
    
    $self->genomic_region($genomic_region);
  }
  
  $sth->finish;
  return $self;
}


sub fetch_genomic_info_from_design {
  my $self = shift;  
  my $design_db = shift;

  my $genomic_region = new TargetedTrap::IVSA::GenomicRegion;
  
  my $sql = "SELECT L1.CHR_START, 
                    L2.CHR_END,
                    L1.CHR_STRAND, 
                    L1.CHR_NAME
     FROM DESIGN d
     JOIN MIG.GNM_EXON E1 on(d.start_exon_id = e1.id)
     JOIN MIG.GNM_EXON E2 on(d.end_exon_id = e2.id)
     JOIN MIG.GNM_LOCUS L1 on(l1.id = e1.locus_id)
     JOIN MIG.GNM_LOCUS L2 on(l2.id = e2.locus_id)
     WHERE design_id=?";

  my $dbh = $design_db->get_connection;
  my $sth = $dbh->prepare($sql);
  $sth->execute($self->design_id);  
  my $row_hash = $sth->fetchrow_hashref;
  if($row_hash) {
    $genomic_region->chrom($row_hash->{'CHR_NAME'});
    $genomic_region->chrom_start($row_hash->{'CHR_START'} -12000);
    $genomic_region->chrom_end($row_hash->{'CHR_END'} + 12000);
    $genomic_region->strand($row_hash->{'CHR_STRAND'});
    $genomic_region->name($self->design_name ."_". $self->gene_name ."_genomic_region");
        
    $self->genomic_region($genomic_region);
  }
  
  $sth->finish;
  return $self;
}

##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my ($class,$db,$design_instance_id) =  @_;
  
 if($__ivsa_design_global_should_cache != 0) {
    my $design = $__ivsa_design_global_di_id_cache->{$db . $design_instance_id};
    return $design if(defined($design));
  }

  my $sql = "SELECT d.*, 
                di.plate, di.well, di.design_instance_id, 
                gbg.primary_name as GENE_NAME, e.primary_name as EXON_ID, e.phase
             FROM design d
                JOIN design_instance di on(d.design_id = di.design_id)
                JOIN mig.gnm_exon e ON(d.start_exon_id=e.id)
                --JOIN mig.gnm_transcript_2_exon et ON(e.id=et.exon_id)
                --JOIN mig.gnm_transcript t ON(et.transcript_id = t.id)
                JOIN mig.gnm_transcript t ON(e.transcript_id = t.id)
                JOIN mig.gnm_gene_build_gene gbg ON(t.build_gene_id = gbg.id)
             WHERE design_instance_id = ?";
  return $class->fetch_single($db, $sql, $design_instance_id);
}


sub fetch_by_design_id {
  my $class = shift;
  my $db = shift;
  my $design_id = shift;
  
 if($__ivsa_design_global_should_cache != 0) {
    my $design = $__ivsa_design_global_di_id_cache->{$db . $design_id};
    return $design if(defined($design));
  }

  my $sql = "SELECT d.*, 
                '' as PLATE, '' as WELL, null as design_instance_id, 
                gbg.primary_name as GENE_NAME, e.primary_name as EXON_ID, e.phase
             FROM design d
                JOIN mig.gnm_exon e ON(d.start_exon_id=e.id)
                --JOIN mig.gnm_transcript_2_exon et ON(e.id=et.exon_id)
                --JOIN mig.gnm_transcript t ON(et.transcript_id = t.id)
                JOIN mig.gnm_transcript t ON(e.transcript_id = t.id)
                JOIN mig.gnm_gene_build_gene gbg ON(t.build_gene_id = gbg.id)
             WHERE design_id = ?";
  return $class->fetch_single($db, $sql, $design_id);
}


sub fetch_by_plate_well {
  my $class = shift;
  my $db = shift;
  my $plate = shift;
  my $well = uc(shift);
  
  my $sql = "SELECT d.*, 
                di.plate, di.well, di.design_instance_id, 
                gbg.primary_name as GENE_NAME, e.primary_name as EXON_ID, e.phase
             FROM design d
                JOIN design_instance di on(d.design_id = di.design_id)
                JOIN mig.gnm_exon e ON(d.start_exon_id=e.id)
                --JOIN mig.gnm_transcript_2_exon et ON(e.id=et.exon_id)
                --JOIN mig.gnm_transcript t ON(et.transcript_id = t.id)
                JOIN mig.gnm_transcript t ON(e.transcript_id = t.id)
                JOIN mig.gnm_gene_build_gene gbg ON(t.build_gene_id = gbg.id)
             WHERE di.plate=? and di.well=? ";
  return $class->fetch_single($db, $sql, $plate, $well);
}

sub fetch_all_by_plate {
  my $class = shift;
  my $db = shift;
  my $plate = shift;
  
  my $sql = "SELECT d.*, 
                di.plate, di.well, di.design_instance_id, 
                gbg.primary_name as GENE_NAME, e.primary_name as EXON_ID, e.phase
             FROM design d
                JOIN design_instance di on(d.design_id = di.design_id)
                JOIN mig.gnm_exon e ON(d.start_exon_id=e.id)
                --JOIN mig.gnm_transcript_2_exon et ON(e.id=et.exon_id)
                --JOIN mig.gnm_transcript t ON(et.transcript_id = t.id)
                JOIN mig.gnm_transcript t ON(e.transcript_id = t.id)
                JOIN mig.gnm_gene_build_gene gbg ON(t.build_gene_id = gbg.id)
             WHERE di.plate=? 
             ORDER BY di.well";
  return $class->fetch_multiple($db, $sql, $plate);
}


sub fetch_all_by_name_search {
  my $class = shift;
  my $db = shift;
  my $name = shift;

  my $sql = "SELECT d.*, di.plate, di.well, di.design_instance_id, 
                    gbg.primary_name as GENE_NAME, e.primary_name as EXON_ID, e.phase
             FROM design d
             JOIN mig.gnm_exon e ON(d.start_exon_id=e.id)
             --JOIN mig.gnm_transcript_2_exon et ON(e.id=et.exon_id)
             --JOIN mig.gnm_transcript t ON(et.transcript_id = t.id)
             JOIN mig.gnm_transcript t ON(e.transcript_id = t.id)
             JOIN mig.gnm_gene_build_gene gbg ON(t.build_gene_id = gbg.id)
             LEFT JOIN design_instance di on(d.design_id = di.design_id)
             WHERE d.start_exon_id IN(  
                SELECT DISTINCT e.id FROM mig.gnm_gene_build_gene gbg, mig.gnm_transcript t, --mig.gnm_transcript_2_exon et, 
		                mig.gnm_exon e, mig.gnm_gene_build_gene_name gbgn 
                WHERE (gbgn.name_uc LIKE ?) AND gbg.id = gbgn.gene_build_gene_id 
                  AND gbg.id = t.build_gene_id 
                  AND t.id = e.transcript_id 
                  --AND t.id = et.transcript_id 
                  --AND e.id = et.exon_id 
                UNION 
                SELECT DISTINCT e.id FROM mig.gnm_gene_build_gene gbg, mig.gnm_transcript t, --mig.gnm_transcript_2_exon et, 
		                mig.gnm_exon e, mig.gnm_transcript_name tn 
                WHERE (tn.name_uc LIKE ?) AND t.id = tn.transcript_id
                  AND gbg.id = t.build_gene_id 
                  AND t.id = e.transcript_id 
                  --AND t.id = et.transcript_id 
                  --AND e.id = et.exon_id 
                UNION 
                SELECT DISTINCT e.id FROM mig.gnm_gene_build_gene gbg, mig.gnm_transcript t, --mig.gnm_transcript_2_exon et, 
		                mig.gnm_exon e, mig.gnm_exon_name en 
                WHERE (en.name_uc LIKE ?) AND e.id=en.exon_id
                  AND gbg.id = t.build_gene_id 
                  AND t.id = e.transcript_id 
                  --AND t.id = et.transcript_id 
                  --AND e.id = et.exon_id 
                UNION 
                SELECT DISTINCT e.id FROM mig.gnm_gene_build_gene gbg, mig.gnm_transcript t, --mig.gnm_transcript_2_exon et, 
		                          mig.gnm_exon e, mig.gnm_gene g, 
                        mig.GNM_GENE_2_GENE_BUILD_GENE ggg, mig.gnm_gene_name gn 
                WHERE (gn.name_uc LIKE ?) AND g.id = gn.gene_id
                  AND ggg.gene_id = g.id
                  and ggg.gene_BUILD_GENE_ID = gbg.id 
                  AND gbg.id = t.build_gene_id 
                  AND t.id = e.transcript_id 
                  --AND t.id = et.transcript_id 
                  --AND e.id = et.exon_id 
              )"; 
  return $class->fetch_multiple($db, $sql, $name, $name, $name, $name);
}


1;

