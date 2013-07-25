package HTGT::Controller::Design;

use strict;
use warnings;
use base 'Catalyst::Controller';
use DBI;
use Cwd; #Yes, I use this - you know who 'I' am
use File::Temp qw/ tempdir /;

=head1 NAME

HTGT::Controller::Design - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for('/design/designlist/list_designs') );
}

#
# Insert short range primers into the database
#

sub insert_short_range_primers : Local {
   my ( $self, $c ) = @_;
   my $design_id    = $c->req->params->{design_id};
   my $arm          = $c->req->params->{arm};
   my $fp           = $c->req->params->{five_prime};
   my $tp           = $c->req->params->{three_prime};
   
   $fp =~ s/\s+//g;
   $tp =~ s/\s+//g;
   
   if ( length $c->req->params->{five_prime} < 10 || length $c->req->params->{three_prime} < 10 ) { 
       $c->res->body('<span class="failure"><em>Failed to find design</em></span>'); 
       return 0; 
   } 

   my $design = $c->model('HTGTDB::Design')->find( { design_id=>$c->req->params->{design_id} } );
   
   if ( ! defined $design ) { 
       $c->res->body('<span class="failure"><em>Failed to find design</em></span>'); 
       return 0;
   }

   my $display_feature = $c->model('HTGTDB::DisplayFeature')->find(
       { 'feature.design_id'  => $design_id, display_feature_type => 'U3' },
       { join => 'feature', prefetch => 'chromosome' }
   );
   
   
   #IF YOU CAN SEE THIS THE CODE HAS NOT BEEN CHECKED...
   my $tp_feat_type_id = 0;
   my $fp_feat_type_id = 0;
   
   if ( $arm =~ /3/ ) {
       $fp_feat_type_id = 52;
       $tp_feat_type_id = 53;
   }
   else {
       $fp_feat_type_id = 50;       
       $tp_feat_type_id = 51;
   }
   
   #This is the 5' feature/primer - not the target 
   my $feature5 = $c->model('HTGTDB::Feature')->update_or_create(
       {
           feature_type_id => $fp_feat_type_id,
           design_id       => $design->design_id,
           chr_id          => $display_feature->chromosome->id,
           feature_start   => -1,
           feature_end     => 1
       }
    );

    my $fd5 = $c->model('HTGTDB::FeatureData')->find( { feature_id => $feature5->feature_id } );
    if ( ! defined $fd5 ) { 
        $fd5 = $c->model('HTGTDB::FeatureData')->create(
            {
                feature_id           => $feature5->feature_id,
                feature_data_type_id => 1,
                data_item            => $fp
            }
        );
    }
    else {
        $fd5->update({ data_item => $fp });
    }        

    #This is the 5' feature/primer - not the target
    #Insert the three prime information.
    my $feature3 = $c->model('HTGTDB::Feature')->update_or_create(
        {
            feature_type_id => $tp_feat_type_id,
            design_id       => $design->design_id,
            chr_id          => $display_feature->chromosome->id,
            feature_start   => -1,
            feature_end     => 1
        }
    );
     
    my $fd3 = $c->model('HTGTDB::FeatureData')->find( { feature_id => $feature3->feature_id } );
    if ( ! defined $fd3 ) { 
        $fd3 = $c->model('HTGTDB::FeatureData')->create(
            {
                feature_id           => $feature3->feature_id,
                feature_data_type_id => 1,
                data_item            => $tp
            }
        );
    }
    else {
        $fd3->update({ data_item => $tp });
    }
       
   $c->res->body('<span class="success"><em>Added Primers</em></span>');
   
}

 sub create_primers : Local {
    my ( $self, $c )    = @_;
    my $design_id       = $c->req->params->{design_id};   
    my $arm_choice      = $c->req->params->{armChoice};       
    ( my $amplicon_size = $c->req->params->{ampsize}) =~ s/\s+//g;     
    ( my $meltingTemp   = $c->req->params->{melt}) =~ s/\s+//g;        
    my $masking         = $c->req->params->{masking};     
    ( my $three_shim    = $c->req->params->{tpshim} ) =~ s/\s+//g;
    ( my $five_shim     = $c->req->params->{fpshim} ) =~ s/\s+//g;

    my %PRIMERS = ();
    
    my $dbi    = $c->model(q(HTGTDB))->storage->dbh;
    my $Q      = _query_list( $dbi );

    if ( $amplicon_size !~ /^\d+$/ || $meltingTemp !~ /^\d+$/ 
        || $three_shim !~ /^\d+$/  || $five_shim !~ /^\d+$/   ) {
        #$c->res->body("<span><h6>Error:</h6><p>The melting point and amplicon size <strong>must</strong> be <strong>integers</strong></p></span>");        
        $c->stash->{primer_error} = 1;
        $c->stash->{template} = 'design/_primers.tt';
        $c->forward('HTGT::View::NakedTT');
    } else {
        my $variable_feature_id_exe; #Either the g5_u5 or the d3_g3
        if ( $arm_choice =~ /^3-arm$/ ) {
            $variable_feature_id_exe = $dbi->prepare( $Q->{get_D3_G3} );
        }
        else {
            #This is the cassette
            $variable_feature_id_exe = $dbi->prepare( $Q->{get_G5_U5} );
        }
        
        my $fixed_feature_id_exe = $dbi->prepare( $Q->{get_U3_D5} );
        $fixed_feature_id_exe->execute( $design_id );
        my $fixed_feature_id = $fixed_feature_id_exe->fetchall_arrayref()->[0][0];
        
        $variable_feature_id_exe->execute( $design_id );
        my $variable_feature_id = $variable_feature_id_exe->fetchall_arrayref()->[0][0];
        
        my $get_seq_exe   = $dbi->prepare( $Q->{get_seq} );
        $get_seq_exe->execute( $fixed_feature_id );
        my $fixed_seq     = $get_seq_exe->fetchall_arrayref()->[0][0];
        
        $get_seq_exe->execute( $variable_feature_id );
        my $var_seq       = $get_seq_exe->fetchall_arrayref()->[0][0];
        
        my $get_chr = $dbi->prepare( $Q->{get_chr_strand} );
        $get_chr->execute( $design_id );
        my $chr     = $get_chr->fetchall_arrayref()->[0][0];        
                
        #Create a temp dir in /tmp/
        my $tmpdir = tempdir( CLEANUP => 1 );
                
        if ( $chr == -1 ) {
            _revcomp(\$fixed_seq);
            _revcomp(\$var_seq);
            sub _revcomp {
               my ( $seq_ ) = @_;
               $$seq_ =~ tr/[ATCGatcg]/[TAGCtagc]/;
               $$seq_ = reverse $$seq_;
            }   
        }
        
        open TMP, ">$tmpdir/seq" or $c->res->body( "<span><h6>Error:</h6><p>Failed to create sequence storage</p></span>" );
        my $path = cwd;
        #`cp script/short_range_primers/insertion_genotyping_vvi.pl $tmpdir/insertion_genotyping_vvi.pl`;
        
        #Gets same result as released version
        #`cp /software/team87/apache2/htdocs/htgt/script/short_range_primers/insertion_genotyping_vvi.pl $tmpdir/insertion_genotyping_vvi.pl`;
        #WHY WHY WHY WHY WHY DOES THIS NOT WORK?
        `cp /software/team87/apache2/htdocs/htgt/script/short_range_primers/insertion_genotyping_vvi.pl $tmpdir/insertion_genotyping_vvi.pl`;
        
        #This produces some odd results - repeats.
        #`cp /software/team87/apache2/htdocs/dk3/script/short_range_primers/vvi.pl $tmpdir/insertion_genotyping_vvi.pl`;
        
        my $current_working_dir = cwd; chdir $tmpdir;

        if ( $arm_choice =~ /3-arm/ ) { 
            print TMP ">tmp 1\n$fixed_seq\n[\n]\n$var_seq\n";
            system("./insertion_genotyping_vvi.pl seq $masking 3 $meltingTemp $amplicon_size $five_shim $three_shim ") ;
        }
        else { 
            print TMP ">tmp 1\n$var_seq\n[\n]\n$fixed_seq\n";
            system("./insertion_genotyping_vvi.pl seq $masking 5 $meltingTemp $amplicon_size $five_shim $three_shim ") ;
        }
                           
        
    #                                                                 #
    #                                                                 #
    # HACK HERE TO GET THREE PRIMERS IN WITH THE CORRECT PRODUCT SIZE #
    #                                                                 #
    #                                                                 #
        open FP, "primers.txt";
        my @Fprimes         = <FP>; close FP;
        #Hack to cope with three primers
        my @Forward  = ($Fprimes[0], $Fprimes[3], $Fprimes[6]);
        my @Backward = ($Fprimes[1], $Fprimes[4], $Fprimes[7]);
        my @Products = ($Fprimes[2], $Fprimes[5], $Fprimes[8]);
        
        for ( @Products ) { s/.*:\s+//g }
        
        for ( my $i = 0; $i < @Forward; $i++ ) {
            ( my $forward      = $Forward[$i]  ) =~ s/.*_F|FORWARD_SPARE://g;
            ( my $backward     = $Backward[$i] ) =~ s/.*_R|REVERSE_SPARE://g;
            my $product_size   = $Products[$i];
            
            push @{ $PRIMERS{forward} }, $forward;
            push @{ $PRIMERS{backward} }, $backward;            
            
            my $wt_product_size = $product_size;
            my $mt_product_size = $product_size;

            if ( $arm_choice =~ /^3-arm$/ ) {
                my $d5 = $c->model('HTGTDB::Feature')->find(
                    { design_id => $design_id, feature_type_id => 11 }
                );

                my $d3 = $c->model('HTGTDB::Feature')->find(
                    { design_id => $design_id, feature_type_id => 12 }
                );            

                if ( ! defined $d5 or ! defined $d3 ) {
                    $product_size = 'NaN';
                    last;
                }
                my $span = 0;

                if ( $chr == 1 ) { 
                    $span = abs( $d5->feature_end() - $d3->feature_start() );
                }
                else {
                    $span = abs( $d5->feature_start() - $d3->feature_end() );
                }

                $wt_product_size += $span;
                $mt_product_size += 80; #LoxP is a guess ATM
                $mt_product_size += $span; #Not sure about this need to speak to Viv
                push @{ $PRIMERS{product} }, $mt_product_size;                            
                push @{ $PRIMERS{wt_product} }, $wt_product_size;                            
            }
            elsif ( $arm_choice =~ /^5-arm$/ ) {

                my $u5 = $c->model('HTGTDB::Feature')->find(
                    { design_id => $design_id, feature_type_id => 9 }
                );

                my $u3 = $c->model('HTGTDB::Feature')->find(
                    { design_id => $design_id, feature_type_id => 10 }
                );

                if ( ! defined $u5 or ! defined $u3 ) {
                    $product_size = 'NaN';
                    last;
                }
               my $cas  = 250;
               my $span = 0;

               if ( $chr == 1 ) {
                   $span = abs( $u5->feature_start() - $u3->feature_end()   );
               }
               else {
                   $span = abs( $u5->feature_end()   - $u3->feature_start() );              
               }
               $mt_product_size += $cas;
                push @{ $PRIMERS{product} }, $mt_product_size;                                           
                push @{ $PRIMERS{wt_product} }, $wt_product_size;                            
            }
            else { #This block of code will NEVER execute#
                $c->res->body( "<span><h6>Error:</h6><p>There has been an error ...</p></span>" ); 
            }
            $c->stash->{wt_product_size} = "$wt_product_size";
            $c->stash->{mt_product_size} = "$mt_product_size";
        }
        
        # End of hack       
        chdir $current_working_dir;
    }
    $c->stash->{primers}  = \%PRIMERS;
    $c->stash->{template} = 'design/_primers.tt';
    $c->forward('HTGT::View::NakedTT');
}


sub _query_list : Private {
    my ( $dbi ) = @_;
    my %Q = (
        get_G5_U5          => "select distinct feature_id 
                               from feature 
                               where feature_type_id = 1000 and design_id = ?
                               ",
        get_U3_D5          => "select distinct feature_id 
                               from feature 
                               where feature_type_id = 1001 and design_id = ?
                               ",
        get_D3_G3          => "select distinct feature_id 
                               from feature 
                               where feature_type_id = 1002 and design_id = ?
                              ",                       
        get_seq            => "select data_item 
                               from feature_data 
                               where feature_id = ? and feature_data_type_id = 1
                               ",
        get_chr_strand     => "select mig.gnm_locus.chr_strand 
                               from mig.gnm_locus, design 
                               where design.design_id = ? and design.locus_id = mig.gnm_locus.id
                               ",
        get_gene_name      => "
                                select distinct mig.gnm_gene_name.name
                                from well_summary ws, mig.gnm_gene_name
                                where mig.gnm_gene_name.gene_id = ws.gene_id
                                and design_instance_id = ?
                                and mig.gnm_gene_name.source = 'MGI' 
                              ",
    );
    
    return(\%Q);
}


sub _search_suggestions : Local {
    my ( $self, $c ) = @_;
    my $href_param   = ( $c->request->parameters() );
    my $field        = $href_param->{'field'};
    my $text         = $href_param->{'text' };
    my $model        = $c->model(q(HTGTDB));
    my $dbh          = $model->storage->dbh;
    my $list         = '<ul>' ;
    
    my $sql;
    
    if    ( $field =~ /^design$/i         ) {
        $sql = "SELECT DISTINCT design.design_id FROM design WHERE design.design_id like '$text%' ";
    }
    
    elsif ( $field =~ /gene/i           ) {
        $sql = "SELECT DISTINCT gene_info.otter_id FROM gene_info WHERE otter_id like '$text%' AND rownum <= 30 ";
    }
    
    elsif ( $field =~ /exon/i           ) {
        $sql = "SELECT DISTINCT mig.gnm_exon.primary_name FROM mig.gnm_exon WHERE mig.gnm_exon.primary_name like '$text%' AND rownum <= 30 ";
    }
    
    elsif ( $field =~ /design_plate/i   ) {
        $sql = "SELECT DISTINCT design_plate_name FROM well_summary WHERE design_plate_name LIKE '%$text%' AND rownum <= 30 order by 1 ";
    }
    
    elsif ( $field =~ /instance_plate/i ) {
        $sql = "SELECT DISTINCT design_instance.plate FROM design_instance WHERE plate LIKE '$text%' ORDER BY 1";
    }
    
    elsif ( $field =~ /comment/i        ) {
        #we do nothing because comment is a pain in the arse
            $c->res->body($list);
    }
    
    else {
        $list = "<li>Opps, you tried a funny table!</li></ul>";
        $c->res->body($list);
    }
    
    my $sql_exe = $dbh->prepare($sql);
    $sql_exe->execute();
    
    my $result_set = $sql_exe->fetchall_arrayref();
    for ( @$result_set ) { $c->log->debug( ${$_}[0] );  $list .= "<li>$_->[0]</li>" }
    
    $list .= '</ul>';
    
    $c->res->body( $list );
    
    
}


=head1 AUTHOR

Dan Klose
Darren Oakley

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
