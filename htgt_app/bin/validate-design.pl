#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use Log::Log4perl ':easy';
use Try::Tiny;
use HTGT::Utils::Design::Validate;        

{
    my $log_level = $WARN;

    GetOptions(
        'help'       => sub { pod2usage( -verbose => 1 ) },
        'man'        => sub { pod2usage( -verbose => 2 ) },
        'debug'      => sub { $log_level = $DEBUG },
        'verbose'    => sub { $log_level = $INFO },
    ) or pod2usage(2);

    Log::Log4perl->easy_init(
        {
            level  => $log_level,
            layout => '%p design=%X{design_id} %m%n',
        }
    );

    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

    my @design_ids = @ARGV ? @ARGV : map { chomp; $_ } <STDIN>;

    for ( @design_ids ) {
        Log::Log4perl::MDC->put( design_id => $_ );
        try {
            validate_design( $htgt, $_ );
        } catch {
            ERROR( $_ );
        };        
    }
}

sub validate_design {
    my ( $htgt, $design_id ) = @_;

    my $design = $htgt->resultset( 'Design' )->find( { design_id => $design_id } )
        or die "design not found\n";

    my $v = HTGT::Utils::Design::Validate->new( design => $design );
    
    if ( $v->has_errors ) {        
        ERROR( $_->mesg ) for ( $v->errors );
    }
    else {
        INFO( "Design OK" );
    }
}
    
__END__

=pod

=head1 NAME

validate-design.pl

=head1 SYNOPSIS

  validate-design [OPTIONS] [DESIGN_ID ...]

=cut
