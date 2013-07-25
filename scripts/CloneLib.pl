use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my $rs = $htgt->resultset( 'CloneLib' );

my $rs_res = $rs->create(
    {
        clone_lib_id => 1000,
        library => 'test',
    }
);


my $design = $htgt->resultset( 'Design' )->search( {} )->first;

my $cat = $htgt->resultset( 'DesignUserCommentCategories' )->find( { category_name => 'Recovery design' } );

my $duc = $cat->design_user_comments_rs->create(
    {
        category_id => $cat->id,
        design_id   => $design->design_id,
        edited_user => $ENV{USER},
#        edited_date => 'SYSDATE',
        edited_date => \'current_timestamp',
        design_comment => 'Hello',
        visibility => 'internal',
        design_comment_id => undef,
    }
);

print "Done.\n";
