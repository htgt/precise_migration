#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::SouthernBlot;
use Getopt::Long;
use CSV::Reader;
use CSV::Writer;
use Log::Log4perl ':easy';
use Try::Tiny;

my $loglevel = $WARN;

GetOptions(
    'probe=s'     => \my $probe,
    'tolerance=i'         => \my $tolerance,
    'max-fragment-size=i' => \my $max_fragment_size,
) or die "Usage: $0 --probe=s --tolerance=i --max-fragment-size=i\n";

Log::Log4perl->easy_init( { level => $DEBUG, layout => '%p %m%n' } );

# code,keyword,commentaire,ensemblid,ligne_es,digest_neo5,digest_neo3
my $in = CSV::Reader->new( use_header => 1 );

my $out = CSV::Writer->new();
$out->write( "Clone name", "Found in targ rep?", "Acutal 5' enzymes", "Missing 5' enzymes", "Actual 3' enzymes", "Missing 3' enzymes" );

my %args;

if ( $probe ) {
    my $seq_io = Bio::SeqIO->new( -file => $probe );
    $args{probe_seq} = $seq_io->next_seq;        
}

if ( $tolerance ) {
    $args{tolerance_pct} = $tolerance;
}

if ( $max_fragment_size ) {
    $args{max_fragment_size} = $max_fragment_size;
}

while ( my $d = $in->read ) {
    ( my $clone_name = $d->{commentaire} ) =~ s/(^\s)|(\s$)//g;    
    next unless $clone_name and ( $d->{digest_neo5} or $d->{digest_neo3} );

    $args{es_clone_name} = $clone_name;

    my ( $found_in_targrep, $missing_5, $missing_3 );    
    
    try {
        my $sb = HTGT::Utils::SouthernBlot->new( \%args );
        $found_in_targrep = 'yes';
        $missing_5 = check_enzymes( $clone_name, "5'", $sb->fivep_enzymes, $d->{digest_neo5} )
            if $d->{digest_neo5};
        $missing_3 = check_enzymes( $clone_name, "3'", $sb->threep_enzymes, $d->{digest_neo3} )
            if $d->{digest_neo3};
    } catch {
        ERROR( $_ );
        $found_in_targrep = 'no';        
    };

    $out->write( $clone_name, $found_in_targrep, $d->{digest_neo5}, $missing_5, $d->{digest_neo3}, $missing_3 );    
}

sub check_enzymes {
    my ( $clone_name, $what, $predicted, $actual ) = @_;

    my %predicted = map { normalize_enzyme_name( $_->{enzyme} ) => 1 } @{ $predicted };
    join ',', grep !$predicted{ normalize_enzyme_name( $_ ) }, split qr/\s*[\/,]\s*/, $actual;
}

sub normalize_enzyme_name {
    my $enzyme = shift;

    $enzyme =~ s/\s//g;
    $enzyme = lc( $enzyme );
}
