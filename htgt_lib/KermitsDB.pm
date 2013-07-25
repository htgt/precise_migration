package KermitsDB;

use strict;
use warnings;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw//);

## Note: All model files generated using the following command:
# perl -MDBIx::Class::Schema::Loader=make_schema_at -e'make_schema_at(q(KermitsDB),{relationships=>1,debug=>1},["dbi:Oracle:host=tracedb3a;sid=utlp;port=1523", "external_mi", "re1ndeer"])'

1;
