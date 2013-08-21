#!/usr/bin/env perl
use warnings FATAL => 'all';
use strict;

use HTGT::Utils::TargRep::Update::RegeneronGenbank;
use HTGT::Utils::Tarmits;
use HTGT::DBFactory;
use Getopt::Long;
use Log::Log4perl ':easy';
use Pod::Usage;

my $loglevel = $INFO;
my @projects;
my ( $commit, $eng_seq_config, $check_genbank );

GetOptions(
    'help'             => sub { pod2usage( -verbose => 1 ) },
    'man'              => sub { pod2usage( -verbose => 2 ) },
    'debug'            => sub { $loglevel = $DEBUG },
    'warn'             => sub { $loglevel = $WARN },
    'project=s'        => \@projects,
    commit             => \$commit,
    check_genbank      => \$check_genbank,
    'eng_seq_config=s' => \$eng_seq_config,
)or pod2usage(2);

Log::Log4perl->easy_init( { level => $loglevel, layout => '%p %x %m%n' } );

my $targrep_schema = HTGT::DBFactory->connect( 'tarmits' );
my $idcc_api       = HTGT::Utils::Tarmits->new_with_config( username => 'htgt@sanger.ac.uk', password => 'WPbjGHdG' );
my $htgt_schema    = HTGT::DBFactory->connect('eucomm_vector', { FetchHashKeyName => 'NAME_lc' });

my @config = (
    htgt_schema    => $htgt_schema,
    targrep_schema => $targrep_schema,
    idcc_api       => $idcc_api,
    commit         => $commit,
    projects       => \@projects,
    check_genbank  => $check_genbank,
);

push @config, ( eng_seq_config => $eng_seq_config ) if $eng_seq_config;
my $regeneron_genbank = HTGT::Utils::TargRep::Update::RegeneronGenbank->new( @config );

$regeneron_genbank->update_regeneron_genbank_files;

__END__

=head1 NAME

update_regeneron_genbank_files.pl - Driver script for HTGT::Utils::TargRep::Update::RegeneronGenbank

=head1 SYNOPSIS

update_regeneron_genbank_files.pl [options]

      --help             Display a brief help message
      --man              Display the manual page
      --debug            Print debug messages
      --warn             Only print warn or higher log messages
      --project=s        Optionally specify Regeneron project ids to work on
      --commit           Run script in commit mode, making changes to the targ rep
      --eng_seq_config=s Specify a EngSeq config file

=head1 DESCRIPTION

Update the Regeneron Genbank files in the Targ Rep.
Script can be run for individual genes or projects.

=head1 AUTHOR

Sajith Perera

=head1 BUGS

None reported... yet.

=headl TODO

=cut
