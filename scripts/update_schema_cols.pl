#! /usr/bin/perl

use feature qw/ say /;
use strict;
use warnings;
use Try::Tiny;

=head1 update_schema_cols -- update the attributes of add_columns in HTGT schema

HTGT does not have automatically generated schema result files because when Loader was first available,
it did not work for Oracle schemas. The schema has now been dbicdump'ed and the 
add_columns section needs to be copied across to the HTGTDB schema files to replace
the old hand crafted schema add_columns data.

So this script reads two files. First it reads the new schema file and saves the add columns section
in an array.

Then, it reads the old schema file and comments out the current add_columns data and adds the
new add_columns data and saves the new file.

Syntax: update_schema_cols old_schema_file new_schema_file > revised_schema_file

The newly merged file is written on stdout.

DJP-S 23 July 2013
=cut

my $old_schema_file = $ARGV[0] || die 'Usage: update_schema_cols old_schema_file new_schema_file > revised_schema_file';

open( my $old_fh, '<', $old_schema_file )
    or die "Can't open old schema file $old_schema_file: $! \n";

my  @old_lines = <$old_fh>;
close $old_fh;
chomp @old_lines;

my $new_schema_file = $ARGV[1] || die 'Usage: update_schema_cols old_schema_file new_schema_file > revised_schema_file';

open( my $new_fh, '<', $new_schema_file )
    or die "Can't open DBIx::Class::Loader file $new_schema_file: $! \n";

my @new_lines = <$new_fh>;
close $new_fh;
chomp @new_lines;

# Find the __PACKAGE->add_columns call in the new_lines array and save it 
#
my $found_start;
my $line_counter = -1;
my $identifier = '__PACKAGE__->add_columns';
LINE1: foreach my $line ( @new_lines ) {
    $line_counter ++;
    if ($line =~ m/ \A $identifier /xgms ) {
        $found_start = 1;
        last LINE1;
    }
}
if ( !$found_start ) {
    die "__PACKAGE->add_columns identifier not found \n";
}

my @saved_lines;
my $terminator = '\);';
SAVE: while ( defined $new_lines[$line_counter] ) {
    if ( $new_lines[$line_counter] !~ m/\A $terminator \z /xgms ) {
        push @saved_lines, $new_lines[$line_counter];
        $line_counter++;
        next SAVE;
    }
    push @saved_lines, $new_lines[$line_counter];
    last SAVE;
}

# Comment out the __PACKAGE__->add_columns in old_lines saving each lines in the output array for finally
# printing to stdout.
#

# There are two cases to deal with here, one where there is a single line
# the other where the directive spans multiple lines terminating with a terminator.
#

my @revised_lines; # These lines form the final output of this script

$found_start = 0;
$line_counter = -1;

LINE_OUT: foreach my $line ( @old_lines ) {
    $line_counter ++;
    if ($line =~ m/ \A $identifier /xgms ) {
        last LINE_OUT;
    }
    else {
        push @revised_lines, $line . "\n";
    }
}

if ( $old_lines[$line_counter] =~ m/ $terminator \z /xgms) {
    # the add_columns is all on one line
    push @revised_lines, '#' . $old_lines[$line_counter] . "\n";
}
else {
    COMMENTS: while ( defined $old_lines[$line_counter] ) {
        if ( $old_lines[$line_counter] !~ m/ $terminator \z /xgms ) {
            push @revised_lines, '#' .$old_lines[$line_counter] . "\n";
            $line_counter++;
            next COMMENTS;
        }
        push @revised_lines, '#' . $old_lines[$line_counter] . "\n";
        last COMMENTS;
    }
}
$line_counter++;

# Interpolate the saved_lines now.
#
push @revised_lines, "\n";
push @revised_lines, "# Added add_columns from dbicdump for htgt_migration project - DJP-S\n";
for my $saved ( @saved_lines ) {
    push @revised_lines, $saved . "\n";
}
push @revised_lines, "# End of dbicdump add_columns data\n";
# Finally, copy the rest of old lines to revised_lines.
#
while ( defined $old_lines[$line_counter] ) {
    push @revised_lines, $old_lines[$line_counter] . "\n";
    $line_counter++;
}

print @revised_lines;
