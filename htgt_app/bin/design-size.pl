#!/usr/bin/env perl
#
# $HeadURL$
# $LastChangedRevision$
# $LastChangedDate$
# $LastChangedBy$
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory::Lazy 'htgt';
use Const::Fast;

const my $GRANULARITY => 1000;

GetOptions(
    'help'        => sub { pod2usage( -verbose => 1 ) },
    'man'         => sub { pod2usage( -verbose => 2 ) },
    'threshold=i' => \my $threshold,
) or pod2usage(2);

$threshold ||= 12000;

my $design_rs = htgt->resultset( 'Design' )->search(
    {
        '-or' => { 'projects.is_eucomm' => 1, 'projects.is_komp_csd' => 1 },
        rownum => { '<=', 1000 }
    },
    {
        join => 'projects'
    }
);

my %count_for;

while ( my $design = $design_rs->next ) {
    my $size = $design->info->homology_arm_end - $design->info->homology_arm_start;
    $size = int( $size / $GRANULARITY ) * $GRANULARITY;
    if ( $size > $threshold ) {
        print $design->design_id . ' ' . $size . "\n";        
    }
    $count_for{$size}++;    
}

for my $size ( sort { $a <=> $b } keys %count_for ) {
    print "$size\t$count_for{$size}\n";
}




__END__

=head1 NAME

design-size.pl - Describe the usage of script briefly

=head1 SYNOPSIS

design-size.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for design-size.pl, 

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ray Miller

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
