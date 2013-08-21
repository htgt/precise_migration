#!/usr/bin/env perl
use warnings FATAL => 'all';
use strict;

use HTGT::Utils::TargRep::Update;
use HTGT::DBFactory;
use HTGT::Utils::Tarmits;
use Getopt::Long;
use Log::Log4perl ':easy';
use Pod::Usage;

my $loglevel = $INFO;
my @genes;
my @projects;
my ( $commit, $optional_checks, $eng_seq_config, $hide_non_dist, $check_genbank );

GetOptions(
    'help'             => sub { pod2usage( -verbose => 1 ) },
    'man'              => sub { pod2usage( -verbose => 2 ) },
    'debug'            => sub { $loglevel = $DEBUG },
    'warn'             => sub { $loglevel = $WARN },
    'gene=s'           => \@genes,
    'project=i'        => \@projects,
    commit             => \$commit,
    hide_non_dist      => \$hide_non_dist,
    optional_checks    => \$optional_checks,
    check_genbank      => \$check_genbank,
    'eng_seq_config=s' => \$eng_seq_config,
)or pod2usage(2);

Log::Log4perl->easy_init( { level => $loglevel, layout => '%p %x %m%n' } );

my $htgt_schema    = HTGT::DBFactory->connect('eucomm_vector', { FetchHashKeyName => 'NAME_lc' });
#targrep_schema now points to tarmits. This database is targrep and imits merged together. This is used to retrieve data from tarmits
my $targrep_schema = HTGT::DBFactory->connect( 'tarmits' );
#idcc_api is used to update tarmits through the api.
my $idcc_api       = HTGT::Utils::Tarmits->new_with_config( username => 'htgt@sanger.ac.uk', password => 'WPbjGHdG' );

my @config = (
    htgt_schema         => $htgt_schema,
    targrep_schema      => $targrep_schema,
    idcc_api            => $idcc_api,
    genes               => \@genes,
    commit              => $commit,
    hide_non_distribute => $hide_non_dist,
    optional_checks     => $optional_checks,
    check_genbank_info  => $check_genbank,
    projects            => \@projects,
);

push @config, (eng_seq_config => $eng_seq_config) if $eng_seq_config;
my $targ_rep_update = HTGT::Utils::TargRep::Update->new( @config );

$targ_rep_update->htgt_to_targ_rep;

__END__

=head1 NAME

update_targ_rep.pl - Driver script for HTGT::Utils::TargRep::Update

=head1 SYNOPSIS

update_targ_rep.pl [options] input output

      --help            Display a brief help message
      --man             Display the manual page
      --debug           Print debug messages
      --warn            Only print warn or higher log messages
      --gene=s          Optionally specify gene marker symbols to work on
      --project=i       Optionally specify project ids to work on
      --commit          Run script in commit mode, making changes to the targ rep
      --hide_non_dist   Hide any non distributable es cells or targeting vectors in targ rep
      --optional_checks Run optional checks on products (floxed exons currently)
      --check_genbank   Compare HTGT Genbank files to Targ Rep ones, takes time.

=head1 DESCRIPTION

Update the Targ Rep for the EUCOMM, KOMP-CSD and MGP pipelines.
Adds new distributable products, hides non distributable products
and checks data in the targ rep is update to date.

Script can be run for individual genes or projects, and can optionally check genbank files
and floxed exon data.

=head1 AUTHOR

Sajith Perera

=head1 BUGS

None reported... yet.

=headl TODO

=cut
