package HTGT::Utils::PassLevel;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgtdb/trunk/lib/HTGT/Utils/PassLevel.pm $
# $LastChangedRevision: 4345 $
# $LastChangedDate: 2011-03-16 17:21:32 +0000 (Wed, 16 Mar 2011) $
# $LastChangedBy: rm7 $

use Sub::Exporter -setup => {
    exports => [ qw( cmp_pass_level qc_update_needed ) ]
};

use Const::Fast;
use Try::Tiny;
use Log::Log4perl ':easy';
use Carp qw( confess );

const my @RANKED_PASS_LEVELS => reverse qw(

    pass
    pass1
    pass2    
    pass2.1
    pass2.2
    pass2.3
    pass3
    pass4
    pass4.1
    pass4.2
    pass4.3
    pass5
    pass5.1
    pass5.2
    pass5.3
    pass6
    pass7
    
    passa
    pass1a
    pass2.1a
    pass2.2a
    pass2.3a
    pass3a
    pass4.1a
    pass4.2a
    pass5.1a
    pass5.2a
    pass5.3a
    
    passb
    pass1b
    pass2.1b
    pass2.2b
    pass2.3b
    pass3b
    pass4.1b
    pass4.2b
    pass5.1b
    pass5.2b
    pass5.3b
    
    pass_lox
    warn
    fail
);

=head2 rank_for_pass_level( I<$pass_level> )

Returns the ranking of pass level I<$pass_level>. If I<$pass_level> is
undefined, assumes it is a fail.

=cut

sub rank_for_pass_level {
    my $pass_level = shift;

    $pass_level = 'fail' unless defined $pass_level;
    $pass_level = 'fail' if $pass_level =~ /fail/;
    $pass_level = 'warn' if $pass_level =~ /warn/;

    my $rank = 0;
    
    for my $this_level ( @RANKED_PASS_LEVELS ) {
        return $rank if $pass_level eq $this_level;
        $rank++;
    }

    confess "Unrecognized pass_level '$pass_level'";
}


=head2 cmp_pass_level(I<$pass_level_a>, I<$pass_level_b>)

Compares two pass levels and returns:

   0 if the pass levels are the same
   1 if I<$pass_level_a> is more advanced than I<$pass_level_b>
  -1 otherwise

=cut

sub cmp_pass_level {
    my ( $pass_level_a, $pass_level_b ) = @_;

    return rank_for_pass_level( $pass_level_a ) <=> rank_for_pass_level( $pass_level_b );
}

=head2 qc_update_needed

Helper for B<insert_update_qc_data>.  This function determines if the new 
QC result is better than the old one - returns undef for 'no', 1 for 'yes'.

B<Input>
 * $existing_pass_level:  The existing pass level
 * $new_pass_level:       The newer pass level
 * $stage:                The QC test 'stage' - i.e. 'allele' etc. (B<no longer used>)

=cut

sub qc_update_needed {
    my ( $existing_pass_level, $new_pass_level, $stage ) = @_;

    my $cmp;
    try {
        $cmp = cmp_pass_level( $new_pass_level, $existing_pass_level );
    }
    catch {
        ERROR( $_ );
        $cmp = 0;
    };
  
    if ( $cmp > 0 ) {
        return 1;
    }

    return undef;
}

1;

__END__
