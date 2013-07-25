package RecombinantUtils;
use strict;
use Bio::SeqUtils;
use Bio::Seq;
use Bio::Perl;
use Bio::Location::Simple;
use Exporter 'import';
our @EXPORT_OK = qw(recombineer gateway);

=head1 NAME

RecombinantUtils - Utilities to create synthetic maps of recombinant DNA products.

=head2 recombineer

Takes the two Seq objects representing the main input products i.e. the plasmids/BACs, and strings (or features or ranges) representing the PCR primers: part of primer "a" in first seq leading OUT of desired region, part of primer "a" in second seq leading OUT of desired region, then part of primer "b" in first seq, part of primer "b" in second seq, i.e. to get the actual primers one part of each primer must be revcomp'd and appended to the other part.

=cut

sub _simple_primer_align {#find 3' end position of exact primer string in seq and the strand it is on
  my ($seq1,$pa1) = @_;
  my $seq1_pa_end0 = index($seq1->seq,$pa1); # 5' end, 0 based
  die "primer $pa1 occurs more than once in ".$seq1->display_id."\n" if ($seq1_pa_end0>=0 and index($seq1->seq,$pa1,$seq1_pa_end0+1)>$seq1_pa_end0);
  my $rpa1 = revcom_as_string($pa1);
  my $seq1_pa_rend0 = index($seq1->seq,$rpa1); # 3' end, 0 based
  die "primer $pa1 occurs more than once in ".$seq1->display_id."\n" if ($seq1_pa_rend0>=0 and index($seq1->seq,$rpa1,$seq1_pa_rend0+1)>$seq1_pa_rend0);
  die "primer $pa1 occurs on both strands in ".$seq1->display_id."\n" if ($seq1_pa_rend0>=0 and $seq1_pa_end0>=0);
  die "primer $pa1 not found in ".$seq1->display_id."\n" if ($seq1_pa_rend0<0 and $seq1_pa_end0<0);
  return $seq1_pa_end0>0 ? ($seq1_pa_end0+length($pa1), '+1') : ($seq1_pa_rend0+1, '-1');
}
sub _primer_end_pos_and_strand {#return bounding end index of sequence to be kept and strand which indicates the "desired" side (-1: to the right, +1 to the left)
  my ($seq1,$pa1) = @_;
  if($pa1->isa(q(Bio::RangeI))){
    return $pa1->strand == -1 ? ($pa1->start,$pa1->strand) : ($pa1->end,$pa1->strand);
  }else{
    return _simple_primer_align($seq1, $pa1);
  }
}
sub _extract_seq_segments { #pa1 guaranteed in first seq(s) returned and to be on forward strand (and therefore at the rightmost end of it)
  my ($seq1, $pa1, $pb1) = @_;
  my ($seq1_pa_end, $seq1_pa_strand) = _primer_end_pos_and_strand($seq1, $pa1);
  my ($seq1_pb_end, $seq1_pb_strand) = _primer_end_pos_and_strand($seq1, $pb1);
  die "primers $pa1 and $pb1 are found on the same strand in ".$seq1->display_id."\n" if ($seq1_pa_strand == $seq1_pb_strand);
  my @r; 
  if ($seq1_pa_end < $seq1_pb_end) {
    if ($seq1_pa_strand == +1) { 
      @r = (Bio::SeqUtils->trunc_with_features($seq1,1,$seq1_pa_end), Bio::SeqUtils->trunc_with_features($seq1,$seq1_pb_end,$seq1->length)) ;
    }else{ 
      @r = (Bio::SeqUtils->trunc_with_features($seq1, $seq1_pa_end,$seq1_pb_end)) ;
    }
  }else{
    if ($seq1_pa_strand == +1) { 
      @r = (Bio::SeqUtils->trunc_with_features($seq1, $seq1_pb_end,$seq1_pa_end)) ;
    }else{ 
      @r = (Bio::SeqUtils->trunc_with_features($seq1,1,$seq1_pb_end), Bio::SeqUtils->trunc_with_features($seq1,$seq1_pa_end,$seq1->length)) ;
    }
  } 
  return @r if ($seq1_pa_strand == +1); 
  return reverse map { Bio::SeqUtils->revcom_with_features($_) } @r;
}  
sub recombineer {
  my ($seq1, $seq2, $pa1, $pa2, $pb1, $pb2) = @_;
  my ($s1,$s3) = _extract_seq_segments($seq1, $pa1, $pb1);
  my ($s2,$s4) = map {$_ ? Bio::SeqUtils->revcom_with_features($_) : $_}_extract_seq_segments($seq2, $pa2, $pb2);
  my $r = Bio::Seq->new(-alphabet=>'dna');
  Bio::SeqUtils->cat($r,$s4) if ($s4 and not $s3);  
  Bio::SeqUtils->cat($r,$s4,$s3) if ($s4 and $s3 and $seq1->is_circular); 
  Bio::SeqUtils->cat($r,$s1,$s2);
  Bio::SeqUtils->cat($r,$s3) if ($s3 and not $s4);  
  if ($s4 and $s3 and not $seq1->is_circular){ 
    die "Sequences not circular as required for given primers.\n" unless $seq2->is_circular;
    Bio::SeqUtils->cat($r,$s4,$s3);
  } 
  $r->is_circular(((not $s3) and (not $s4)) or 
                  ((not $s3) and $seq2->is_circular) or
                  ((not $s4) and $seq1->is_circular) or
                  ($seq2->is_circular and $seq1->is_circular)) ;
  return $r;
}

=head2 gateway

Take two Seq input objects - assume first has BR sites and second LB sites, find B sites, return product containing B sites only. 

=cut

#TODO: look for suitable LB and BR sites in the inputs, return main product (with B sites) and by-product (with LBR site).
#TO CONSIDER: treat the alternate Sanger B site patterns as distinct strings i.e Sanger B1 site to match Sanger B only, not www B1....
our %gateway_patterns = (
  B1 => qr/[AC]CAA[GC]TTTGTACAAAAAAGC(?:AGGCT|TGAAC)/i, #second variant for Sanger constructs
  B2 => qr/(?:ACC|CCA)ACTTTGTACAAGAAAGCTG(?:GGT|AAC)/i,   
  B3 => qr/CAACTTTGTATAATAAAGTTG/i, #Sanger variant can miss the initial A - replace with . wildcard?
  B4 => qr/CAACTTTGTATAGAAAAGTTG/i,
);
sub _simple_re_align{#find 3' end position of exact primer string in seq, the strand it is on and the matching string
  my ($seq1,$re1) = @_;
  my $str = $seq1->seq;
  my $match;
  $str=~/$re1/ig;
  my $seq1_re_end = pos($str); # 3' end
  if (defined($&)){
    $match = $&;
    pos($str) += 1 - length($&); # start next match search from next character along
  }
  die "re $re1 occurs more than once ($seq1_re_end and ".pos($str).") in ".$seq1->display_id."\n" if ($seq1_re_end and $str=~/$re1/ig);
  $str = revcom_as_string($str);
  $str=~/$re1/ig;
  my $rseq1_re_end = pos($str); # 3' end in rev coordinates
  if (defined($&)){
    $match = $&;
    pos($str) += 1 - length($&); # start next match search from next character along
  }
  die "re $re1 occurs more than once ($seq1_re_end and ".pos($str).") in revcom ".$seq1->display_id."\n" if ($rseq1_re_end and $str=~/$re1/ig);
  die "re $re1 occurs on both strands in ".$seq1->display_id."\n" if ($rseq1_re_end and $seq1_re_end);
  die "re $re1 not found in ".$seq1->display_id."\n" unless ($rseq1_re_end or $seq1_re_end);
  return $seq1_re_end,  +1, $match if $seq1_re_end ;
  return length($str)+1-$rseq1_re_end, -1, $match if $rseq1_re_end ;
}
sub gateway {
  my ($seq1, $seq2) = @_;
  my %b_pair_hits;
  my $err="";
  while(my ($bn, $bs) = each %gateway_patterns){
    eval { 
      $b_pair_hits{$bn}=[
         _simple_re_align($seq1, $bs),
         _simple_re_align($seq2, $bs),
      ];
    };
    $err=join(" ",$err,$@) if $@;
  }
  my $nbp = scalar(keys %b_pair_hits);
  die "Number of valid B site pairs found is $nbp not 2. $err" unless ($nbp==2);
  my ($loc1a,$loc1b, $loc2a, $loc2b);
  while(my ($bn, $br) = each %b_pair_hits){
    my ($s1pos, $s1strand, $s1match, $s2pos, $s2strand, $s2match) = @$br;
    die "Matching B site sequences ($s1strand and $s2strand) have differing lengths." if (length($s1match)!=length($s2match));
    my $shift1 = -1 * int(length($s1match)/2);
    my $shift2 = $shift1 + 1;
    unless($loc1a){
      my $p = $s1pos+($shift1*$s1strand);
      $loc1a = Bio::Location::Simple->new(-start=>$p, -end=>$p, -strand=> $s1strand);
      $p = $s2pos+($shift2*$s2strand);
      $loc2a = Bio::Location::Simple->new(-start=>$p, -end=>$p, -strand=> ($s2strand*-1));
    }else{
      my $p = $s1pos+($shift1*$s1strand);
      $loc1b = Bio::Location::Simple->new(-start=>$p, -end=>$p, -strand=> $s1strand);
      $p = $s2pos+($shift2*$s2strand);
      $loc2b = Bio::Location::Simple->new(-start=>$p, -end=>$p, -strand=> ($s2strand*-1));
    }
  }
  return recombineer($seq1,$seq2,$loc1a,$loc2a,$loc1b,$loc2b);
}

1;

=head1 AUTHOR

David K Jackson <david.jackson@sanger.ac.uk>

=cut
