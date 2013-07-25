package HTGT::Controller::Design::TargetFinder;

use warnings;
use strict;
use base 'Catalyst::Controller';
use HTGT::Utils::EnsEMBL;
use Data::Dumper;
use Tie::IxHash;

=head1 NAME

HTGT::Controller::Design::TargetFinder - Catalyst Controller

=head1 DESCRIPTION

Generate target exons 

=head1 METHODS

=cut

=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body(
'Matched HTGT::Controller::Design::TargetFinder in Design::TargetFinder.'
    );
}

=head2

Method for generating target exons for frameshift standard allele

=cut

sub standard : Local {
    my ( $self, $c, $ams ) = @_;

    my $gene_adaptor = HTGT::Utils::EnsEMBL->gene_adaptor    
        or die "Failed to get gene adaptor\n";
    my $dbh = HTGT::Utils::EnsEMBL->db_adaptor
        or die "Failed to get the DBAdaptor!\n";
    my $sa = HTGT::Utils::EnsEMBL->slice_adaptor
        or die "Failed to get the slice adaptor\n";

    my $gene = $gene_adaptor->fetch_by_stable_id($ams);
    if ( !defined $gene ) {
        die "$ams Removed from DB\n";    #removed from database
    }

    #transfer to slice.
    $gene = $gene->transfer( $gene->feature_Slice() );
    my @transcripts = @{ $gene->get_all_Transcripts() };

    #sort transcripts by length;

    my $template_transcript;
    my $current_length = 0;
    for my $t (@transcripts) {
        my $length = length $t->translateable_seq();

        #print "LEN: $length->", $t->stable_id(), "\n";
        if ( $length > $current_length ) {
            $current_length      = $length;
            $template_transcript = $t;
        }
    }

    if ( !defined $template_transcript ) {
        die "$ams failed to define a template\n";
    }

    #Find first coding exon

    my @template_coding_exons =
      @{ $template_transcript->get_all_translateable_Exons() };
    my @template_all_exons  = @{ $template_transcript->get_all_Exons() };
    my $template_seq        = $template_transcript->translateable_seq();
    my $template_seq_length = ( length $template_seq ) / 3;

#I am expecting to do a look-up later and think the best way is to hash the data!
    my %coding_exons =
      map { $_->stable_id() => $_ }
      @{ $template_transcript->get_all_translateable_Exons() };
    my %all_exons =
      map { $_->stable_id() => $_ } @{ $template_transcript->get_all_Exons() };

    #Filter out those transcripts with two or less FULLY coding exons
    my $numb_fully_coding_exons = 0;

    for my $e (@template_coding_exons) {
        if ( exists $all_exons{ $e->stable_id() } ) {
            $e = $all_exons{ $e->stable_id() };
            my $code_len = (
                abs(
                    $e->cdna_coding_start($template_transcript) -
                      $e->cdna_coding_end($template_transcript)
                  ) + 1
            );
            my $full_len = abs( $e->start() - $e->end() ) + 1;
            if ( $full_len == $code_len ) { $numb_fully_coding_exons++; }
        }
    }

    if ( $numb_fully_coding_exons <= 2 ) {
        die "$ams - not enough coding material!\n";
    }

    #Determine point after 35 amino acids have been coded for
    my $first_ko_exon;
    my $first_ko_exon_obj;
    my $first_ko_id;

    my $first_coding_exon = $template_coding_exons[0];

#This does not do what you think it does!
#my $aas_coded = (abs( $first_coding_exon->cdna_coding_start($template_transcript) - $first_coding_exon->cdna_coding_end($template_transcript) ) + 1);
    my $aas_coded = (
        abs(
            $first_coding_exon->cdna_coding_end($template_transcript) -
              $first_coding_exon->cdna_coding_start($template_transcript)
        )
    ) / 3;

    #print $first_coding_exon->start(), "\n";
    #print $first_coding_exon->end(), "\n";
    #print $first_coding_exon->cdna_coding_start($template_transcript), "\n";
    #print $first_coding_exon->cdna_coding_end($template_transcript), "\n";

    for ( my $i = 0 ; $i < @template_all_exons ; $i++ ) {
        if (    $aas_coded <= 35
            and $template_all_exons[$i]->stable_id eq
            $first_coding_exon->stable_id() )
        {
            $first_ko_exon     = $i + 2;
            $first_ko_exon_obj = $template_all_exons[ $i + 2 ];
            $first_ko_id       = $template_all_exons[ $i + 2 ]->stable_id();
        }
        elsif ( $aas_coded > 35
            and $template_all_exons[$i]->stable_id eq
            $first_coding_exon->stable_id() )
        {
            $first_ko_exon     = $i + 1;
            $first_ko_exon_obj = $template_all_exons[ $i + 1 ];
            $first_ko_id       = $template_all_exons[ $i + 1 ]->stable_id();
        }
        else {

            #oh no!
        }
    }

    my @errors = ();
    my %scores = ();

    #See if we can hack out the first exon :)
    my $first_exon      = $template_coding_exons[0];
    my $number_of_acids = (
        (
            $first_exon->cdna_coding_end($template_transcript) -
              $first_exon->cdna_coding_start($template_transcript)
        ) + 1
    ) / 3;
    if ( $number_of_acids <= 35 ) {
        my $score          = 0;
        my $two_up         = $template_coding_exons[2];
        my $first_exon_seq = $first_exon->seq()->seq();
        my $two_up_seq     = $two_up->seq()->seq();

        my $f = ( length $first_exon_seq ) / 3;

        #print "LEN: $f\n";
        #print "$first_exon_seq\n";

#This is a huge pile of arse - the ensembl api is totally inconsistent in the way it treats coding exons.
#asking for the coding exons and coordinates gives only the coding start and end ... if you ask for the sequence
#you get the untranslated part too.  WHAT A PILE OF SHITE!

        if ( ( ( length $first_exon_seq ) / 3 ) =~ /^-?\d+$/ ) {
            my $str = substr $first_exon_seq, -2;
            $str .= substr $two_up_seq, 0, 1;

            if ( $str =~ /TAA|TAG|TGA/ig ) {
                my $left_flank =
                  ( $template_coding_exons[1]->start() -
                      $template_coding_exons[0]->end() ) - 1;
                my $right_flank =
                  ( $template_coding_exons[2]->start() -
                      $template_coding_exons[1]->end() ) - 1;

                #print "LF: $left_flank  RF: $right_flank\n";

                score_flanking_introns( \$left_flank, \$right_flank, \$score );

                $score +=
                  60;    #Because I KNOW we are in the first 20% of the protein.

                score_region_length(
                    $template_coding_exons[1],
                    $template_coding_exons[1],
                    $template_transcript, \$score
                );

                $score += 1000000000000;

#$scores{$template_coding_exons[1]->stable_id() } = "$score $left_flank $right_flank " . $template_coding_exons[1]->transform('chromosome')->start() . " " . $template_coding_exons[1]->transform('chromosome')->end();
            }
            else {

            }

        }
        else {

        }
    }

#Tested and appear to work on ENSMUSG00000029465->Ensmust00000102525 - DO NOT DELETE THIS LINE PLEASE.

    my $power_sets = power_sets( \@template_all_exons );

    #Loop over the combinations - isn't this fun?
    for my $set (@$power_sets) {

        #print "Current SET ... $set\n";

        my $score = 0;
        my @set_array = split /\s+/, $set;

        my $first_exon_id = $template_all_exons[ $set_array[0] ]->stable_id();
        my $last_exon_id =
          $template_all_exons[ $set_array[$#set_array] ]->stable_id();

        #Remove if less than 35 amino acids have been coded for
        ###print "FKO = $first_ko_exon\n";
        if ( $set_array[0] < $first_ko_exon ) {

#Need to pass this off to another routine to check the new termination site - we have compensated for this above :)
#push @errors, "$set - less than 35 residues have been coded for by previous exons!\n";
#print "CODED FOR ... $set\n";
            next;
        }

      # exists $coding_exons{ $template_all_exons[$set_array[0]] }->stable_id();
        if ( !exists
            $coding_exons{ $template_all_exons[ $set_array[0] ]->stable_id() } )
        {

            #print "NICE ... $set\n";
            next;
        }

        #Can't remove the last coding exon
        if ( $set_array[$#set_array] + 1 == scalar @template_all_exons ) {

            #print "LCE ... $set\n";
            #push @errors, "$set Can't ko last coding exon\n";
            next;
        }

        #Establish the amount of protein coded by previous exons
        #Remove if > 50% of protein
        my $exon_start_point = 0;
        for ( my $i = 0 ; $i < $set_array[0] ; $i++ ) {

#This avoids the problem of the non-coding exons - why didn't I just loop over the coding ones? - I was tired on Friday ...
            if ( exists $coding_exons{ $template_all_exons[$i]->stable_id() } )
            {
                $exon_start_point +=
                  ( $template_all_exons[$i]
                      ->cdna_coding_end($template_transcript) -
                      $template_all_exons[$i]
                      ->cdna_coding_start($template_transcript) ) + 1;
            }
            else {
                next;
            }
        }
        $exon_start_point = $exon_start_point / 3;
        if ( $exon_start_point > 0.5 * $template_seq_length ) {

            #push @errors, "$set - going towards C-terminal of protein\n";
            #print "CTERM ... $set\n";
            next;
        }

        #Get and check for phase matches
        my $left_exon_phase =
          $template_all_exons[ $set_array[0] - 1 ]->end_phase();
        my $right_exon_phase =
          $template_all_exons[ $set_array[$#set_array] + 1 ]->phase();

        #Remove matching phase
        if ( $left_exon_phase == $right_exon_phase ) {

            #print "SYM ... $set\n";
            #push @errors, "$set symmetical exons\n";
            next;
        }

#print $set, " " ,  $template_all_exons[ $set_array[0]  ]->stable_id() , ":" , $template_all_exons[ $set_array [ $#set_array ] ]->stable_id() , " $left_exon_phase :: $right_exon_phase\n";

#Skip those where either flanking intron is less than 450 base pairs - this would look nicer if the patterns referenced exons directly.
#This is partial fall out from stopping me from using $$ - you may think the comments here are odd, the ones in HTGT are worse!
#print "$set\n";

        my $left_intron_length =
          ( $template_all_exons[ $set_array[0] ]->start() -
              $template_all_exons[ $set_array[0] - 1 ]->end() ) - 1;
        my $right_intron_length =
          ( $template_all_exons[ $set_array[$#set_array] + 1 ]->start() -
              $template_all_exons[ $set_array[$#set_array] ]->end() ) - 1;

        #debug
        ###print "$set " , $left_intron_length, " ", $right_intron_length, "\n";

        if ( $left_intron_length <= 450 or $right_intron_length <= 450 ) {

            #push @errors, "$set short flanking introns\n";
            #print "intron length ... $set\n";
            next;
        }

        #Score the intron lengths
        score_flanking_introns( \$left_intron_length, \$right_intron_length,
            \$score );

#This is probably over-complicated but I don't care ... actually I do ... but I can't be arsed to think about it.
#Errors are occuring here!
        score_distance_from_nterm( $set_array[0], \@template_all_exons,
            \%coding_exons, $template_transcript, $template_seq_length,
            \$score );

        #Score the length of the construct
        my ($len) = score_region_length(
            $template_all_exons[ $set_array[0] ],
            $template_all_exons[ $set_array[$#set_array] ],
            $template_transcript, \$score
        );

        #print "The length of the construct is: $len\n";
        if ( $len > 3500 ) {

            #print "length skip ... $set ($len)\n";
            next;
        }

        #Check for things on the opposite strand1
        my $overlap = overlapping_loci( $template_all_exons[ $set_array[0] ],
            $template_all_exons[ $set_array[$#set_array] ], $sa );

#print "$set OVERLAP: $overlap\n";
#print $template_all_exons[$set_array[0]]->stable_id, " --> ", $template_all_exons[ $set_array[ $#set_array ] ]->stable_id, "\n";

        if ($overlap) {
            print "OVL ... $set\n";
            push @errors, "$set overlapping loci\n";
            next;
        }
        else {
            my $key = '';
            for ( my $i = 0 ; $i < @set_array ; $i++ ) {
                my $e = $template_all_exons[ $set_array[$i] ];
                $key .= $e->stable_id() . " ";
            }

            $scores{$key} = $score;

            #Should create new exon objects on the chromosome
            my $chr_exon_r = $template_all_exons[ $set_array[$#set_array] ];

            if ( $template_all_exons[ $set_array[0] ]->transform('chromosome')
                ->strand() == 1 )
            {
                $scores{$key} =
                  "$score $left_intron_length $right_intron_length "
                  . $template_all_exons[ $set_array[0] ]
                  ->transform('chromosome')->start() . " "
                  . $template_all_exons[ $set_array[$#set_array] ]
                  ->transform('chromosome')->end();
            }
            else {
                $scores{$key} =
                  "$score $left_intron_length $right_intron_length "
                  . $template_all_exons[ $set_array[$#set_array] ]
                  ->transform('chromosome')->start() . " "
                  . $template_all_exons[ $set_array[0] ]
                  ->transform('chromosome')->end();

#warn  $template_all_exons[$set_array[0]]->transform('chromosome')->end (), "*\n";
#warn  $template_all_exons[$set_array[0]]->transform('chromosome')->strand(), "\n";
#warn  $template_all_exons[$set_array[0]]->transform('chromosome')->start() . " --> ";
#warn  $template_all_exons[$set_array[$#set_array] ]->transform('chromosome')->end(), "-->";
#warn  $template_all_exons[$set_array[$#set_array] ]->transform('chromosome')->start(), "\n";
            }
        }
    }

    my @targets;    # return value

    if ( keys %scores > 0 ) {
        for ( keys %scores ) {
            my @values = split /\s+/, $scores{$_};

            my @tmp = split /\s+/,
              $_;    #tmp is the list of exons covered by the critical regions.
            my $are_common =
              common_to_sets( \@tmp, \@transcripts, $template_transcript );

            #print "COMMON STATUS: $are_common!\n";
            if ($are_common) {
                my ( $l_param, $r_param, $chr_s, $chr_e ) =
                  prepare_for_automagic( $scores{$_} );
                $c->log->debug(
"$ams $tmp[0] $tmp[$#tmp] $chr_s $chr_e @{$l_param} @{$r_param} ($values[0])\n"
                );

                # re-format the params
                my @l_params;
                foreach my $l_para ( @{$l_param} ) {
                    push @l_params, $l_para;
                }

                my @r_params;
                foreach my $r_para ( @{$r_param} ) {
                    push @r_params, $r_para;
                }

                # return value
                my $target;
                $target->{ams}          = $ams;
                $target->{start_exon}   = $tmp[0];
                $target->{end_exon}     = $tmp[$#tmp];
                $target->{target_start} = $chr_s;
                $target->{target_end}   = $chr_e;
                $target->{l_param}      = \@l_params;
                $target->{r_param}      = \@r_params;
                $target->{score}        = $values[0];

                push @targets, $target;
            }
        }
        return \@targets;
    }
}

#                                                                          #
############################## SNIP ########################################
#                                                                          #

sub prepare_for_automagic {
    my ($string) = @_;
    my ( $score, $lil, $ril, $chr_s, $chr_e ) = split /\s+/, $string;

    my @defaults_l = ( 120, 60, 300 );
    my @defaults_r = ( 120, 60, 100 );

    if ( $lil < 700 ) {
        _readjust( $lil, \@defaults_l );
    }
    if ( $ril < 700 ) {
        _readjust( $ril, \@defaults_r );
    }
    return ( \@defaults_l, \@defaults_r, $chr_s, $chr_e );
}

sub _readjust {
    my ( $l, $array ) = @_;
    for (@$array) {
        $_ = int( ( ( $l / 700 ) * $_ ) + 0.5 );
    }
}

sub common_to_sets {
    my ( $exons, $transcripts, $tt ) = @_;    #$tt is the template transcript
    my $f_exon = $exons->[0];
    my $l_exon = $exons->[ scalar @{$exons} - 1 ];

    my %transcripts = map { $_->stable_id() => $_ } @$transcripts;

    return (1) if keys %transcripts == 1;

    delete $transcripts{ $tt->stable_id()
      };    #remove the template transcript as the exons belong to this chap

    for my $t ( keys %transcripts ) {
        my %coding_exons =
          map { $_->stable_id() => $_ }
          @{ $transcripts{$t}->get_all_translateable_Exons() };
        if (    exists $coding_exons{$f_exon}
            and exists $coding_exons{$l_exon} )
        {
            return (1);
        }
        else {
            return (0);
        }
    }
}

sub overlapping_loci {
    my ( $left_exon, $right_exon, $slice_adaptor ) = @_;
    my $left_slice =
      $slice_adaptor->fetch_by_exon_stable_id( $left_exon->stable_id(), 1500 );
    my $right_slice =
      $slice_adaptor->fetch_by_exon_stable_id( $right_exon->stable_id(), 1500 );

    my @left_exonS  = @{ $left_slice->get_all_Exons() };
    my @right_exonS = @{ $right_slice->get_all_Exons() };

    my %left_exons =
      map { $_->stable_id() => $_ } @{ $left_slice->get_all_Exons() };
    my %right_exons =
      map { $_->stable_id() => $_ } @{ $left_slice->get_all_Exons() };

    my $strand = $left_exons{ $left_exon->stable_id() }->strand;

    _delete_same_strand( \%left_exons,  $strand );
    _delete_same_strand( \%right_exons, $strand );

    #for (keys %left_exons  ) {
    #print $left_exons{$_}->stable_id(), "\n";
    #}

    if ( keys %left_exons > 1 or keys %right_exons > 1 ) {
        return (1);
    }
    else {
        return (0);
    }
}

sub _delete_same_strand {
    my ( $hash, $strand ) = @_;
    for ( keys %$hash ) {

        #print "STR: $strand :: ", $hash->{$_}->strand(), "\n";
        if ( $hash->{$_}->strand == $strand ) {

            #print "!!!!\n";
            delete $hash->{$_};
        }
    }
}

sub score_region_length {
    my ( $left_exon, $right_exon, $transcript, $score ) = @_;
    my $size = ( $right_exon->end() - $left_exon->start() ) + 1;
    if ( $size <= 500 ) { $$score += 200; }
    elsif ( $size > 500  and $size <= 1000 ) { $$score += 190; }
    elsif ( $size > 1000 and $size <= 1500 ) { $$score += 180; }
    elsif ( $size > 1500 and $size <= 2000 ) { $$score += 150; }
    elsif ( $size > 2000 and $size <= 2500 ) { $$score += 100; }
    elsif ( $size > 2500 and $size <= 3500 ) { $$score += 25; }
    else { }    #do nothing - welcome to the world of C.

    return ($size);

}

sub score_distance_from_nterm {
    my (
        $first_set_exon, $all_exons,  $coding_exons,
        $transcript,     $seq_length, $score
    ) = @_;

    my $e = $all_exons->[$first_set_exon];

    my $code_start_pos = 0;
    for ( my $i = 0 ; $i < @$all_exons ; $i++ ) {
        my $ce =
          $all_exons->[$i];   #you people and your silly fear of $$all_exons[$i]
        if ( exists $coding_exons->{ $ce->stable_id() } ) {

            #print $ce->stable_id(), "    <----\n";
            $code_start_pos = $ce->cdna_coding_start($transcript);
            last;             #aka a goto
        }
        else {
            next
              ; #skip the ones that don't code for nothing - yes that is a double negative which would imply that the exon DID code for something!
        }
    }

    #print $e->cdna_coding_start($transcript), "\n";
    #print $e->stable_id(),"\n";
    my $dist_from_start =
      ( $e->cdna_coding_start($transcript) - $code_start_pos ) / 3;

    #my $dist_from_start = 12;
    # WTF did I do here - this must have been modified for some reason.
    if    ( $dist_from_start < 0.2 * $seq_length ) { $$score += 80; }
    elsif ( $dist_from_start < 0.2 * $seq_length ) { $$score += 70; }
    elsif ( $dist_from_start < 0.2 * $seq_length ) { $$score += 40; }
    elsif ( $dist_from_start < 0.2 * $seq_length ) { $$score += 20; }
    else {
        $$score += 0;
    } #Almost pointless ... actually, like most comments in this *script*, totally pointless

}

#This routine scores the flanking intron lengths.  It is recycled from the old algorithm D.A.N
sub score_flanking_introns {
    my ( $l, $r, $score_ ) = @_;
    if ( $$l >= 700 and $$r >= 700 ) {
        $$score_ += 200;
    }

    elsif ( $$l >= 700 ) {
        if    ( $$r >= 500 and $$r < 700 ) { $$score_ += 80; }
        elsif ( $$r >= 400 and $$r < 500 ) { $$score_ += 20; }
        elsif ( $$r < 400 and $$r > 350 ) { $$score_ -= 60; }
        elsif ( $$r < 350 ) { $$score_ -= 80; }
        else {
            warn
"URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 1 ($$l <-> $$r)\n";
            die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n";
        }
    }

    elsif ( $$r >= 700 ) {
        if    ( $$l >= 500 and $$l < 700 ) { $$score_ += 80; }
        elsif ( $$l >= 400 and $$l < 500 ) { $$score_ += 20; }
        elsif ( $$l < 400 and $$l > 350 ) { $$score_ -= 60; }
        elsif ( $$l < 350 ) { $$score_ -= 80; }
        else {
            warn
"URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 2 ($$l <-> $$r)\n";
            die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n";
        }
    }

    elsif ( $$l < 700 and $$l >= 500 ) {
        if    ( $$r < 700 and $$r >= 500 ) { $$score_ += 50; }
        elsif ( $$r < 500 and $$r >= 400 ) { $$score_ += 10; }
        elsif ( $$r < 400 ) { $$score_ -= 80; }
        else {
            warn
"URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 3 ($$l <-> $$r)\n";
            die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n";
        }
    }

    elsif ( $$r < 700 and $$r >= 500 ) {
        if ( $$l < 700 and $$l >= 500 ) { $$score_ += 50; }
        elsif ( $$l < 500 and $$l >= 450 ) { $$score_ -= 20; }
        elsif ( $$l < 450 ) { $$score_ -= 80; }
        else {
            warn
"URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 4 ($$l <-> $$r)\n";
            die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n";
        }
    }

    elsif ( $$l < 500 and $$l >= 400 ) {
        if ( $$r < 500 and $$r >= 400 ) { $$score_ += 5; }
        elsif ( $$r < 400 ) { $$score_ -= 45; }
        else {
            warn
"URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 5 ($$l <-> $$r)\n";
            die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n";
        }
    }

    elsif ( $$r < 500 and $$r >= 400 ) {
        if ( $$l < 500 and $$l >= 400 ) { $$score_ += 5; }
        elsif ( $$l < 400 ) { $$score_ -= 45; }
        else {
            warn
"URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 6 ($$l <-> $$r)\n";
            die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n";
        }
    }

    elsif ( $$l < 400 and $$r < 400 ) {
        if    ( $$l >= 350 and $$r < 400 )  { $$score_ -= 100; }
        elsif ( $$l < 400  and $$r >= 350 ) { $$score_ -= 15; }
        elsif ( $$l < 350  and $$r < 350 )  { $$score_ -= 250; }
        else {
            warn
"URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 7 ($$l <-> $$r)\n";
            die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n";
        }
    }

    else {
        warn
"URGENT: email dk3\@sanger.ac.uk and inform him about this error\nCODE 8 ($$l <-> $$r)\n";
        die " \n\n\n\n\n\n\n\tD'OH!\n\n\n\n\n\n\n";
    }
}

sub power_sets {
    my ($array) = @_;
    my @t       = @$array;
    my @sets    = ();
    my @list    = 0 .. $#t;
    foreach my $start ( 0 .. $#list ) {
        foreach my $end ( $start .. $#list ) {
            my @sublist = @list[ $start .. $end ];
            push @sets, join( ' ', @sublist );
        }
    }
    return ( \@sets );
## Please see file perltidy.ERR
}

=head2

Method for generating target exons for frameshift short allele

=cut

sub short : Local {

    #####################################################################
    # Key:                                                              #
    # $var   = scalar                                                   #
    # $var_  = ref to array                                             #
    # $var__ = ref to hash                                              #
    # _some_sub = A subroutine called by another subroutine             #
    #####################################################################

    #####################################################################
    #                                                                   #
    #            40 instead of 50 % cutoff for protein KO.              #
    #                                                                   #
    #####################################################################

    my ( $self, $ctx, $ensembl_id ) = @_;

    my $gene_adaptor = HTGT::Utils::EnsEMBL->gene_adaptor
      or die "Failed to get gene adaptor\n";
    my $dbh = HTGT::Utils::EnsEMBL->db_adaptor
      or die "Failed to get the DBAdaptor!\n";

    my $gene = get_gene_object( $gene_adaptor, $ensembl_id );
    die "For some reason I didn't get a gene"
      if !
          defined
          $gene;    # Perl Critic says this is naughty - *&@% Damian Conway.

    my $template_transcript = get_longest_transcript($gene);
    die "For some reason I didn't get a template"
      if !defined $template_transcript;

    my $template_protein = $template_transcript->translation();
    die "Failed to translate!\n" if !defined $template_protein;

    my ( $all_exons__, $coding_exons__ ) =
      get_coding_and_all_exons($template_transcript);

    my $number_of_exons = keys %$coding_exons__;

    die "There are too many exons -> $ensembl_id\n" if $number_of_exons > 4;

    my $coding_contributions__ = get_coding_contributions($template_transcript);

    my $combinations__ =
      get_power_sets( $template_transcript, $coding_contributions__ );

    #warn "TARGET: ", $template_transcript->stable_id(), "\n";

    shit_sift( $ctx, $template_transcript, $combinations__, $ensembl_id );
}

sub shit_sift {
    my ( $ctx, $t, $c, $ensembl_id ) = @_;

    my %coding_exons =
      map { $_->stable_id() => $_ } @{ $t->get_all_translateable_Exons() };
    my %all_exons = map { $_->stable_id() => $_ } @{ $t->get_all_Exons() };

    my @coding = @{ $t->get_all_translateable_Exons() };
    my @all    = @{ $t->get_all_Exons() };

    my %coding_cont = ();
    _coding_cont( \%coding_exons, \%coding_cont );

    my $ce1 = $coding[0];

    my $aas_coded_for_by_ce1 = ( length $ce1->seq()->seq() ) / 3;

    # If we have over 35 amino acids we fork one way

    if ( $aas_coded_for_by_ce1 >= 35 ) {

        for my $set ( keys %$c ) {

            # To store the amount of protein KO.
            my %protein_ko   = ();
            my @set          = split /\s+/, $set;
            my $first_in_set = $all[ $set[0] ];

            # Eliminate a set if the first exon does not code.
            next if !exists $coding_exons{ $first_in_set->stable_id() };

          # Get the amount of protein removed - save it to a hash for later too.
            my $set_pct = get_set_sum( \@set, \%coding_cont, \@all );
            $protein_ko{$set} = $set_pct;

            # If we are looking at the very first exon then we don't want it.

#print "$set -> $set_pct ", $coding_exons{ $first_in_set->stable_id() }->stable_id(), ' ',  $coding[0]->stable_id(), "\n";
# This will fail in some instances - see ENSMUSG0^53206 - Added the check against the all array to solve this - I HOPE!
            next
              if $coding_exons{ $first_in_set->stable_id() }->stable_id() eq
                  $coding[0]->stable_id() and $set_pct < 50
                  or $coding[0]->stable_id eq $all[0]->stable_id();

            # Skip the set it the last exon is the last exon in the gene
            next if $all[ $set[-1] ]->stable_id() eq $all[-1]->stable_id();

            # Skip if the length of the critical set is greater than 3500 nts
            my $set_length =
              abs( ${ $t->get_all_Exons }[ $set[0] ]->start() -
                  ${ $t->get_all_Exons }[ $set[-1] ]->end() ) + 1;

            next if $set_length > 3500;

            my ( $sphase, $ephase ) =
              is_it_a_frameshift( \@coding, \@all, \@set );

# Skip those that hit the start or end exon that do not destroy more than 50% of the protein
            next if ( ( $sphase == 99 or $ephase == 99 ) and $set_pct <= 40 );

# Skip the little chaps that are symmetrical - we can't do anything with these until the ELSE block related to this IF block
            next if ( $sphase == $ephase ) and $set_pct <= 40;

# Skip the ones that have a negative phase and code for less than 50% of the protein
            next if ( $sphase == -1 or $ephase == -1 ) and $set_pct <= 40;
            my $te = $first_in_set->stable_id();

            my $lead_intron =
              _calculate_intron_flank_size( $t, $set[0], ( $set[0] ) - 1, 'l' );
            my $exit_intron =
              _calculate_intron_flank_size( $t, $set[0], ( $set[0] ) + 1, 'r' )
              if ${ $t->get_all_Exons() }[ $set[-1] ]->stable_id() ne
                  ${ $t->get_all_Exons() }[-1]->stable_id();

#print "$ensembl_id $te Set remain: [$set], $sphase, $ephase, $set_pct -> $lead_intron -> $exit_intron\n";
            my %hash;
            $hash{$set} = $set;
            my $results = format_for_designs( $ctx, $t, \%hash, $ensembl_id );
            return ($results);

            # Arguments -> my ( $tt, $c__) = @_;

        }
    }

# Else we need to test to see if we can induce serveral stop sites elsewhere in the protein
    else {

#Must test for new stop sites.
#Loop over all possible combinations - checking for new stop sites in the sequence - yey

    }
}

#
# This code is verbose so that the person that gets to edit it after me can change it
# It makes some abstract attempt to discern if the CE set is in or out of phase.
#

sub is_it_a_frameshift {
    my ( $c, $n, $s ) = @_;

# The first element of the array is a number, then minus 1 to get the previous exon.
    my $previous_exon = $s->[0] - 1;

   # The last element of the array is a number, then add 1 to get the next exon.
    my $next_exon = $s->[-1] + 1;

    # Previous exon
    my $pe = $n->[$previous_exon];

    # Next exon
    my $ne = $n->[$next_exon];

    my $left_phase  = 100;
    my $right_phase = 101;

    if ( defined $pe->end_phase() ) { $left_phase  = $pe->end_phase() }
    if ( defined $ne->phase() )     { $right_phase = $ne->phase() }

    return ( $left_phase, $right_phase );
}

#
# Use this to work out how much of the protein is destroyed by removing this set of exons
#

sub get_set_sum {
    my ( $set, $cont, $exons ) = @_;
    my $sum = 0;
    for (@$set) {
        my $id = $exons->[$_]->stable_id();
        if ( exists $cont->{$id} ) {
            $sum += $cont->{$id};
        }
    }
    return ($sum);
}

# Use to get the % contribution of each exon to the final protein
sub _coding_cont {
    my ( $ce, $hash ) = @_;
    my $sum = 0;
    for ( keys %$ce ) {
        $sum += length( $ce->{$_}->seq()->seq() );
        $hash->{ $ce->{$_}->stable_id() } = length( $ce->{$_}->seq()->seq() );
    }
    for ( keys %$hash ) {
        $hash->{$_} = ( $hash->{$_} / $sum ) * 100;
    }
}

#identify_ko( $template_transcript, $combinations__, $coding_contributions__ );

#format_for_designs( $template_transcript, $combinations__ );

#####################################################################
#                                                                   #
#                           THE SUBROUTINES                         #
#                                                                   #
#####################################################################

#                                                #
# Setup the format for automagic design creation #
#                                                #
sub format_for_designs {
    my ( $ctx, $tt, $c__, $ensembl_id ) = @_;
    my @l_defaults = ( 120, 60, 300 );
    my @r_defaults = ( 120, 60, 100 );
    my $strand     = $tt->transform('chromosome')->strand();

    # return value
    my @targets;
    for my $set ( keys %$c__ ) {
        my @set         = split /\s+/, $set;
        my $first       = $set[0];
        my $last        = $set[-1];
        my $chrom_start = 0;
        my $chrom_end   = 0;
        my $lf          = 0;
        my $rf          = 0;

        $lf =
          _calculate_intron_flank_size( $tt, $set[0], ( $set[0] ) - 1, 'l' );
        $rf =
          _calculate_intron_flank_size( $tt, $set[0], ( $set[-1] ) + 1, 'r' )
          if ${ $tt->get_all_Exons() }[ $set[-1] ]->stable_id() ne
              ${ $tt->get_all_Exons() }[-1]->stable_id();

        if ( $strand == 1 ) {
            $chrom_start =
              ${ $tt->get_all_Exons() }[$first]->transform('chromosome')
              ->start();
            $chrom_end =
              ${ $tt->get_all_Exons() }[$last]->transform('chromosome')->end();
        }
        elsif ( $strand == -1 ) {
            $chrom_start =
              ${ $tt->get_all_Exons() }[$last]->transform('chromosome')
              ->start();
            $chrom_end =
              ${ $tt->get_all_Exons() }[$first]->transform('chromosome')->end();
        }
        else {
            die
"There is one hell of an error in your code! Strand == ***$strand***\n";
        }

        if ( $lf < 700 ) {
            _readjust( $lf, \@l_defaults );
        }
        if ( $rf < 700 and $rf != 0 ) {
            _readjust( $rf, \@r_defaults );
        }

        $ctx->log->debug(
            "$ensembl_id ",
            ${ $tt->get_all_Exons() }[$first]->stable_id(),
            " ",
            ${ $tt->get_all_Exons() }[$last]->stable_id(),
            " ",
            $chrom_start,
            " ",
            $chrom_end,
            " @l_defaults @r_defaults\n"
        );

        #reformat the params
        my @l_params;
        my @r_params;

        foreach my $l_para (@l_defaults) {
            push @l_params, $l_para;
        }

        foreach my $r_para (@r_defaults) {
            push @r_params, $r_para;
        }

        # return value
        my $target;
        $target->{ams}        = $ensembl_id;
        $target->{start_exon} = ${ $tt->get_all_Exons() }[$first]->stable_id();
        $target->{end_exon}   = ${ $tt->get_all_Exons() }[$last]->stable_id();
        $target->{target_start} = $chrom_start;
        $target->{target_end}   = $chrom_end;

        $target->{l_param} = \@l_params;
        $target->{r_param} = \@r_params;

        push @targets, $target;
    }

    return ( \@targets );
}

#                                                                        #
# Uses a set of routines to remove the impossilbe/undesirable ko options #
#                                                                        #
sub identify_ko {
    my ( $tt, $c__, $cc__ ) = @_;

    for my $set ( keys %$c__ ) {

        #print "CURRENT SET: $set\n";
        my @set = split /\s+/, $set;
        delete $c__->{$set}
          if ${ $tt->get_all_Exons() }[ $set[0] ]->stable_id() eq
              ${ $tt->get_all_Exons }[0]->stable_id();

#delete $c__->{$set} if ( $cc__->{${$tt->get_all_Exons() }[ $set[-1] ]->stable_id()} < 50 ) and next;
        if (
            $cc__->{ ${ $tt->get_all_Exons() }[ $set[-1] ]->stable_id() } < 50 )
        {

            my $prev_exon_number = $set[0] - 1;
            my $start_phase =
              ${ $tt->get_all_Exons() }[ ($prev_exon_number) ]->end_phase();

            my $trail_exon_number = $set[-1] + 1;
            my $end_phase;
            if ( defined ${ $tt->get_all_Exons() }[$trail_exon_number] ) {
                $end_phase =
                  ${ $tt->get_all_Exons() }[$trail_exon_number]->end_phase();
            }
            else {

                # We are now dealing with the trailing exon !
                #print "SET: $set ( $trail_exon_number )\n";
                delete $c__->{$set};
                next;
            }

            #print "Deleting SET: $set $end_phase :: $start_phase\n";
            #print "SET: $set -:> START : $start_phase -> END: $end_phase\n";
            if ( $start_phase == $end_phase ) {
                delete $c__->{$set};
            }
            next;
        }

        my $crappyness_value = _remove_crappy_coding_sets( \@set, $tt, $cc__ );

        delete $c__->{$set} if $crappyness_value == 0;

        my $lead_intron = 0;
        my $exit_intron = 0;

        $lead_intron =
          _calculate_intron_flank_size( $tt, $set[0], ( $set[0] ) - 1, 'l' );
        $exit_intron =
          _calculate_intron_flank_size( $tt, $set[0], ( $set[0] ) + 1, 'r' )
          if ${ $tt->get_all_Exons() }[ $set[-1] ]->stable_id() ne
              ${ $tt->get_all_Exons() }[-1]->stable_id();

        if ( ${ $tt->get_all_Exons() }[ $set[-1] ]->stable_id() eq
            ${ $tt->get_all_Exons() }[-1]->stable_id() )
        {

     #print $set, ' ', ${$tt->get_all_Exons() }[ $set[-1] ]->stable_id()  ,"\n";
            delete $c__->{$set} if $lead_intron < 450;
        }
        else {
            delete $c__->{$set} if $lead_intron < 450;
            delete $c__->{$set} if $exit_intron < 450;    #and scalar @set > 1;
        }
    }
}

#                                           #
# Just what it says - called by identify_ko #
#                                           #

sub _remove_crappy_coding_sets {
    my ( $set_, $tt, $ccp__ ) = @_;

    #Get all and coding exons (again!)
    my ( $ae__, $ce__ ) = get_coding_and_all_exons($tt);

    #Get the coding contribution of exons
    my $cc__ = _get_aas_coded($tt);

    #Work out the amount previously coded
    my $number_of_coded_aas = 0;
    for ( keys %$ae__ ) {
        last
          if $ae__->{$_}->stable_id() eq
              ${ $tt->get_all_Exons() }[ $set_->[0] ]->stable_id();
        if ( exists $ce__->{ $ae__->{$_}->stable_id() } ) {
            $number_of_coded_aas += $cc__->{ $ae__->{$_}->stable_id };
        }
    }

    my $pct_coded = 0;
    for (@$set_) {
        $pct_coded += $ccp__->{ ${ $tt->get_all_Exons() }[$_]->stable_id() };
    }

    #Get at the phases.
    my $phases_match = 0;
    my $start_phase  = 99;    #We won't see these in the wild - we will see 0
    my $end_phase    = 99;

    $end_phase = ${ $tt->get_all_Exons() }[ $set_->[-1] ]->end_phase();
    $start_phase = ${ $tt->get_all_Exons() }[ ( $set_->[0] - 1 ) ]->end_phase();

    if ( $start_phase == $end_phase ) { $phases_match = 1 }

    my $span = 0;
    $span =
      abs( ${ $tt->get_all_Exons }[ $set_->[0] ]->start() -
          ${ $tt->get_all_Exons }[ $set_->[-1] ]->end() ) + 1;

    if ( $span > 3500 ) {

        #print "Failed too long: @{$set_}\n";
        return 0;
    }

    if ( !$phases_match and $number_of_coded_aas >= 35 ) {

#print "PHASES DON'T MATCH ( $phases_match ) - # OF aas: $number_of_coded_aas\n";
        return 1;
    }

    if ($phases_match) {

        #print "Failed PHASES MATCH: @{$set_}\n";
        return 0;
    }

    if ( $pct_coded > 50 ) {

        #print "PCT CODED:  $pct_coded\n";
        return 1;
    }    # and $span;

    if (
        $number_of_coded_aas >= 35
        and ( ${ $tt->get_all_Exons }[ $set_->[0] ]->stable_id() ne
            ${ $tt->get_all_translateable_Exons() }[0]->stable_id() )
      )
    {

        #print "MEH!\n";
        return 1;
    }
    return 0;
}

#                                                             #
# Get the number of amino acids coded by each of the exons    #
#                                                             #

sub _get_aas_coded {
    my ($transcript) = @_;
    my $protein_length =
      ( ( length $transcript->translateable_seq() ) / 3 ) - 1;
    my %contributions =
      map { $_->stable_id() => _get_aa_count( $protein_length, $_ ) }
      @{ $transcript->get_all_translateable_Exons() };
    return ( \%contributions );
}

#                                                  #
# Calculate the % of the protein coded by the exon #
# Called by get_aas_coded                          #
#                                                  #

sub _get_aa_count {
    my ( $pl, $e ) = @_;
    my $nts = ( abs( $e->start() - $e->end() ) + 1 );
    my $pc  = int( $nts / 3 );
}

#                                                  #
# Get the all the exons and coding exons mapped    #
# to tied hashes for convenience                   #
#                                                  #

sub get_coding_and_all_exons {
    my ($tt) = @_;
    tie my %coding_exons, 'Tie::IxHash';
    tie my %all_exons,    'Tie::IxHash';
    %coding_exons =
      map { $_->stable_id() => $_ } @{ $tt->get_all_translateable_Exons() };
    %all_exons = map { $_->stable_id() => $_ } @{ $tt->get_all_Exons() };

    return ( \%all_exons, \%coding_exons );
}

=head2

Method for generating target exons for domain allele

=cut

sub domain : Local {
    my ( $self, $ctx, $ensembl_id, $domain_db ) = @_;

    #####################################################################
    #                                                                   #
    # INITIAL DETAILS:                                                  #
    #                                                                   #
    # Targets are the on holds and conditional design not possible      #
    # Max target length = 3500                                          #
    # Must consume 30% or more of the protein                           #
    # Must kill 50% of a domain                                         #
    # Minimum intron length is 450                                      #
    #                                                                   #
    # PROTEIN DATABASES                                                 #
    # 1. PFAM DOMAINS                                                   #
    # 2. InterPro -> contains PFAM                                      #
    # 3. UniProt  -> this is place of choice                            #
    #                                                                   #
    #####################################################################
    #####################################################################
    # Key:                                                              #
    # $var   = scalar                                                   #
    # $var_  = ref to array                                             #
    # $var__ = ref to hash                                              #
    # _some_sub = A subroutine called by another subroutine             #
    #####################################################################

    my $gene_adaptor = HTGT::Utils::EnsEMBL->gene_adaptor
      or die "Failed to get gene adaptor\n";
    my $dbh = HTGT::Utils::EnsEMBL->db_adaptor
      or die "Failed to get the DBAdaptor!\n";

    #
    # Test gene: PCBP2 - ENSMUSG00000056851
    #

    my %datasource = (
        genscan     => 'enscan',
        pirsf       => 'pirsf',
        pfam        => 'pfam',
        prints      => 'prints',
        rfamblast   => 'rfamblast',
        smart       => 'smart',
        superfamily => 'superfamily',
        trf         => 'trf',
        Unigene     => 'unigene',
        havana      => 'havana',
        pfscan      => 'pfscan',
        scanprosite => 'scanprosite',
        tmhmm       => 'tmhmm',
        everything  => 'everything',
    );

    if ( !exists $datasource{$domain_db} ) {
        $ctx->log->error("No datasource for domain_db: '$domain_db'");
        return;
    }

    #print "TARGET:$ensembl_id DOM_DB:$domain_db\n";

    # Get the gene.
    my $gene = get_gene_object( $gene_adaptor, $ensembl_id );

    # Get the longest transcript
    my $template_transcript = get_longest_transcript($gene);
    die "Failed to get transcript!\n" if !defined $template_transcript;

    # Translate to a protein
    my $template_protein = $template_transcript->translation()
      or die "!!! $ensembl_id !!!"
      ;    #Something odd going on here! Not using chromosomes?
    die "Failed to translate!\n" if !defined $template_protein;

    # Grab ALL protein feature - will include SNPs
    my @protein_features = @{ $template_protein->get_all_ProteinFeatures() };

    # Get the domain features - PFAM, interpro etc
    my @domain_features = @{ $template_protein->get_all_DomainFeatures() };

    # Get a set of the domains that we want to use in designs
    my ( $domains__, $DOMAIN_LOOKUP ) =
      get_domain_definitions( \@domain_features, $domain_db );

    #Get the contribution of each exon to the protein sequence
    my $coding_contributions__ = get_coding_contributions($template_transcript);

    #Get a list of all possible exon combinations
    my $combinations__ =
      get_power_sets( $template_transcript, $coding_contributions__ );

#There are some combinations that can never be attempted and so don't get a score at all
    remove_impossible_flank_sizes_and_long_combinations( $combinations__,
        $template_transcript );

    #Validate a knockout based on the domain definition
    my ($dom_ko__) =
      validate_domain_ko( $combinations__, $domains__, $template_transcript );

    #One characteristic ugly block to finish off the script.

    format_for_automatic_design( $ctx, $dom_ko__, $template_transcript,
        $DOMAIN_LOOKUP, $ensembl_id );
}

#####################################################################
#                                                                   #
#                           THE SUBROUTINES                         #
#                                                                   #
#####################################################################
#                                               #
# Complete the format for the automatic designs #
#                                               #
sub format_for_automatic_design {
    my ( $ctx, $dom_ko__, $template_transcript, $DOMAIN_LOOKUP, $ensembl_id ) =
      @_;

    my %u = ();

    my @targets;    # return value

    for my $k ( keys %$dom_ko__ ) {
        my ( $set, $domain ) = split /:/, $k;
        my @set = split /\s+/, $set;

        #Get the domain name - this is the ID that Alejo would like
        #print "DOMAIN: ", $domain, "\n";
        my ( $displayed_domain_name, $method ) = _get_domain_info($domain);

        my $left_flank =
          _calculate_intron_flank_size( $template_transcript, $set[0],
            ( $set[0] ) - 1, 'l' );
        my $right_flank =
          _calculate_intron_flank_size( $template_transcript, $set[-1],
            ( $set[-1] ) + 1, 'r' );
        my $span =
          5000 -
          abs( ${ $template_transcript->get_all_Exons() }[ $set[0] ]->start() -
              ${ $template_transcript->get_all_Exons() }[ $set[-1] ]->end() );

        if ( $left_flank >= 700 )  { $left_flank  = 700 }
        if ( $right_flank >= 700 ) { $right_flank = 700 }

        my @l_defaults = ( 120, 60, 300 );
        my @r_defaults = ( 120, 60, 100 );
        my $chrom_start = 0;
        my $chrom_end   = 0;

        my $strand = $template_transcript->transform('chromosome')->strand();

        for my $l ( keys %{ $dom_ko__->{$k} } ) {
            my @set = split /\s+/, $l;

 #                                                                             #
 # Weight the left and right flank and the overall length (span) of the design #
 #                                                                             #
            my $score = sprintf(
                "%.3f",
                (
                    $left_flank +
                      $right_flank + $span +
                      ${ $dom_ko__->{$k} }{$l}
                  ) / 6500
            );

            if ( $strand == 1 ) {
                $chrom_start =
                  ${ $template_transcript->get_all_Exons() }[ $set[0] ]
                  ->transform('chromosome')->start();
                $chrom_end =
                  ${ $template_transcript->get_all_Exons() }[ $set[-1] ]
                  ->transform('chromosome')->end();
            }
            elsif ( $strand == -1 ) {
                $chrom_start =
                  ${ $template_transcript->get_all_Exons() }[ $set[-1] ]
                  ->transform('chromosome')->start();
                $chrom_end =
                  ${ $template_transcript->get_all_Exons() }[ $set[0] ]
                  ->transform('chromosome')->end();
            }
            else {
                die
"There is one hell of an error in your code! Strand == ***$strand***\n";
            }

            if ( $left_flank < 700 ) {
                _readjust( $left_flank, \@l_defaults );
            }
            if ( $right_flank < 700 ) {
                _readjust( $right_flank, \@r_defaults );
            }

            my $string =
              "$ensembl_id "
              . ${ $template_transcript->get_all_Exons() }[ $set[0] ]
              ->transform('chromosome')->stable_id() . " "
              . ${ $template_transcript->get_all_Exons() }[ $set[-1] ]
              ->transform('chromosome')->stable_id() . " "
              . $chrom_start . " "
              . $chrom_end . " "
              . join( " ", @l_defaults ) . " "
              . join( " ", @r_defaults ) . " ("
              . $DOMAIN_LOOKUP->{$domain}->idesc
              . ":$displayed_domain_name:$score)";

            ######
            # return value
            #re-format the param
            my @l_param;
            my @r_param;

            foreach my $l_para (@l_defaults) {
                push @l_param, $l_para;
            }

            foreach my $r_para (@r_defaults) {
                push @r_param, $r_para;
            }

            my $target;
            $target->{ams} = $ensembl_id;
            $target->{start_exon} =
              ${ $template_transcript->get_all_Exons() }[ $set[0] ]
              ->transform('chromosome')->stable_id();
            $target->{end_exon} =
              ${ $template_transcript->get_all_Exons() }[ $set[-1] ]
              ->transform('chromosome')->stable_id();
            $target->{target_start}          = $chrom_start;
            $target->{target_end}            = $chrom_end;
            $target->{l_param}               = \@l_param;
            $target->{r_param}               = \@r_param;
            $target->{score}                 = $score;
            $target->{domain}                = $DOMAIN_LOOKUP->{$domain}->idesc;
            $target->{displayed_domain_name} = $displayed_domain_name;

            push @targets, $target;

            ######
#print "'", $DOMAIN_LOOKUP->{$domain}->idesc, "' ", $DOMAIN_LOOKUP->{$domain}->interpro_ac, "\n";
            if ( !$u{"$chrom_start:$chrom_end:$displayed_domain_name"} ) {
                $u{"$chrom_start:$chrom_end:$displayed_domain_name"} = $string;
            }
        }
    }

    for ( keys %u ) {
        $ctx->log->debug("$u{$_}\n");
    }

    return \@targets;
}

##### MOVE THIS INTO ITS OWN SPACE #####
# Have had to change this to support the web front end.
sub _get_domain_info {
    my ($dom) = @_;
    my $domain_name;
    my $dbh = DBI->connect( 'dbi:mysql:mus_musculus_core_47_37:ensembldb',
        'anonymous', '', { RaiseError => 1 } )
      or die "oops, an error occured!\n";

#my $get_domain_id = "select hit_id from protein_feature where protein_feature_id = ?";
#my $get_domain_id = "select hit_name from protein_feature where protein_feature_id = ?";
    my $get_domain_id = "
                    select protein_feature.hit_id, analysis_description.display_label 
                    from protein_feature
                    join analysis_description on analysis_description.analysis_id = protein_feature.analysis_id
                    where protein_feature_id = ?
                    ";

    my $gdi = $dbh->prepare($get_domain_id);
    $gdi->execute($dom);
    my $names = $gdi->fetchall_arrayref();
    return ( $names->[0][0], $names->[0][1] );
}

#                                                                 #
# This determines how much of a domain each critical set overlaps #
#                                                                 #
sub validate_domain_ko {
    my ( $c__, $d__, $tt ) = @_;
    my $coding_start =
      ${ $tt->get_all_translateable_Exons() }[0]->cdna_start($tt);
    my %domain_overlap = ();

    for my $domain ( keys %$d__ ) {
        my @dom       = @{ $d__->{$domain} };
        my $dom_start = $dom[0];
        my $dom_end   = $dom[1];

        for my $set ( keys %$c__ ) {
            my @set = split /\s+/, $set;
            my @exons = @{ $c__->{$set} };

            my $start_point = $exons[0]->cdna_coding_start($tt);
            my $end_point   = $exons[-1]->cdna_coding_end($tt);

            $start_point = abs( $coding_start - $start_point );
            $end_point   = abs( $coding_start - $end_point )
              ;    #for some reason this was $start_point !!!
            my $koed = 0;    #The variable to store the amount koed.

            if ( $start_point <= $dom_start and $end_point >= $dom_end ) {

                #rock on - we got the whole domain !!!
                $koed = 100;
            }
            elsif ( $start_point >= $dom_start and $end_point <= $dom_end ) {

                #Calculate %
                my $dom_len = abs( $dom_start - $dom_end );
                my $len     = abs( $start_point - $end_point );
                $koed = ( $len / $dom_len ) * 100;
            }
            elsif ( ( $start_point >= $dom_start and $start_point < $dom_end )
                and $end_point >= $dom_end )
            {
                my $koed = abs( $start_point - $dom_end );
                $koed = ( $koed / ( abs( $dom_end - $dom_start ) ) ) * 100;
            }
            elsif (
                $start_point <= $dom_start
                and (   ( $end_point > $dom_start )
                    and ( $end_point < $dom_end ) )
              )
            {
                my $overlap = abs( $start_point - $dom_start );
                my $len     = $end_point - ( $start_point + $overlap );
                my $dom_len = abs( $dom_start - $dom_end );
                $koed = ( $len / $dom_len ) * 100;

                #print "$set $koed $dom_start $dom_end\n";
            }
            else {

# !!! THERE IS NOTHING TO HIT !!!
#print  "#Domain Start: $dom_start Domain End: $dom_end \tCODE start: $start_point CODE end: $end_point\n";
                next;
            }
            if ( $koed > 40 ) {
                $domain_overlap{"$set:$domain"}{$set} = $koed;
            }
        }
    }
    return ( \%domain_overlap );
}

#                                                                                    #
# Remove combination where the flanking exons are short or the construct is too long #
#                                                                                    #
sub remove_impossible_flank_sizes_and_long_combinations {
    my ( $combinations__, $template_transcript ) = @_;
    foreach my $combination ( keys %$combinations__ ) {
        my @all_exons = @{ $template_transcript->get_all_Exons() };
        my @list      = @{ $combinations__->{$combination} };
        my @comb      = split /\s+/, $combination;

        my $left_flank =
          _calculate_intron_flank_size( $template_transcript, $comb[0],
            ( $comb[0] ) - 1, 'l' );
        my $right_flank =
          _calculate_intron_flank_size( $template_transcript, $comb[-1],
            ( $comb[-1] ) + 1, 'r' );

        if ( $left_flank < 450 or $right_flank < 450 ) {
            delete $combinations__->{$combination};
        }

        my $span =
          abs( ${ $template_transcript->get_all_Exons() }[ $comb[0] ]->start() -
              ${ $template_transcript->get_all_Exons() }[ $comb[-1] ]->end() );
        if ( $span > 3500 ) {
            delete $combinations__->{$combination};
        }
    }
}

## Please see file perltidy.ERR
## Please see file perltidy.ERR
#                                             #
# Do the calculation of flanking intron sizes #
#                                             #
sub _calculate_intron_flank_size {
    my ( $tt, $c_number, $o_number, $switch ) =
      @_;    #o_number is the next or previous exon number
    my $ces =
      ${ $tt->get_all_Exons() }[$c_number]->start;    # The current exon start;
    my $cee =
      ${ $tt->get_all_Exons() }[$c_number]->end;      # The current exon start;
    my $oes =
      ${ $tt->get_all_Exons() }[$o_number]->start();   # The current exon start;
    my $oee =
      ${ $tt->get_all_Exons() }[$o_number]->end();     # The current exon start;

    my $length = 0;

    if ( $switch eq 'l' ) {
        $length = abs( $ces - $oee ) - 1;
    }
    elsif ( $switch eq 'r' ) {
        $length = abs( $cee - $oes ) - 1;
    }
    else {
        die
"Switch '$switch' isn't valid (in function /* _calculate_intron_flank_size *\ \n";
    }
    return ($length);
}

#                                          #
# Create the potential power-sets of exons #
#                                          #
sub get_power_sets {
    my ( $template_transcript, $chash ) = @_;
    my @t = @{ $template_transcript->get_all_Exons() };

    tie my %ce_nts, 'Tie::IxHash';
    %ce_nts =
      map { $_->stable_id() => abs( $_->start() - $_->end() ) + 1 }
      @{ $template_transcript->get_all_translateable_Exons() };

    my @list         = 0 .. $#t;
    my %combinations = ();
    foreach my $start ( 0 .. $#list ) {
        foreach my $end ( $start .. $#list ) {
            my @sublist = @list[ $start .. $end ];

#print "@sublist (",   _ko_thirty_pct( \@sublist, \@t, $chash ), " " .  _begin_and_end_code( \@sublist, \@t, $chash ), ")\n";
# // DON'T DELETE THE NEXT LINE \\ #
            if (    _ko_thirty_pct( \@sublist, \@t, $chash )
                and _begin_and_end_code( \@sublist, \@t, $chash ) )
            {

                #if ( _begin_and_end_code( \@sublist, \@t, $chash ) ) {
                my $k = join( " ", @sublist );
                for (@sublist) {
                    push @{ $combinations{$k} },
                      $template_transcript->get_all_Exons()->[$_];
                }
            }
        }
    }
    return ( \%combinations );
}

#                                                                    #
# Check that the critical set codes for more than 30% of the protein #
#                                                                    #
sub _ko_thirty_pct {
    my ( $c_, $t_, $chash__ ) = @_;
    my $amount_ko = 0;

    #print "@$c_\n";
    for my $i (@$c_) {

        #print "$i -> ";
        my $e = $t_->[$i];
        if ( exists $chash__->{ $e->stable_id() } ) {

            #print $chash__->{ $e->stable_id() }, "\n";
            $amount_ko += $chash__->{ $e->stable_id() };
        }
    }
    return (1) if $amount_ko >= 30;
    return (0);
}

#                                          #
# Check that the first and last exons code #
#                                          #
sub _begin_and_end_code {
    my ( $c_, $t_, $chash__ ) = @_;
    my $f = $t_->[ $c_->[0] ];
    my $l = $t_->[ $c_->[-1] ];
    return (0)
      if $c_->[0] == 0
    ;  # Can't take the first exon even if it does code - there won't be an exon
    return (0) if $c_->[-1] == ( scalar @$t_ ) - 1;
    if (    exists $chash__->{ $f->stable_id() }
        and exists $chash__->{ $l->stable_id() } )
    {
        return (1);
    }
    else {
        return (0);
    }
}

#                                           #
# Get the coding contribution of each exon  #
#                                           #
sub get_coding_contributions {
    my ($transcript) = @_;
    my $protein_length =
      ( ( length $transcript->translateable_seq() ) / 3 ) - 1;
    my %contributions = map {
        $_->stable_id() => _pct_protein_contribution( $protein_length, $_ )
    } @{ $transcript->get_all_translateable_Exons() };
    my $sum = 0;
    return ( \%contributions );
}

#                                                  #
# Calculate the % of the protein coded by the exon #
# Called by get_coding_contributions               #
#                                                  #
sub _pct_protein_contribution {
    my ( $pl, $e ) = @_;
    my $nts = ( abs( $e->start() - $e->end() ) + 1 );
    my $pc  = ( int( $nts / 3 ) / $pl ) * 100;
}

#                                        #
# Get the longest example of each domain #
# THIS METHOD IS INCOMPLETE              #
#                                        #
sub get_domain_definitions {
    my ( $domains_, $dom_db ) = @_;

    my $dbh = DBI->connect( 'dbi:mysql:mus_musculus_core_51_37d:ens-livemirror',
        'ensro', '', { RaiseError => 1 } )
      or die "oops, an error occured!\n";

    my $sql = (
        q/
                   select display_label
                   from protein_feature, analysis_description
                   where protein_feature_id = ? and protein_feature.analysis_id = analysis_description.analysis_id;
                   /
    );

#my $get_domain_id = (q/
#                     select protein_feature_id from protein_feature where protein_feature_id = (?);
#                     /);

    my %domains = ();

    my %domainObjects = ();

    for ( my $i = 0 ; $i < @$domains_ ; $i++ ) {
        my $d = $domains_->[$i];

        #print $d->idesc, " -> ", $d->interpro_ac, " " , $d->dbID, "\n";
        my $sql_exe = $dbh->prepare($sql);
        $sql_exe->execute( $d->dbID() );

        my $feature_source = $sql_exe->fetchall_arrayref();

        if (   $feature_source->[0][0] =~ /$dom_db/i
            or $dom_db =~ /everything/i )
        {
            my $cdna_start = $d->start * 3;
            my $cdna_end   = $d->end * 3;
            $domains{ $d->dbID } = [ $cdna_start, $cdna_end ];
            $domainObjects{ $d->dbID } = $d;
        }
    }
    return ( \%domains, \%domainObjects );
    $dbh->disconnect();
}

#                               #
# Get a gene on a feature slice #
#                               #
sub get_longest_transcript {
    my ($gene_object)   = @_;
    my @transcripts     = @{ $gene_object->get_all_Transcripts() };
    my $transcript      = '';
    my $longest_protein = 0;

    for ( my $i = 0 ; $i < @transcripts ; $i++ ) {
        my $protein_length =
          ( ( length $transcripts[$i]->translateable_seq() ) / 3 ) - 1;
        if ( $protein_length > $longest_protein ) {
            $longest_protein = $protein_length;
            $transcript      = $transcripts[$i];
        }
    }
    return ($transcript) if defined $transcript;
    die "A transcript could not be defined for ", $gene_object->stable_id(),
      "\n";
}

#                               #
# Get a gene on a feature slice #
#                               #
sub get_gene_object {
    my ( $ga, $ens_id ) = @_;
    my $gene = $ga->fetch_by_stable_id($ens_id);
    die "$ens_id cannot be found - please check manually!\n"
      if !defined $gene;
    return ( $gene = $gene->transfer( $gene->feature_Slice() ) );
}

=head1 AUTHOR

Wanjuan Yang

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
