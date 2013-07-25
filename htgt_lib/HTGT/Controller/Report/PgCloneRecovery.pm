package HTGT::Controller::Report::PgCloneRecovery;

use warnings;
use strict;
use base 'Catalyst::Controller';
use Data::Dumper;
require Exporter;

our @ISA     = qw(Exporter);
our @EXPORT  = qw(
                    test
                    complete_search
                ); 

my %sql_queries = (
    get_primary_and_pgdgr_name => (q/SELECT DISTINCT         
                                        gg.primary_name, 
                                        ws.pgdgr_plate_name, 
                                        ws.pgdgr_well_id, 
                                        gi.otter_id, 
                                        gi.ensembl_id, 
                                        ws.pcs_plate_name,
                                        ws.design_well_name,
                                        ws.design_plate_name,
                                        ws.design_instance_id                                      
                                    
                                    FROM 
                                        well_summary ws,
                                        mig.gnm_gene gg, 
                                        gene_info gi
                                    
                                    WHERE REGEXP_LIKE (ws.pgdgr_plate_name, 'PRPGD|PRPGS')
                                    AND gg.id = ws.gene_id
                                    AND gi.gene_id = ws.gene_id
                                  /),
                                  
    get_well_data              => (q/SELECT 
                                        well.plate_id,
                                        well.well_id, 
                                        wd.data_value, 
                                        wd.data_type, 
                                        well.well_name
         
                                    FROM 
                                        well, 
                                        well_data wd
                                        
                                    WHERE well.well_id = ? and wd.well_id = well.well_id
                                    AND ( (wd.data_type  = 'DNA_STATUS' or wd.data_type = 'DNA_QUALITY') )
                                    
                                  /),
    
    get_epd_pass_info           => (q/SELECT
                                        gi.mgi_symbol,
                                        ws.pgdgr_plate_name,
                                        ws.ep_plate_name,
                                        ws.epd_well_id,
                                        ws.epd_pass_level,
                                        ws.colonies_picked
                                        
                                    FROM
                                        well_summary ws,
                                        gene_info gi
                                        
                                    WHERE ws.pgdgr_plate_name = ?
                                    AND   gi.mgi_symbol = ?
                                    AND   gi.gene_id = ws.gene_id
                                    
                                    /),
    get_clone_names              => (q/
                                    select data_value from well_data where data_type = 'clone_name' and well_id = ?
                                    /),                  
);

sub complete_search {
    my ( $self, $c, $search_on, $text, $filter, $colony_limit ) = @_;

    my $model = $c->model(q(HTGTDB));
    my $dbh   = $model->storage->dbh;
    my $q     = $sql_queries{get_primary_and_pgdgr_name};
    
    my %look = (
        'Otter ID'   => " AND gi.otter_id   = '$text' ",
        'MGI Symbol' => " AND gi.mgi_symbol = '$text' ",
        'EnsEMBL ID' => " AND gi.ensembl_id = '$text' ",
    );
        
    if ( $search_on !~ /every/ ) {
        $q .= $look{ $search_on };
    }
    
    my $q_exe = $dbh->prepare( $q );
    $q_exe->execute();
    
    my %info = ();
    
    my @headers = qw( mgi otter ensembl design_instance_id design_plate_name design_well_name plate_name well_id well_name type value pgdgr pgdgr_clone_name colonies status );

    while( my $row = $q_exe->fetchrow_arrayref() ) {
        clean_row($row);
        my $mgi           = $row->[0];
        my $plate_name    = $row->[1];
        my $well_id       = $row->[2];
        my $ott           = $row->[3];
        my $ens           = $row->[4];
        my $pcs_name      = $row->[5];
        my $dwn           = $row->[6];#ws.design_well_name;
        my $dpn           = $row->[7];#ws.design_plate_name;
        my $did           = $row->[8];#design_instance_id;

        next if $well_id !~ /^\d+$/;
        
        my $get_well_data = $sql_queries{get_well_data};
        my $gwd_exe       = $dbh->prepare( $get_well_data );
        $gwd_exe->execute( $well_id );
        
        while ( my $gwd_row = $gwd_exe->fetchrow_arrayref() ) {
            clean_row( $gwd_row );
            my $plate_id    = $gwd_row->[0];
            my $well_id     = $gwd_row->[1];
            my $value       = $gwd_row->[2];
            my $type        = $gwd_row->[3];
            my $well_name   = $gwd_row->[4];
            
            my $gcn = $sql_queries{get_clone_names};
            my $gcn_e = $dbh->prepare($gcn);
            $gcn_e->execute($well_id);
            my $rs = $gcn_e->fetchall_arrayref();
            
            $info{ $mgi }{mgi}                = $mgi;                
            $info{ $mgi }{ensembl}            = $ens;
            $info{ $mgi }{otter}              = $ott;
            $info{ $mgi }{well_id}            .= "$well_id ";
            $info{ $mgi }{well_name}          .= "$well_name ";            
            $info{ $mgi }{plate_name}         .= "$pcs_name ";
            $info{ $mgi }{pcs_name}           .= "$pcs_name ";
            $info{ $mgi }{type}               .= "$type ";                                    
            $info{ $mgi }{value}              .= "$value ";
            $info{ $mgi }{pgdgr}              .= "$plate_name ";
            $info{ $mgi }{colonies}           .= "";
            $info{ $mgi }{status}             .= "";
            $info{ $mgi }{design_well_name}   .= "$dwn ";
            $info{ $mgi }{design_plate_name}  .= "$dpn ";
            $info{ $mgi }{design_instance_id} .= "$did ";
            #This line is included to get the clone names for Darren.  The fourth
            #query to do this means I don't have to do a slow join in the second query
            $info{ $mgi }{pgdgr_clone_name}   = $rs->[0][0] || '-';
            #print Dumper %info; #This is ok.
            
        }   
    }
    
    for my $k1 ( keys %info ) {
        my $gene_symbol  = $k1;
        my $pgdgr_plates = $info{$k1}{pgdgr};
        my @plates  = split /\s+/, $pgdgr_plates;
        my $sql     = $sql_queries{get_epd_pass_info};
        my $epd_exe = $dbh->prepare($sql);

        for my $plate ( @plates ) {
                    
            $epd_exe->execute($plate, $gene_symbol);
            while( my $r = $epd_exe->fetchrow_arrayref() ) {
                clean_row($r);
                my $colonies = $r->[5];
                my $status   = $r->[4];
                $info{ $k1 }{colonies} .= "$colonies ";
                $info{ $k1 }{status}   .= "$status "; 
            }
        }
        
        #print Dumper %info; #Ok here
        
        my $colonies = $info{$k1}{colonies};
        my $status   = $info{$k1}{status};
        
        $colonies =~ s/-|\s+/ /g;
        $colonies =~ s/^\s+//; $colonies =~ s/\s+$//;
        $status =~ s/-|\s+/ /g;
    
        my @c = split /\s+/, $colonies;
        @c = sort { $b <=> $a } @c;
        my $max_count = $c[0];
        $max_count = 0, if ! $max_count or $max_count !~ /\d/;
         
        #print Dumper "The number of colonies: ($max_count :: $colony_limit)";
        if ( $max_count >= $colony_limit ) { delete $info{$k1}; next; }
        #Remove the little bastards if they do/don't meet the Dave standards.
        if ( $filter =~ /fail/i ) { 
             $status =~ s/-|fail|\s+//ig;            
             my @e = $info{$k1}{status};
             @e = grep { ! /-/ }@e;
             delete $info{$k1} if length $status > 0 || scalar @e == 0;            
        }
        elsif ( $filter =~ /pass123/i ) {
            $status =~ s/-|fail|pass4|pass5\s+//ig;
            my @e = $info{$k1}{status};
            @e = grep { ! /-/ }@e;
            delete $info{$k1} if length $status > 0 || scalar @e == 0;            
        }
        elsif ( $filter =~ /pass1234/i ) {
            $status =~ s/-|fail|pass5|\s+//ig;
            my @e = $info{$k1}{status};
            @e = grep { ! /-/ }@e;
            delete $info{$k1} if length $status > 0 || scalar @e == 0;            
        }
        else {
            $status =~ s/-|fail|\s+//ig;            
            my @e = $info{$k1}{status};
            @e = grep { ! /-/ }@e;
            
            delete $info{$k1} if length $status > 0 || scalar @e == 0;
        }
    }
    
    #print Dumper %info; #Fucked here!
    
    clean_and_tidy($self, $c, \%info, \@headers);
    
    return (\%info, \@headers);
}

sub clean_and_tidy {
    my ($self, $c, $href, $aref ) = @_;    
    for my $k ( keys %$href ) {
        $href->{ $k }{well_id}    = _compress_row( \$href->{ $k }{well_id}, $c, $self);
        $href->{ $k }{well_name}  = _compress_row( \$href->{ $k }{well_name}, $c, $self);
        $href->{ $k }{plate_name} = _compress_row( \$href->{ $k }{plate_name}, $c, $self);
        $href->{ $k }{pcs_name}   = _compress_row( \$href->{ $k }{pcs_name}, $c, $self);
        $href->{ $k }{type}       = _compress_row( \$href->{ $k }{type}, $c, $self);
        $href->{ $k }{value}      = _compress_row( \$href->{ $k }{value}, $c, $self);
        $href->{ $k }{pgdgr}      = _compress_row( \$href->{ $k }{pgdgr}, $c, $self);   
        $href->{ $k }{colonies}   = _compress_row( \$href->{ $k }{colonies}, $c, $self , 1);
        $href->{ $k }{status}     = _compress_row( \$href->{ $k }{status}, $c, $self);       
        
        $href->{ $k }{design_well_name}      = _compress_row( \$href->{ $k }{design_well_name}, $c, $self);       
        $href->{ $k }{design_plate_name}     = _compress_row( \$href->{ $k }{design_plate_name}, $c, $self);         
        $href->{ $k }{design_instance_id}     = _compress_row( \$href->{ $k }{design_instance_id}, $c, $self);         
    }
}

sub _compress_row {
    my ( $string_ref , $c, $self, $get_max_val ) = @_;
    
    my @ary = split /\s+/, $$string_ref;
    
    #for ( @ary )  { $c->log->debug($_) }
    
    my %hash = ();
    for ( @ary ) { $hash{$_} = 1 }
    
    if ( $get_max_val ) {
        my $max = 0;
        for (my $i = 0; $i < @ary; $i++ ) {
            $max = $ary[$i], if $ary[$i] > $max;
        }   
        return($max);
    }
    else {
        my $string = join (" ", keys %hash);
        $string =~ s/-//g;
        return($string);
    }
    
}


sub clean_row {
    my ( $array_ref ) = @_;
    for ( @$array_ref ) { 
        if ( ! defined ) { $_ = '-' }
    }
}
