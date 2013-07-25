package HTGT::View::TT_utils;

use strict;
use warnings;

=head1 DESCRIPTION

TT utils for HTGT. 

=head1 AUTHOR

Dan Klose dk3@sanger.ac.uk
Darren Oakley do2@sanger.ac.uk

=head1 SEE ALSO


=head1 LICENSE

This library isn't free software, you can't redistribute it and/or modify
it under the same terms as Perl itself.


=head2 link_well

Creates a link to a qc test results

=cut

sub link_qctest_result_id {
    my ( $context, $pass_text, $qc_id ) = @_;
    
    #http://www.sanger.ac.uk/cgi-bin/teams/team87/qc/qctest_view.cgi?id=62885
    return sub {
        if ( $qc_id =~ /\d+/ and $pass_text =~ /\w+/ ) {
            my $link = "<a href='http://www.sanger.ac.uk/cgi-bin/teams/team87/qc/qctest_view.cgi?id=$qc_id'>$pass_text</a>";
            return( $link );
        }
        else {
            return ();
        }
    }
}



=cut

=head2 link_mgi

Creates a link to mgi

=cut

sub link_mgi {
    my ( $context ) = @_;
    return sub {
        my $string = shift;
        $string =~ s|(\S+)|<a href='http://www.informatics.jax.org/javawi2/servlet/WIFetch?page=searchTool&query=$1&selectedQuery=Genes+and+Markers'>$1</a>|g;
        return($string);
    }
}

=head2 link_plate_name

Creates a link to a plate

=cut

sub link_plate_name {
    my ( $context ) = @_;
    return sub {
        my $string = shift;
        if ( $string =~ /^\d+$/ ) {
            my $link = "<a href='http://www.sanger.ac.uk/htgt/plate/view?plate_name=$string'>$string</a>";
            return ( $link );
        }
        else {
            return($string);
        }
    }
}

=head2 link_design

Creates a link to a design

=cut

sub link_design {
    my ( $context ) = @_;
    return sub {
        my $string = shift;
        $string =~ s/\s+//g;
        if ( $string =~ /^\d+$/ ) {
            my $link = "<a href='http://www.sanger.ac.uk/htgt/design/designlist/list_designs?design_id=". $string . "&submit_search=Get\%designs'>$string</a>";
            return( $link );
        }
        else {
            return( $string ); 
        }
    }
}

=head2 link_well

Creates a link to a well

=cut

sub link_well {
    my ( $context, $well_id, $well_name ) = @_;
    
    return sub {
        if ( $well_id =~ /\d+/ and $well_name =~ /\w+/ ) {
            my $link = "<a href='http://www.sanger.ac.uk/htgt/plate/view?well_id=$well_id#$well_id'>$well_name</a>";
            return( $link );
        }
        else {
            return ();
        }
    }
}


=head2 link_ensembl

Takes a string and will convert it to an ensembl/otter link: includes genes, 
transcripts and exons.  Will also allow links to include DAS tracks, just follow 
the ID with a list of the DAS track names that you would like included in the link.

=cut

sub link_ensembl {
    my ( $context, $text, @das ) = @_;

    my $das_source = {
        team87_production_constructs => ';add_das_source=(name=team87_production_constructs+url=http://das.ensembl.org/das+dsn=team87_production_constructs+type=ensembl_location_toplevel+active=1)',
        KO_vectors                   => ';add_das_source=(name=KO_vectors+url=http://das.sanger.ac.uk/das+dsn=KO_vectors+type=ensembl_location_toplevel+active=1)',
    };

    return sub {
        $text = shift if !defined $text;
        if ( $text =~ /OTTMUS|ENSMUS/i ) {
            my $link = 'http://www.ensembl.org/Mus_musculus/contigview?gene=' . uc($text);

            foreach ( @das ) {
                $link .= $das_source->{$_};
            }
            
            return("<a href='$link'>".uc($text)."</a>");               
        } else {
            return ( $text );
        }
        
    }
}

=head2 link_qc

Filter to provide a link to the QC results page.  Input is the pass_level (text) 
and the qctest_result_id (number).

=cut

sub link_qc {
    my ( $context, $pass_level, $id ) = @_;
    
    return sub {
        
    }
}



=head2 rot13

A simple crypto cipher ... use it when the results are wrong!

=cut

sub rot13 { 
    my $text = shift;
    $text =~ tr/a-zA-Z/n-za-mN-ZA-M/;
    return($text);
}


1;
