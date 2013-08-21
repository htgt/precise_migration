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
use Log::Log4perl qw( :levels );
use Bio::SeqIO;
use HTGT::QC::Util::FetchSynVecs;
use Const::Fast;
use Path::Class;

const my %SUFFIX_FOR => (
    genbank => 'gbk',
    fasta   => 'fasta'
);

{
    my $log_level = $WARN;    
    
    GetOptions(
        'help'       => sub { pod2usage( -verbose => 1 ) },
        'man'        => sub { pod2usage( -verbose => 2 ) },
        'trace'      => sub { $log_level = $TRACE },
        'debug'      => sub { $log_level = $DEBUG },
        'verbose'    => sub { $log_level = $INFO },
        'format=s@'  => \my $formats,
        'dirname=s'  => \my $dirname,
        'stage=s'    => \my $stage,
    ) and @ARGV == 1 or pod2usage(2);

    Log::Log4perl->easy_init( { level => $log_level } );

    my $outdir = dir( $dirname || '.' );
    
    fetch_syn_vecs(
        template_plate => $ARGV[0],
        vector_stage   => $stage,
        output_dir     => $outdir,
    );
}    

__END__

=head1 NAME

fetch-syn-vecs.pl - Describe the usage of script briefly

=head1 SYNOPSIS

fetch-syn-vecs.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for fetch-syn-vecs.pl, 

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
