package HTGT::DBFactory;

#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-dbconnect/trunk/lib/HTGT/DBFactory.pm $
# $LastChangedRevision: 8158 $
# $LastChangedDate: 2013-03-08 13:24:21 +0000 (Fri, 08 Mar 2013) $
# $LastChangedBy: pm9 $
#

use HTGT::DBFactory::DBConnect;
use Carp;
use Readonly;

sub connect {
    my ( $class, $database, $attrs ) = @_;

    my $dbname = $class->dbname_for( $database );

    HTGT::DBFactory::DBConnect->connect( $dbname, $attrs );
}

sub dbi_connect {
    my ( $class, $database, $attrs ) = @_;

    my $dbname = $class->dbname_for( $database );

    HTGT::DBFactory::DBConnect->dbi_connect( $dbname, $attrs );
}

sub params {
    my ( $class, $database, $attrs ) = @_;

    my $dbname = $class->dbname_for( $database );

    HTGT::DBFactory::DBConnect->params( $dbname, $attrs );
}

sub params_hash {
    my ( $class, $database, $attrs ) = @_;

    my $dbname = $class->dbname_for( $database );

    HTGT::DBFactory::DBConnect->params_hash( $dbname, $attrs );
}

{
    Readonly my %ENVVAR_FOR => (
        'eucomm_vector' => 'HTGT_DB',
        'vector_qc'     => 'VECTOR_QC_DB',
        'kermits'       => 'KERMITS_DB',
        'mig'           => 'MIG_DB',
        'idcc'          => 'IDCC_DB',
        'tarmits'       => 'TARMITS_DB',
    );

    sub dbname_for {
        my ( $class, $database ) = @_;

        my $dbname;

        if ( my $envvar = $ENVVAR_FOR{ $database } ) {
            $dbname = $ENV{ $envvar };
            defined ( $dbname )
                or Carp::confess( "Environment variable $envvar not set" );
        }
        else {
            $dbname = $database;
        }

        return $dbname;
    }
}

1;

__END__

=pod

=head1 NAME

HTGT::DBFactory

=head1 SYNOPSIS

  my $schema = HTGT::DBFactory->connect( 'eucomm_vector' );

  my $dbh = HTGT::DBFactory->dbi_connect( 'vector_qc', {AutoCommit => 1} );

  my @params = HTGT::DBFactory->params( 'mig' );

=head1 DESCRIPTION

This module provides a wrapper around B<HTGT::DBFactory::DBConnect> that will load the appropriate
B<DBIx::Class> model, look up the database name (eucomm_vector, eucomm_vector_test,
eucomm_vector_devel, etc.) in %ENV, and call the appropriate HTGT::DBFactory::DBConnect method.

Note that the database names specifid in the environment must exist in the B<HTGT::DBFactory::DBConnect>
configuration.

=head1 METHODS

=over 4

=item B<connect()>

Returns a B<DBIx::Class::Schema> object.

=item B<dbi_connect()>

Returns a B<DBI> handle.

=item B<params()>

Returns a list of parameters suitable for passing to C<DBI-E<gt>connect()>.

=back

=head1 SUPPORTED DATABASES

=over 4

=item I<eucomm_vector>

=item I<vector_qc>

=item I<kermits>

=item I<mig>

=back

=head1 ENVIRONMENT

=over 4

=item B<HTGT_DB>

Specifies the I<eucomm_vector> database to connect to.

=item B<VECTOR_QC_DB>

Specifies the I<vector_qc> database to connect to.

=item B<KERMITS_DB>

Specifies the I<kermits> database to connect to.

=item B<MIG_DB>

Specifies the I<mig> database to connect to.

=back

=head1 SEE ALSO

L<HTGT::DBFactory::DBConnect>, L<HTGTDB>, L<ConstructQC>, L<KermitsDB>.

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>.

=cut
