package Kermits;

use Moose;

use KermitsDB;
use Tie::IxHash;
use Math::Round qw(:all);
use DateTime;

##
## Configurable Attributes...
##

has c => ( is => 'rw', required => 1 );

##
## Non-Configurable Attributes...
##

has dbh                               => ( is => 'ro', lazy => 1, builder => '_build_dbh' );
has schema                            => ( is => 'ro', lazy => 1, builder => '_build_schema' );
has htgt_dbh                          => ( is => 'ro', lazy => 1, builder => '_build_htgt_dbh' );
has htgt_schema                       => ( is => 'ro', lazy => 1, builder => '_build_htgt_schema' );
has microinjections                   => ( is => 'ro', lazy => 1, builder => '_build_microinjections' );
has microinjections_by_project        => ( is => 'ro', lazy => 1, builder => '_build_microinjections_by_project' );
has microinjections_by_centre         => ( is => 'ro', lazy => 1, builder => '_build_microinjections_by_centre' );
has microinjections_by_project_centre => ( is => 'ro', lazy => 1, builder => '_build_microinjections_by_project_centre' );

##
## Builder Methods...
##

sub _build_dbh {
  my $self = shift;
  return $self->schema->storage->dbh();
}

sub _build_schema {
  my $self = shift;
  return $self->c->model('KermitsDB');
}

sub _build_htgt_dbh {
  my $self = shift;
  return $self->htgt_schema->storage->dbh();
}

sub _build_htgt_schema {
  my $self = shift;
  return $self->c->model('HTGTDB');
}

sub _build_microinjections {
  my $self = shift;

  my $mi_data_a_ref = [];

  # Fetch ALL microinjection data from Kermits...
  my $mi_rs = $self->schema->resultset('EmiAttempt')->search(
    {},
    {
      prefetch => { 'event' => [ 'centre', { 'clone' => 'pipeline' } ] },
      order_by => { -asc => 'me.actual_mi_date' }
    }
  );

  while ( my $mi = $mi_rs->next ) { push( @{$mi_data_a_ref}, $mi ); }
  return $mi_data_a_ref;
}

sub _build_microinjections_by_project {
  my $self = shift;

  my $mi_by_project_ha_ref = {};

  foreach my $mi ( @{ $self->microinjections } ) {
    
    #Flush all UCD-based MI's for EUCOMM projects
    if($mi->event->clone->pipeline->name eq 'EUCOMM' && $mi->event->centre->name eq 'UCD'){ next; }
    
    push( @{ $mi_by_project_ha_ref->{ $mi->event->clone->pipeline->name } }, $mi );
  }

  return $mi_by_project_ha_ref;
}

sub _build_microinjections_by_centre {
  my $self = shift;

  my $mi_by_centre_ha_ref = {};

  foreach my $mi ( @{ $self->microinjections } ) {
    push( @{ $mi_by_centre_ha_ref->{ $mi->event->centre->name } }, $mi );
  }

  return $mi_by_centre_ha_ref;
}

sub _build_microinjections_by_project_centre {
  my $self = shift;

  my $mi_by_project_ha_ref         = $self->microinjections_by_project;
  my $mi_by_project_centre_hha_ref = {};

  foreach my $project ( keys %{$mi_by_project_ha_ref} ) {
    foreach my $mi ( @{ $mi_by_project_ha_ref->{$project} } ) {
      push( @{ $mi_by_project_centre_hha_ref->{$project}->{ $mi->event->centre->name } }, $mi );
    }
  }

  return $mi_by_project_centre_hha_ref;
}

##
## General Methods
##

sub microinjections_detailed {
  my ( $self, $params ) = @_;

  # Get all microinjection data defined by the params
  my $attempts_a_ref = [];
  if ( $params->{centre} ) {
    if   ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project_centre->{ $params->{project} }->{ $params->{centre} }; }
    else                        { $attempts_a_ref = $self->microinjections_by_centre->{ $params->{centre} }; }
  }
  elsif ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project->{ $params->{project} }; }
  else                         { $attempts_a_ref = $self->microinjections; }

  # Store the info for display in an array of hashes
  my $attempt_data_ah_ref = [];
  
  # Get all of the allele names for our clones...
  my $clone_allele_names_h_ref = $self->get_all_allele_names();

  foreach my $a ( @{$attempts_a_ref} ) {

    my $percent_pups_born = undef;
    if ( defined $a->number_born and $a->num_blasts and $a->num_blasts > 0 ) { $percent_pups_born = round( ( $a->number_born / $a->num_blasts ) * 100 ); }
    elsif ( defined $a->num_blasts and $a->num_blasts == 0 ) { $percent_pups_born = 0; }

    my $percent_total_chimeras = undef;
    if ( defined $a->total_chimeras and $a->number_born and $a->number_born > 0 ) { $percent_total_chimeras = round( ( $a->total_chimeras / $a->number_born ) * 100 ); }
    elsif ( defined $a->number_born and $a->number_born == 0 ) { $percent_total_chimeras = 0; }

    my $percent_male_chimeras = undef;
    if ( defined $a->number_male_chimeras and $a->total_chimeras and $a->total_chimeras > 0 ) { $percent_male_chimeras = round( ( $a->number_male_chimeras / $a->total_chimeras ) * 100 ); }
    elsif ( defined $a->total_chimeras and $a->total_chimeras == 0 ) { $percent_male_chimeras = 0; }

    my $percent_chimeras_with_glt = undef;
    my $max_glt ;
    my $sum_chimeras_by_cct_bins;

    
    if($a->chimeras_with_glt_from_cct){
      $sum_chimeras_by_cct_bins = $a->chimeras_with_glt_from_cct;
    }else{
      if(defined($a->number_lt_10_percent_glt)){
        $sum_chimeras_by_cct_bins =
          $a->number_lt_10_percent_glt + $a->number_btw_10_50_percent_glt +
          $a->number_gt_50_percent_glt + $a->number_100_percent_glt;
      }     
    }
    
    if($a->chimeras_with_glt_from_genotyp && $sum_chimeras_by_cct_bins){
      if($a->chimeras_with_glt_from_genotyp > $sum_chimeras_by_cct_bins){
        $max_glt = $a->chimeras_with_glt_from_genotyp;
      }else{
        $max_glt = $sum_chimeras_by_cct_bins;
      }
    }elsif($a->chimeras_with_glt_from_genotyp){
      $max_glt = $a->chimeras_with_glt_from_genotyp;
    }else{
      $max_glt = $sum_chimeras_by_cct_bins;
    }
    
    if ( defined $max_glt and $a->number_male_chimeras and $a->number_male_chimeras > 0 ) { $percent_chimeras_with_glt = round( ( $max_glt / $a->number_male_chimeras ) * 100 ); }
    elsif ( defined $a->number_male_chimeras and $a->number_male_chimeras == 0 ) { $percent_chimeras_with_glt = 0; }

    # 'Tie' the hash so it retains its order - memory/process intensive so only use
    # this when performance isn't an issue...
    tie my %attempt, 'Tie::IxHash';
    %attempt = (
      'Project'                                             => $a->event->clone->pipeline->name,
      'Injection Date'                                      => $self->parse_oracle_date( $a->actual_mi_date ),
      'Clone Name'                                          => $a->event->clone->clone_name,
      'Original Gene Symbol'                                => $a->event->clone->gene_symbol,
      'Allele Gene Symbol'                                  => $clone_allele_names_h_ref->{ $a->event->clone->clone_name }->{allele_gene_sybmol},
      'Allele Designation'                                  => $clone_allele_names_h_ref->{ $a->event->clone->clone_name }->{allele_mutation},
      'ES Cell Line'                                        => $a->event->clone->es_cell_line,
      'ES Cell Strain'                                      => $a->event->clone->es_cell_strain,
      
      'Blastocyst Strain'                                   => $a->blast_strain,
      'Attempt'                                             => $a->attempt_number,
      'Blastocysts Transferred'                             => $a->num_blasts,
      'Pups Born #'                                         => $a->number_born,
      'Pups Born %'                                         => $percent_pups_born,
      'No. Total Chimeras'                                  => $a->total_chimeras,
      'Total Chimeras %'                                    => $percent_total_chimeras,
      'No. Male Chimeras'                                   => $a->number_male_chimeras,
      'Male Chimeras %'                                     => $percent_male_chimeras,
      'No. Female Chimeras'                                 => $a->number_female_chimeras,
      'No. Male Chimeras/Coat Colour < 40%'                 => $a->number_male_lt_40_percent,
      'No. Male Chimeras/Coat Colour 40-80%'                => $a->number_male_40_to_80_percent,
      'No. Male Chimeras/Coat Colour >80%'                  => $a->number_male_gt_80_percent,
      'No. Male Chimeras/Coat Colour 100%'                  => $a->number_male_100_percent,
      'Test Cross Strain'                                   => $a->test_cross_strain,
      'No. Chimeras Set Up'                                 => $a->number_chimera_mated,
      'Chimeras / < 10% GLT'                                => $a->number_lt_10_percent_glt,
      'Chimeras / 10-50% GLT'                               => $a->number_btw_10_50_percent_glt,
      'Chimeras / > 50% GLT'                                => $a->number_gt_50_percent_glt,
      'Chimeras / 100% GLT'                                 => $a->number_100_percent_glt,
      'No. Chimeras With Coat Colour Transmission'          => $sum_chimeras_by_cct_bins,
      'No. Coat Colour offspring'                           => $a->number_with_cct,
      'No. Chimeras With Genotype-Confirmed Transmission'   => $a->chimeras_with_glt_from_genotyp,
      'No. Heterozygous offspring'                          => $a->number_het_offspring,
      'Chimeras With GLT %'                                 => $percent_chimeras_with_glt,
      'Colony Name'                                         => $a->colony_name,
      'Europhenome'                                         => $a->europhenome,
      'EMMA Repository'                                     => $a->emma,
      'MMRRC Repository'                                    => $a->mmrrc,
      'Comments'                                            => $a->comments
    );

    # To remove the pesky A07 etc wells - unless they have glt
    next if ($a->event->clone->clone_name =~ /^[A-Z]{1}\d{2}/
        && ( $max_glt || 0 ) < 1 && ( $a->chimeras_with_glt_from_genotyp || 0 ) < 1 && ( $a->chimeras_with_glt_from_cct || 0 ) < 1);
    
    push( @{$attempt_data_ah_ref}, \%attempt );

  }

  return $attempt_data_ah_ref;
}

sub microinjections_overview {
  my ( $self, $params ) = @_;

  # Get all microinjection data defined by the params
  my $attempts_a_ref = [];
  if ( $params->{centre} ) {
    if   ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project_centre->{ $params->{project} }->{ $params->{centre} }; }
    else                        { $attempts_a_ref = $self->microinjections_by_centre->{ $params->{centre} }; }
  }
  elsif ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project->{ $params->{project} }; }
  else                         { $attempts_a_ref = $self->microinjections; }

  # First sort the mi attempts into groups by thier month/year
  tie my %attempts_by_month, 'Tie::IxHash';
  foreach my $a ( @{$attempts_a_ref} ) {
    my $mi_date = $self->parse_oracle_date( $a->actual_mi_date );
    push( @{ $attempts_by_month{ $mi_date->month_abbr . '-' . $mi_date->year } }, $a );
  }

  # Now calculate the info we want...
  my $summary_by_month_ah_ref = [];
  foreach my $month ( keys %attempts_by_month ) {
    tie my %summary, 'Tie::IxHash';
    $summary{'Centre'} = $params->{pretty_name} ? $params->{pretty_name} : $params->{centre};
    $summary{'Month Injected'} = $month;

    # Work out a datetime object for the injection date...
    $month =~ /(\w{3})-(\d{4})/;
    my $m              = "\U$1";
    my $y              = substr( $2, 2 );
    my $injection_date = $self->parse_oracle_date( '01-' . $m . '-' . $y );
    my $todays_date    = DateTime->now();

    # counters
    my $clone_counts = {
      injected            => {},
      at_birth            => {},
      at_weaning          => {},
      set_up              => {},
      transmitting        => {},
      testcross_completed => {}
    };

    foreach my $a ( @{ $attempts_by_month{$month} } ) {

      # Increment the mi counter by one
      $clone_counts->{injected}->{ $a->event->clone->clone_name }++;

      # Is this attempt at birth?
      if ( defined $a->number_born and $a->number_born > 0 ) { $clone_counts->{at_birth}->{ $a->event->clone->clone_name }++; }

      # Male Chimeras? (ref: at weaning)
      if ( defined $a->number_male_chimeras and $a->number_male_chimeras > 0 ) { $clone_counts->{at_weaning}->{ $a->event->clone->clone_name }++; }

      # GLT?
      #if ( defined $a->number_with_glt and $a->number_with_glt > 0 ) { $clone_counts->{transmitting}->{ $a->event->clone->clone_name }++; }
      if(
         $a->chimeras_with_glt_from_cct || $a->chimeras_with_glt_from_genotyp || $a->number_lt_10_percent_glt ||
         $a->number_btw_10_50_percent_glt || $a->number_gt_50_percent_glt || $a->number_100_percent_glt ||
         $a->number_with_cct || $a->number_het_offspring
      ){
        $clone_counts->{transmitting}->{ $a->event->clone->clone_name }++;
      }

      # Test-cross completed?
      my $date_delta = $todays_date->subtract_datetime($injection_date);
      if ( ( $date_delta->months > 4 ) or ( $date_delta->years > 0 ) ) {
        $clone_counts->{testcross_completed}->{ $a->event->clone->clone_name }++;
      }
      
      # Genotype confirmation?
      if($a->event->centre->name eq 'WTSI'){
        if ( (defined $a->number_het_offspring) and ($a->number_het_offspring >= 2) ) {
          $clone_counts->{genotype_confirmed}->{ $a->event->clone->clone_name }++;
        }
      }else{
        if (
            (defined $a->number_het_offspring and $a->number_het_offspring > 0) ||
            (defined $a->chimeras_with_glt_from_genotyp and $a->chimeras_with_glt_from_genotyp > 0)
        ) {
          $clone_counts->{genotype_confirmed}->{ $a->event->clone->clone_name }++;
        }
      }
      
      # Mouse Available?
      if ( defined $a->number_het_offspring and $a->number_het_offspring > 4 ) { $clone_counts->{mouse_available}->{ $a->event->clone->clone_name }++; }

    }

    my $num_clones_injected            = scalar( keys %{ $clone_counts->{injected} } );
    my $num_clones_at_birth            = scalar( keys %{ $clone_counts->{at_birth} } );
    my $num_clones_at_weaning          = scalar( keys %{ $clone_counts->{at_weaning} } );
    my $num_clones_set_up              = scalar( keys %{ $clone_counts->{set_up} } );
    my $num_clones_transmitting        = scalar( keys %{ $clone_counts->{transmitting} } );
    my $num_clones_testcross_completed = scalar( keys %{ $clone_counts->{testcross_completed} } );
    my $num_clones_genotype_confirmed = scalar( keys %{ $clone_counts->{genotype_confirmed} } );
    my $num_clones_mouse_available = scalar( keys %{ $clone_counts->{mouse_available} } );

    my $percent_of_injected_at_birth = 0;
    if ( $num_clones_at_birth or $num_clones_at_birth == 0 ) { $percent_of_injected_at_birth = round( ( $num_clones_at_birth / $num_clones_injected ) * 100 ); }

    my $percent_of_injected_at_weaning = 0;
    if ( $num_clones_at_weaning or $num_clones_at_weaning == 0 ) {
      $percent_of_injected_at_weaning = round( ( $num_clones_at_weaning / $num_clones_injected ) * 100 );
    }

#my $percent_of_clones_set_up;
#if ( $num_clones_transmitting or $num_clones_transmitting == 0 ) { $percent_of_clones_set_up = round( ( $num_clones_transmitting / $num_clones_set_up ) * 100 ); }

    my $percent_clones_transmitting = 0;
    my $percent_clones_genotype_confirmed = 0;
    my $percent_clones_mouse_available = 0;
    
    if ($num_clones_testcross_completed) {
      $percent_clones_transmitting = round( ( $num_clones_transmitting / $num_clones_testcross_completed ) * 100 );
      $percent_clones_genotype_confirmed = round( ( $num_clones_genotype_confirmed / $num_clones_testcross_completed ) * 100 );
      $percent_clones_mouse_available = round( ( $num_clones_mouse_available / $num_clones_testcross_completed ) * 100 );
    }

    # Finish off our summary hash
    $summary{'# Clones Injected'}          = $num_clones_injected;
    $summary{'# at Birth'}                 = $num_clones_at_birth;
    $summary{'% of Injected (at Birth)'}   = $percent_of_injected_at_birth;
    $summary{'# at Weaning'}               = $num_clones_at_weaning;
    $summary{'% of Injected (at Weaning)'} = $percent_of_injected_at_weaning;

    #$summary{'# Clones Set-Up'}               = $num_clones_set_up;
    $summary{'# Clones Transmitting'} = $num_clones_transmitting;
    $summary{'# Clones Genotype Confirmed'} = $num_clones_genotype_confirmed;

    #$summary{'% of Set-Up'}                   = $percent_of_clones_set_up;
    $summary{'# Clones Test-Cross Completed'} = $num_clones_testcross_completed;
    $summary{'% Clones Transmitting'} = $percent_clones_transmitting;
    $summary{'% Clones Genotype Confirmed'}         = $percent_clones_genotype_confirmed;

    push( @{$summary_by_month_ah_ref}, \%summary );

  }

  return $summary_by_month_ah_ref;
}

sub injected_counts {
  my ( $self, $params ) = @_;

  # Get all microinjection data defined by the params
  my $attempts_a_ref = [];
  if ( $params->{centre} ) {
    if   ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project_centre->{ $params->{project} }->{ $params->{centre} }; }
    else                        { $attempts_a_ref = $self->microinjections_by_centre->{ $params->{centre} }; }
  }
  elsif ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project->{ $params->{project} }; }
  else                         { $attempts_a_ref = $self->microinjections; }

  # If we want to exclude data from the last few months... (i.e. Test-Cross data)
  if ( $params->{month_offset} ) {
    my $today              = DateTime->now();
    my $new_attempts_a_ref = [];

    foreach my $mi ( @{$attempts_a_ref} ) {
      my $mi_date = $self->parse_oracle_date( $mi->actual_mi_date );

      my $date_delta = $today->subtract_datetime($mi_date);
      if ( ( $date_delta->months > $params->{month_offset} ) or ( $date_delta->years > 0 ) ) {
        push( @{$new_attempts_a_ref}, $mi );
      }
    }

    $attempts_a_ref = $new_attempts_a_ref;
  }

  # Counts of all mi's and unique gene's mi'ed
  my $total_count = 0;
  my $uniqe_count = 0;
  if ( $attempts_a_ref ) {
    $total_count = scalar( @{$attempts_a_ref} );
    
    my %unique_genes;
    foreach my $mi ( @{$attempts_a_ref} ) { $unique_genes{ $mi->event->clone->gene_symbol } = 1; }
    $uniqe_count = scalar( keys %unique_genes );
  }
  

  return {
    'count'  => $total_count,
    'unique' => $uniqe_count
  };
}

sub transmitted_counts {
  my ( $self, $params ) = @_;

  # Get all microinjection data defined by the params
  my $attempts_a_ref = [];
  if ( $params->{centre} ) {
    if   ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project_centre->{ $params->{project} }->{ $params->{centre} }; }
    else                        { $attempts_a_ref = $self->microinjections_by_centre->{ $params->{centre} }; }
  }
  elsif ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project->{ $params->{project} }; }
  else                         { $attempts_a_ref = $self->microinjections; }

  my $total_count = 0;
  my $uniqe_count = 0;
  
  if ( $attempts_a_ref ) {
    my %unique_genes;

    foreach my $mi ( @{$attempts_a_ref} ) {
      if ( $mi->chimeras_with_glt_from_cct || $mi->chimeras_with_glt_from_genotyp || $mi->number_with_cct || $mi->number_het_offspring ) {
        $total_count++;
        $unique_genes{ $mi->event->clone->gene_symbol } = 1;
      }
    }

    $uniqe_count = scalar( keys %unique_genes );
  }

  return {
    'count'  => $total_count,
    'unique' => $uniqe_count
  };
}

sub genotype_confirmed_counts {
  my ( $self, $params ) = @_;

  # Get all microinjection data defined by the params
  my $attempts_a_ref = [];
  if ( $params->{centre} ) {
    if   ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project_centre->{ $params->{project} }->{ $params->{centre} }; }
    else                        { $attempts_a_ref = $self->microinjections_by_centre->{ $params->{centre} }; }
  }
  elsif ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project->{ $params->{project} }; }
  else                         { $attempts_a_ref = $self->microinjections; }

  my $total_count = 0;
  my $uniqe_count = 0;
  
  if ( $attempts_a_ref ) {
    my %unique_genes;

    foreach my $mi ( @{$attempts_a_ref} ) {
      if($mi->event->centre->name eq 'WTSI'){
        if (
            ($mi->number_het_offspring) && ($mi->number_het_offspring >= 2)
        ) {
          $total_count++;
          $unique_genes{ $mi->event->clone->gene_symbol } = 1;
        }
      }else{
        if (
            (($mi->number_het_offspring) && ($mi->number_het_offspring > 0)) ||
            (($mi->chimeras_with_glt_from_genotyp) && ($mi->chimeras_with_glt_from_genotyp >0) )
        ) {
          $total_count++;
          $unique_genes{ $mi->event->clone->gene_symbol } = 1;
        }
      }
    }

    $uniqe_count = scalar( keys %unique_genes );
  }

  return {
    'count'  => $total_count,
    'unique' => $uniqe_count
  };
}

sub mice_available_counts {
  my ( $self, $params ) = @_;

  # Get all microinjection data defined by the params
  my $attempts_a_ref = [];
  if ( $params->{centre} ) {
    if   ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project_centre->{ $params->{project} }->{ $params->{centre} }; }
    else                        { $attempts_a_ref = $self->microinjections_by_centre->{ $params->{centre} }; }
  }
  elsif ( $params->{project} ) { $attempts_a_ref = $self->microinjections_by_project->{ $params->{project} }; }
  else                         { $attempts_a_ref = $self->microinjections; }

  my $total_count = 0;
  my $uniqe_count = 0;
  
  if ( $attempts_a_ref ) {
    my %unique_genes;

    foreach my $mi ( @{$attempts_a_ref} ) {
      if ( ($mi->number_het_offspring) && ($mi->number_het_offspring > 4) ) {
        $total_count++;
        $unique_genes{ $mi->event->clone->gene_symbol } = 1;
      }
    }

    $uniqe_count = scalar( keys %unique_genes );
  }
  
  return {
    'count'  => $total_count,
    'unique' => $uniqe_count
  };
}

sub parse_oracle_date {
  my ( $self, $date ) = @_;

  my $month_to_num = {
    'JAN' => 1,
    'FEB' => 2,
    'MAR' => 3,
    'APR' => 4,
    'MAY' => 5,
    'JUN' => 6,
    'JUL' => 7,
    'AUG' => 8,
    'SEP' => 9,
    'OCT' => 10,
    'NOV' => 11,
    'DEC' => 12
  };

  $date =~ /(\d\d)-(\w\w\w)-(\d\d)/;
  my $d = $1;
  my $m = $month_to_num->{$2};
  my $y = 2000 + $3;

  my $dt = DateTime->new( year => $y, month => $m, day => $d );
  return $dt;
}

sub get_all_allele_names {
  my ( $self, $params ) = @_;
  
  my $clone_allele_rs = $self->htgt_schema->resultset('WellSummaryByDI')->search(
    { epd_well_name => { '!=', undef }, allele_name => { '!=', undef } },
    { columns => [ 'epd_well_name', 'allele_name' ], distinct => 1 }
  );
  
  my $clone_allele_names_h_ref = {};
  
  while ( my $entry = $clone_allele_rs->next ) {
    $entry->allele_name =~ m!(.+)<sup>(.+)</sup>!;
    $clone_allele_names_h_ref->{ $entry->epd_well_name }->{allele_gene_sybmol} = $1;
    $clone_allele_names_h_ref->{ $entry->epd_well_name }->{allele_mutation} = $2;
  }
  
  return $clone_allele_names_h_ref;
}


no Moose;
1;
