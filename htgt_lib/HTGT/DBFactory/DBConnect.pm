#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-dbconnect/trunk/lib/HTGT/DBFactory/DBConnect.pm $
# $LastChangedDate: 2013-03-08 13:24:21 +0000 (Fri, 08 Mar 2013) $
# $LastChangedRevision: 8158 $
# $LastChangedBy: pm9 $
#
package HTGT::DBFactory::DBConnect;

use strict;
use warnings FATAL => 'all';

use base 'Class::Data::Inheritable';

use Carp;
use Config::General;
use DBI;
use Readonly;

Readonly my $DEFAULT_CONFIG => '/software/team87/brave_new_world/conf/dbconnect.cfg';

__PACKAGE__->mk_classdata( 'ConfigFile' => $ENV{ HTGT_DBCONNECT } || $DEFAULT_CONFIG );

{
    my %config;

    sub config {
        my ( $class ) = @_;

        unless ( $config{ $class->ConfigFile } ) {
            $config{ $class->ConfigFile } =
                {
                    Config::General->new( -ConfigFile => $class->ConfigFile )->getall
                };
        }

        return $config{ $class->ConfigFile };
    }
}

sub params {
    my ( $class, $dbname, $attrs ) = @_;

    my $config = $class->config();

    my $c = $config->{ Database }->{ $dbname }
        or Carp::confess "Database '$dbname' not configured";

    my %attrs;

    if ( $c->{no_default_attrs} ) {
        %attrs = (
            %{ $c->{ Attributes } || {} },
            %{ $attrs             || {} }
        );
    }
    else {
        %attrs = (
            %{ $config->{ DefaultAttributes } || {} },
            %{ $c->{ Attributes }             || {} },
            %{ $attrs                         || {} }
        );
    }

    return ( $c->{ dsn }, $c->{ user }, $c->{ password }, \%attrs );
}

sub params_hash {
    my $class = shift;

    my ( $dsn, $user, $passwd, $attrs ) = $class->params( @_ );
    return {
        dsn      => $dsn,
        user     => $user,
        password => $passwd,
        %{ $attrs }
    };
}

sub model {
    my ( $class, $dbname ) = @_;

    my $config = $class->config();

    my $c = $config->{ Database }->{ $dbname }
        or Carp::confess "Database '$dbname' not configured";

    my $model = $c->{model}
        or Carp::confess "No model defined for '$dbname'";

    return $model;
}

sub dbi_connect {
    my ( $class, $dbname, $override_attrs ) = @_;

    DBI->connect( $class->params( $dbname, $override_attrs ) );
}

sub dbi_connect_cached {
    my ( $class, $dbname, $override_attrs ) = @_;

    DBI->connect_cached( $class->params( $dbname, $override_attrs ) );
}

sub connect {
    my ( $class, $dbname, $override_attrs ) = @_;

    my @params = $class->params( $dbname, $override_attrs );
    my $model  = $class->model( $dbname );

    eval "require $model"
        or Carp::confess( "Failed to load $model: $@" );

    $model->connect( @params );
}

1;

__END__

=pod

=head1 NAME

HTGT::DBFactory::DBConnect

=head1 SYNOPSIS

  use HTGT::DBFactory::DBConnect;
  HTGT::DBFacotry::DBConnect->ConfigFile( $path );

  my $schema = HTGTDB->connect( HTGT::DBConnect->params( 'eucomm_vector' ) );

  my $dbh = HTGT::DBFactory::DBConnect->dbi_connect( 'vector_qc' );

=head1 DESCRIPTION

This is not the module you are looking for. Try L<HTGT::DBFactory>.

This module reads database connection parameters from a configuration file and
implements a class method that returns the connection parameters for a given database
in a format suitable for passing to C<DBI-E<gt>connect()> or
C<DBIx::Class::Storage::DBI-E<gt>connect()>.  It also provides two convenience methods for
connecting to a database via DBI, and a method for connecting via DBIx::Class.

=head1 CLASS METHODS

=head2 ConfigFile( I<path> )

Override the default configuration file path.

=head2 params( I<database_name> )

Return connect parameters for the specified I<database_name>.

=head2 dbi_connect( I<database_name> )

Call B<DBI-E<gt>connect> with parameters configured for I<database_name> and
return database handle.

=head2 dbi_connect_cached( I<database_name> )

Call B<DBI-E<gt>connect_cached> with parameters configured for I<database_name> and
return database handle.

=head2 connect( I<database_name> )

Loads the appropriate B<DBIx::Class> schema for this database, calls B<connect()>,
and returns a B<DBIx::Class::Schema> object. Throws an exception if no model is
defined for I<database_name>.

=head1 CONFIGURATION

The configuration file should be in a format that is understood by B<Config::General>.

It may contain a single section B<DefaultAttributes> to be applied to B<all> databases:

  <DefaultAttributes>
    AutoCommit  = 0
    RaiseError  = 1
    PrintError  = 0
    LongReadLen = 2097152
    on_connect_do = alter session set NLS_SORT=BINARY_CI
    on_connect_do = alter session set NLS_COMP=LINGUISTIC
  </DefaultAttributes>

and a named B<Database> section for each database:

  <Database eucomm_vector_test>
    model = HTGTDB
    dsn = dbi:Oracle:migt_ha
    user = eucomm_vector
    password = eucomm_vector
  </Database>

  <Database eucomm_vector_devel>
    model = HTGTDB
    dsn = dbi:Oracle:migd
    user = eucomm_vector
    password = eucomm_vector
  </Database>

An B<Attributes> section within a B<Database> will augment (or override) any
B<DefaultAttributes>:

  <Database vector_qc_test>
    model = ConstructQC
    dsn = dbi:Oracle:utlt
    user = vector_qc
    password = vector_qc
    <Attributes>
        LongReadLen = 144000
    </Attributes>
  </Database>

Here, B<LongReadLen> will be 14400, overriding the default 2097152.

=head1 CAVEATS

The B<on_connect_do> paramater is specific to B<DBIx::Class> and is ignored by B<DBI>.  This means
it will be ignored by this module's C<dbi_connect> and C<dbi_connect_cached> methods.

=head1 FILES

The default configuration file is C</software/team87/brave_new_world/conf/dbconnect.cfg>.

=head1 ENVIRONMENT

The environment variable B<HTGT_DBCONNECT> will override the default configuration file path.

=head1 SEE ALSO

L<Config::General>, L<DBI>, L<DBIx::Class>.

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>.

=cut
