# author jessica
=head1 NAME

Bio::CigarSeq - DESCRIPTION of Object

=head1 DESCRIPTION

A wrapper around a Bio::Seq to hold cigar_line based alignment information 
to easily facilitate database storage and conversion into SimpleAlign.

The Bio::Seq object is not manipulated so it can be shared among many
CigarSeq objects and is in the original form in which it was inputed
into the alignment program (SSAHA2 or exonerate).  All manipulations
to reconstruct the alignment and to do alignment analysis are calculated
as needed and do not modify the original Bio::Seq data.

This makes for a rather thin wrapper around the Bio::Seq and cigar alignment data.  
It also makes memory usage more minimal since the sequences are not being copied 
and stored like in the LocatableSeq object. 

The coordinate system of the cigar line is 0 referenced start..end exclusive
so length = end - start.  So a perfect alignment on the first ten bases of a
sequence would be recorded 0..10  M10

=head1 CONTACT

Author: Jessica Severin : jessica@sanger.ac.uk, jessica.severin@gmail.com

=cut

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=for Pod::Coverage::TrustPod
    align_length
    alignment_string
    cigar_line
    coord_consensus_2_seq
    coord_seq_2_consensus
    end
    expand_cigar
    init
    locatable_seq
    name
    new
    ori
    perc_cov
    perc_id
    perc_pos
    sequence
    start

=cut

package Bio::CigarSeq;

use strict;
use Time::HiRes qw(time gettimeofday tv_interval);
#use Bio::EnsEMBL::Utils::Exception;

use Bio::Seq;
use Bio::LocatableSeq;

#################################################
# Factory methods
#################################################

sub new {
  my ($class, @args) = @_;
  my $self = {};
  bless $self,$class;
  $self->init(@args);  
  return $self;
}

sub init {
  my $self = shift;
  #internal variables minimal allocation
  $self->{'_sequence'} = undef;  
  $self->{'_name'} = '';
  $self->{'_ori'} = '+';
  return $self;
}

sub DESTROY {
  my $self = shift;
  #If I need to do any cleanup - do it here
  $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}


#####################################################

sub sequence {
  my $self = shift;
  if(@_) {
    my $seq = shift;
    unless(defined($seq) && $seq->isa('Bio::Seq')) {
      throw('sequence argument must be a Bio::Seq');
    }
    $self->{'_sequence'} = $seq;
  }
  return $self->{'_sequence'};
}

sub name {
  my $self = shift;
  $self->{'_name'} = shift if(@_);
  $self->{'_name'}=' ' unless($self->{'_name'});
  return $self->{'_name'};
}

sub cigar_line {
  my $self = shift;
  $self->{'_cigar_line'} = shift if(@_);
  return $self->{'_cigar_line'};
}

sub start {
  my $self = shift;
  $self->{'_start'} = shift if(@_);
  return $self->{'_start'};
}

sub end {
  my $self = shift;
  $self->{'_end'} = shift if(@_);
  return $self->{'_end'};
}

sub align_length {
  my $self = shift;
  return $self->end - $self->start;
}

sub ori {
  #either '-' or '+'
  my $self = shift;
  $self->{'_ori'} = shift if(@_);
  return $self->{'_ori'};
}


sub perc_cov {
  my $self = shift;
  $self->{'perc_cov'} = shift if(@_);
  return $self->{'perc_cov'};
}

sub perc_id {
  my $self = shift;
  $self->{'perc_id'} = shift if(@_);
  return $self->{'perc_id'};
}

sub perc_pos {
  my $self = shift;
  $self->{'perc_pos'} = shift if(@_);
  return $self->{'perc_pos'};
}


sub alignment_string {
  my $self = shift;

  unless ((defined $self->cigar_line) and defined($self->sequence)) {
    throw("To get an alignment_string, the sequence and cigar_line need to be define\n");
  }

  my $sequence = $self->sequence->seq;
  if($self->ori eq '-') {
    $sequence = $self->sequence->revcom->seq;    
  }
  
  if (defined($self->start) || defined($self->end)) {
    unless (defined $self->start && defined $self->end) {
      throw("both start and end should be defined");
    }
    my $offset = $self->start;
    my $length = $self->end - $self->start;
    $sequence = substr($sequence, $offset, $length);
  }

  my $cigar_line = $self->cigar_line;
  $cigar_line =~ s/([MID])/ $1/g;

  my @cigar_segments = split " ",$cigar_line;
  my $alignment_string = "";
  my $seq_start = 0;
  foreach my $segment (@cigar_segments) {
    if ($segment =~ /^D(\d*)$/) {
      my $length = $1;
      $length = 1 if ($length eq "");
      $alignment_string .= "-" x $length;
    } elsif ($segment =~ /^[MI](\d*)$/) {
      my $length = $1;
      $length = 1 if ($length eq "");
      $alignment_string .= substr($sequence,$seq_start,$length);
      $seq_start += $length;
    }
  }
  
  return $alignment_string;
}


sub locatable_seq {
  #converts into a LocatableSeq object to create a SimpleAlign
  my ($self, @args) = @_;

  my $seqstr = $self->alignment_string;
  
  my $seq = Bio::LocatableSeq->new(-SEQ    => $seqstr,
                                   -START  => 1,
                                   -END    => length($seqstr),
                                   -ID     => $self->name,
                                   -STRAND => 0);
  return $seq;
}


sub coord_seq_2_consensus {
  my $self = shift;
  my $pos = shift;
  
  #printf("coord_seq_2_consensus : pos=%d  start=%d  end=%d\n", $pos, $self->start, $self->end);
  
  return undef unless(($pos>=$self->start) and ($pos <=$self->end));
  
  my $offset = $pos - $self->start;
  #printf("  initial offset : %d\n", $offset);
  
  my $cigar_line = $self->cigar_line;
  $cigar_line =~ s/([MID])/ $1/g;

  my @cigar_segments = split " ",$cigar_line;
  my $cons_pos = 0;
  foreach my $segment (@cigar_segments) {
    #printf("  cigar segment %s\n", $segment);
    if ($segment =~ /^D(\d*)$/) {
      my $length = $1;
      $length = 1 if ($length eq "");
      $offset += $length;
    } elsif ($segment =~ /^[MI](\d*)$/) {
      my $length = $1;
      $length = 1 if ($length eq "");
      $cons_pos += $length;
      if($cons_pos >= $offset) { last; }
    }
  }
  
  #printf("  final offset : %d\n", $offset);
  return $offset;
}


sub coord_consensus_2_seq {
  my $self = shift;
  my $cons_pos = shift;

  return undef unless($cons_pos > 0);  
  
  my $cigar_line = $self->cigar_line;
  $cigar_line =~ s/([MID])/ $1/g;

  my @cigar_segments = split " ",$cigar_line;
  my $correction = 0;
  my $t_pos = 0;
  foreach my $segment (@cigar_segments) {
    #printf("  cigar segment %s\n", $segment);
    if ($segment =~ /^D(\d*)$/) {
      my $length = $1;
      $length = 1 if ($length eq "");
      $correction -= $length;
      $t_pos += $length;
    } elsif ($segment =~ /^[MI](\d*)$/) {
      my $length = $1;
      $length = 1 if ($length eq "");
      $t_pos += $length;
      if($t_pos >= $cons_pos) { last; }
    }
  }
  my $pos = $self->start + $cons_pos + $correction;

  #printf("  coord_consensus_2_seq : cons_pos %d : start %d  : correction %d : pos %d\n", $cons_pos, $self->start, $correction, $pos);
  return $pos;
}


sub expand_cigar {
  my $self = shift;

  my $cigar_line = $self->cigar_line;
  $cigar_line =~ s/([MID])/ $1/g;

  my @cigar_segments = split " ",$cigar_line;
  my $expanded_cigar = '';
  foreach my $segment (@cigar_segments) {
    if($segment =~ /^[MID](\d*)$/) {
      my $length = $2;
      $length = 1 if ($length eq "");
      $expanded_cigar .= $1 x $length;
    } 
  }
  return $expanded_cigar;
}

1;
