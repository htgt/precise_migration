### TargetedTrap::IVSA::GenomicRegion
#
# Copyright 2005 Genome Research Limited (GRL)
#
# Maintained by Jessica Severin (jessica@sanger.ac.uk) 
# Maintained by Lucy Stebbings (las@sanger.ac.uk) 
# Author las
#
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


package TargetedTrap::IVSA::GenomicRegion;

use strict;
use Bio::Seq;
use Bio::SeqIO;
use Data::Dumper;

use DBD::Oracle qw(:ora_types);
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );
#use Bio::EnsEMBL::Gene;
use Bio::SeqFeature::Gene::Exon;

use TargetedTrap::IVSA::QCTest;

use TargetedTrap::IVSA::EngineeredSeq;
our @ISA = qw(TargetedTrap::IVSA::EngineeredSeq);



#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->subclass('genomic_region');
  $self->type('genomic_region');
  
  $self->{'design_id'} = undef;
  $self->{'design'} = undef;
  
  $self->{'chrom'} = undef;
  $self->{'chrom_start'} = undef;
  $self->{'chrom_end'} = undef;
  $self->{'strand'} = undef;
  $self->{'assembly'} = undef;
  
  return $self;
}

####################################################

sub design {
  my $self = shift;
  if(@_) {
    my $design = shift;
    unless(defined($design) && $design->isa('TargetedTrap::IVSA::Design')) {
      throw('design param must be a TargetedTrap::IVSA::Design');
    }
    $self->{'design'} = $design;
  }
  
  #lazy load from database if possible
  if(!defined($self->{'design'}) and 
     defined($self->database) and 
     defined($self->{'design_id'}))
  {
    #lazy load from database if possible
    my $design = TargetedTrap::IVSA::Design->fetch_by_design_id($self->database, $self->{'design_id'});
    if(defined($design)) {
      $self->{'design'} = $design;
      $design->genomic_region($self);
    }
  }

  return $self->{'design'};
}



####################################################
# information pulled from Ensembl / GenomicRegion
####################################################


sub chrom {
  my $self = shift;
  $self->{'chrom'} = shift if @_;
  return $self->{'chrom'};
}
sub chrom_start {
  my $self = shift;
  $self->{'chrom_start'} = shift if @_;
  return $self->{'chrom_start'};
}
sub chrom_end {
  my $self = shift;
  $self->{'chrom_end'} = shift if @_;
  return $self->{'chrom_end'};
}
sub strand {
  my $self = shift;
  $self->{'strand'} = shift if @_;
  return $self->{'strand'};
}
sub assembly {
  my $self = shift;
  $self->{'assembly'} = shift if @_;
  return $self->{'assembly'};
}

sub length {
  my $self = shift;
  return $self->chrom_end - $self->chrom_start;
}

sub location_info {
  my $self = shift;
  my $str = $self->chrom .':'.
            $self->chrom_start .':'.
            $self->chrom_end .':'.
            $self->strand;
  return $str;
}

#############################################

sub description {
  my $self = shift;
  
  my $seq = '';
  if($self->sequence) {
    $seq = substr($self->sequence->seq, 0, 30);
  }
  if(!defined($seq)) { $seq = ''; }
  
  my $str = sprintf("GenomicRegion[%s] %s : (%d) %s", 
          $self->id,
          $self->location_info,
          $self->length,
          $seq
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
  
  $self->SUPER::mapRow($rowHash, $dbh);
    
  $self->primary_id($rowHash->{'ENGINEERED_SEQ_ID'});
  $self->chrom($rowHash->{'CHROM'});
  $self->chrom_start($rowHash->{'CHROM_START'});
  $self->chrom_end($rowHash->{'CHROM_END'});
  $self->strand($rowHash->{'STRAND'});

  #for lazy loading
  $self->{'design_id'} = $rowHash->{'DESIGN_ID'};
      
  return $self;
}


sub load_exon_features {
  my $self = shift;
  my $design_db = shift;
    
  my $sql = "SELECT l.*, e.primary_name as exon_name 
             FROM gnm_locus l 
               join gnm_exon e on(l.id=e.locus_id)
             WHERE assembly_id = ? 
               and chr_start  <= ? 
               and chr_end    >= ? 
               and chr_name    = ?";

  my $dbh = $design_db->get_connection;
  my $sth = $dbh->prepare($sql);
  $sth->execute(8, $self->chrom_end, $self->chrom_start, $self->chrom);
  
  my $exon_hash = {};
  while(my $row_hash = $sth->fetchrow_hashref) {
    my $exon_name = $row_hash->{'EXON_NAME'};
    next if($exon_hash->{$exon_name});
    
    #truncate the exon features so that they fit within the coordinate
    #space of this GenomicRegion (show partial overlapping exons)
    my $tags = { note => $exon_name };
    my $new_start = $row_hash->{'CHR_START'} - $self->chrom_start;
    my $new_end   = $row_hash->{'CHR_END'} - $self->chrom_start;
    if($new_start < 0) { $new_start = 0; $tags->{truncated} = 1; }
    if($new_end >= $self->seq_length) { $new_end = $self->seq_length - 1;   $tags->{truncated} = 1; }

    #printf("load_exon_feature %s %d-%d %d\n", $exon_name, 
    #    $row_hash->{'CHR_START'} - $self->chrom_start, 
    #    $row_hash->{'CHR_END'} - $self->chrom_start,
    #    $row_hash->{'CHR_STRAND'}); 
    
    my $feat = new Bio::SeqFeature::Gene::Exon ( 
              -is_coding    => 1,
              -start        => $new_start,
              -end          => $new_end,              
              -strand       => $row_hash->{'CHR_STRAND'}, 
              -display_name => $exon_name,
              -tag          => $tags );
    $exon_hash->{$exon_name} = $feat;
    $self->sequence->add_SeqFeature($feat);
  }
  
  $sth->finish;
  return $self;
}


sub store {
  my $self = shift;
  my $db = shift;
  if($db) { $self->database($db); }
 
  return if($self->test_exists("select * from genomic_region where design_id=?", $self->design->design_id));
 
  $self->SUPER::store($db);
  
  my $dbh = $self->database->get_connection;  
  my $sql = qq/
      INSERT INTO GENOMIC_REGION (
            ENGINEERED_SEQ_ID,
            DESIGN_ID,
            LOCATION_INFO,
            STRAND,
            CHROM,
            CHROM_START,
            CHROM_END
        ) 
      VALUES(?,?,?,?,?,?,?)/;
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $self->id);
  $sth->bind_param(2, $self->design->design_id);
  $sth->bind_param(3, $self->location_info);
  $sth->bind_param(4, $self->strand);
  $sth->bind_param(5, $self->chrom);
  $sth->bind_param(6, $self->chrom_start);
  $sth->bind_param(7, $self->chrom_end);
  $sth->execute();
  $sth->finish;
}




##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  my $sql = "SELECT * FROM genomic_region ".
            "JOIN engineered_seq using(engineered_seq_id) ".
            "WHERE genomic_region_id = ?";
  return $class->fetch_single($db, $sql, $id);
}


sub fetch_by_design_id {
  my $class = shift;
  my $db = shift;
  my $design_id = shift;
  
  my $sql = "SELECT * FROM genomic_region ".
            "JOIN engineered_seq using(engineered_seq_id) ".
            "WHERE design_id = ?";
  return $class->fetch_single($db, $sql, $design_id);
}



1;

