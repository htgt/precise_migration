package HTGT::Controller::Tools::EngSeqBuilder;

use strict;
use warnings;

use base 'Catalyst::Controller';

use HTGT::Utils::FetchHTGTEngSeqParams qw(fetch_htgt_genbank_eng_seq_params);
use EngSeqBuilder;
use File::Temp;
use Try::Tiny;
use Data::Dumper;
use HTGT::Constants qw( %CASSETTES %BACKBONES ); 
use Scalar::Util qw(openhandle);

$Data::Dumper::Maxdepth = 3;

sub index :Path :Args(0) {

    my ($self, $c) = @_;

    # Re-populate the stash in case of error return
    my @params = qw( design_id cassette backbone type targeted_trap );
    my $esb_params;
    foreach my $param (@params){
        $c->stash->{$param} = $c->req->param($param);
        $esb_params->{$param} = $c->req->param($param);
    }
    $c->stash->{ cassettes } = [ keys %CASSETTES ];
    $c->stash->{ backbones } = [ keys %BACKBONES ];

    return unless $c->req->param( 'generate_genbank' );
        
	# Attempt to write the genbank file and return it
	try{
		# Check design ID is an int
		my $design_id = $c->req->param('design_id');
		if( $design_id =~ /\D/){
			die ("Design ID \"$design_id\" must be a number\n");
		}
		
		my $fh_tmp = File::Temp->new() or die "Could not open temp file - $!";
        $esb_params->{filehandle} = $fh_tmp;
		
		$c->log->debug("Running EngSeqBuilder");
		#my $builder = EngSeqBuilder::Genbank::HTGT->new($esb_params);
	    $self->_write_genbank($c, $esb_params);
	    
	    # SeqIO writer is closing temp fh. need to reopen using name.
	    open (my $fh, "<", $fh_tmp->filename) 
	        or die ("Could not open temp file ".$fh_tmp." for reading - $!");
        $self->_download($c,$fh);
	}
	catch{
	    $c->stash->{error_msg} = UNIVERSAL::isa( $_, 'Throwable::Error' ) ? $_->message : $_;
	};
}

sub _download{
	 my ($self, $c, $fh) = @_;
	 
	 $c->log->debug("Downloading genbank file");
	 seek $fh, 0, 0 or die "Could not rewind temp filehandle - $!";
     
     my @name_fields;
     if ($c->req->param('type') eq "vector"){
     	@name_fields = qw(type cassette backbone design_id);
     }
     else{
     	@name_fields = qw(type cassette design_id);
     }
     my $filename = join "#", map{ $c->req->param($_) } @name_fields;
     $filename .= ".gbk";
     
     $c->res->content_type('text/plain');
     $c->res->header('Content-Disposition', qq[attachment; filename="$filename"]);
     $c->res->body(join "", <$fh>);
}

sub _write_genbank{
	my ($self, $c, $input_params) = @_;

    my $param_getter;
    
    # Check we have a filehandle to write to
	unless (openhandle($input_params->{filehandle})){
		die("filehandle attribute ".$input_params->{filehandle}." is not an open filehandle");
	}
            
    my $builder = EngSeqBuilder->new;

    # Get params relevant to design type
    my $eng_seq_params = fetch_htgt_genbank_eng_seq_params( $input_params );
    
    # Run appropriate EngSeqBuilder method
    my $eng_seq_method = $eng_seq_params->{'eng_seq_method'};

    my $seq = $builder->$eng_seq_method( %{ $eng_seq_params->{'eng_seq_params'} });
    
    # Write out sequence in genbank file
    my $seq_io = Bio::SeqIO->new( -fh => $input_params->{filehandle}, -format => 'genbank' );
    $seq_io->write_seq( $seq );

    return;
}

1;