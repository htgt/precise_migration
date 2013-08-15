package HTGT::Test::Class;

use strict;
use warnings FATAL => 'all';

use base qw( Test::Class Class::Data::Inheritable );

BEGIN {
    __PACKAGE__->mk_classdata( 'class' => 'HTGT::Test::Class' );
    __PACKAGE__->mk_classdata('eucomm_vector_schema');
    __PACKAGE__->mk_classdata('kermits_schema');
}

use Test::Most;
use HTGTDB;
use KermitsDB;
use YAML::Syck;
use Path::Class;

sub SKIP_CLASS { shift eq __PACKAGE__ }

sub deploy_eucomm_vector_schema {

    my $eucomm_vector
        = HTGTDB->connect( 'dbi:SQLite:dbname=:memory:', '', '', { AutoCommit => 1 } );

    $eucomm_vector->deploy(
        {   filters => [
                sub {
                    my $schema = shift;
                    for my $t ( $schema->get_tables ) {

                        # Skip MIG.* tables
                        if ( $t->name =~ m/^mig\./ ) {
                            $schema->drop_table($t);
                            next;
                        }

                        # Ensure that all fields are nullable
                        # set primary key fields as integer data type
                        # this is so auto increment of pk fields will work
                        for my $f ( $t->get_fields ) {
                            #$f->is_nullable(1);
                            # This is all properly defined in the schema
                            if ( $f->is_primary_key ) {
                                $f->is_nullable(0);
                                my $type = $f->data_type;
                                $f->data_type('integer') unless $type;
                            }
                        }

                        # Drop foreign key constraits pointing at mig schema
                        for my $fkey ( $t->fkey_constraints ) {
                            if ( $fkey->reference_table =~ m/^mig\./ ) {
                                $t->drop_constraint( $fkey );                                
                            }
                        }
                    }
                    for my $v ( $schema->get_views ) {
                        # Skip the well_detail materialized view                        
                        if ( $v->name eq 'well_detail' ) {
                            $schema->drop_view( $v );
                            next;                            
                        }
                    }
                }
            ]
        }
    );

    return $eucomm_vector;
}

sub deploy_kermits_schema {

    my $kermits = KermitsDB->connect( 'dbi:SQLite:dbname=:memory:', '', '', { AutoCommit => 1 } );

    $kermits->deploy(
        {   filters => [
                sub {
                    my $schema = shift;
                    for my $t ( $schema->get_tables ) {

                        # Ensure that all fields are nullable
                        for my $f ( $t->get_fields ) {
                            $f->is_nullable(1);
                        }
                    }
                }
            ]
        }
    );

    return $kermits;
}

sub load_fixtures {
    my ( $test, $schema, $fixture_dir ) = @_;

    while ( my $fixture = $fixture_dir->next ) {
        next unless -f $fixture;
        my ($resultset_name) = $fixture->basename =~ m/^(.*)\.yaml$/ or next;
        my $data             = YAML::Syck::LoadFile($fixture);
        my $rs               = $schema->resultset($resultset_name);
        for my $datum ( @{$data} ) {
            $rs->create($datum);
        }
    }

    return 1;
}

sub make_fixtures : Tests(startup => 4) {
    my $test = shift;

    ok my $eucomm_vector = $test->deploy_eucomm_vector_schema, 'Deploy eucomm_vector schema';

    my $eucomm_vector_fixtures = dir($FindBin::Bin)->subdir('fixtures')->subdir('eucomm_vector');

    ok $test->load_fixtures( $eucomm_vector, $eucomm_vector_fixtures ),
        'Load eucomm_vector fixtures';

    $test->eucomm_vector_schema($eucomm_vector);

    ok my $kermits_fixtures = dir($FindBin::Bin)->subdir('fixtures')->subdir('kermits'),
        'Deploy kermits schema';

    my $kermits = $test->deploy_kermits_schema;

    ok $test->load_fixtures( $kermits, $kermits_fixtures ), 'Load kermits fixtures';

    $test->kermits_schema($kermits);
}

1;

__END__
