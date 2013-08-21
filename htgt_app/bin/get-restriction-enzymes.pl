#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::SouthernBlot;
use Log::Log4perl ':easy';
use Text::Table;
use Getopt::Long;
use Pod::Usage;
use Const::Fast;
use List::MoreUtils 'zip';
use Bio::SeqIO;

{
    my $log_level = $WARN;

    GetOptions(
        help    => sub { pod2usage( -verbose => 1 ) },
        man     => sub { pod2usage( -verbose => 2 ) },
        debug   => sub { $log_level = $DEBUG },
        verbose => sub { $log_level = $INFO },        
        'max-fragment-size=i' => \my $max_fragment_size,
        'probe=s'             => \my $probe,
        'tolerance=i'         => \my $tolerance,
    ) and @ARGV == 1 or pod2usage(2);
        
    Log::Log4perl->easy_init(
        {   level  => $log_level,
            layout => '%p %m%n'
        }
    );

    my %args = ( es_clone_name => shift @ARGV );

    if ( $max_fragment_size ) {
        $args{max_fragment_size} = $max_fragment_size;
    }

    if ( $probe ) {
        if ( $probe eq 'NeoR' or $probe eq 'LacZ3' or $probe eq 'LacZ5' ) {
            $args{probe} = $probe;            
        }
        else {
            $args{probe} = 'custom';
            my $seq_io = Bio::SeqIO->new( -file => $probe );
            $args{probe_seq} = $seq_io->next_seq;
        }
    }

    if ( $tolerance ) {
        $args{tolerance_pct} = $tolerance;
    }
    
    my $sb = HTGT::Utils::SouthernBlot->new( \%args );
        
    print_table(
        "Enzymes for 5' analysis",
        [   'Enzyme'              => 'enzyme',
            'Fragment Size'       => 'fragment_size',
            'Preferred?'          => 'is_preferred',
            'Distance from G5'    => 'distance_g5',
            'Distance from probe' => 'distance_probe',
        ],
        $sb->fivep_enzymes
    );

    print "\n\n";

    print_table(
        "Enzymes for 3' analysis",
        [   'Enzyme'              => 'enzyme',
            'Fragment Size'       => 'fragment_size',
            'Preferred?'          => 'is_preferred',
            'Distance from G3'    => 'distance_g3',
            'Distance from probe' => 'distance_probe',
        ],
        $sb->threep_enzymes
    );
}

sub print_table {
    my ( $title, $colspec, $data ) = @_;

    my ( @columns, @keys );
    while ( my ( $column_name, $key_name ) = splice @{$colspec}, 0, 2 ) {
        push @columns, $column_name;
        push @keys,    $key_name;
    }

    my $tb = Text::Table->new( interpose( \' | ', @columns ) );
    for ( @{$data} ) {
        $tb->add( @{$_}{@keys} );
    }

    print "$title\n";
    print '-' x length($title), "\n\n";
    print $tb->title;
    print $tb->rule( '-', '+' );
    print $tb->body;
}

sub interpose {
    my $sep = shift;

    my @separators = ( $sep ) x $#_;
    zip @_, @separators;
}

__END__

=pod

=head1 NAME

get_restriction_enzymes

=head1 SYNOPSIS

  get-restriction-enzymes.pl [OPTIONS] EPD_CLONE_NAME

=head1 OPTIONS

=over

=item B<--help>

Display a brief help message.

=item B<--man>

Display the manual page.

=item B<--debug>

Show debug messages.

=item B<--verbose>

Show informational messages.

=iteb B<--max-fragment-size>

Specify the maximum fragment size (in base pairs). By default, only
enzymes producing fragments less than 25kbp are reported. Use this
option to specify a different threshold. Set C<--max-fragment-size=0> to
see all enzymes, regardless of fragment size.

=back

=head1 DESCRIPTION

This program will attempt to download annotated sequence for the
allele I<EPD_CLONE_NAME> from the IDCC Targeting Repository. It
searches the annotations to determine the location of the G3 and G5
primers and the Neo probe, then uses the L<Bio::Restriction::Analysis>
library to identify restriction enzymes suitable for 5' and 3'
Southern Blot assays.

=head1 SEE ALSO

L<Bio::Restriction::Analysis>

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
