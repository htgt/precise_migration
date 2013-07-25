package HTGT::DBFactory::Lazy;

use Sub::Exporter -setup => {
    exports => [ qw( htgt htgt_dbh kermits kermits_dbh vector_qc vector_qc_dbh ) ],
    groups => {
        default  => [ qw( htgt kermits vector_qc ) ],
        handles  => [ qw( htgt_dbh kermits_dbh vector_qc_dbh ) ]
    }
};

use HTGT::DBFactory;

{
    my $htgt;
    
    sub htgt {
        $htgt ||= HTGT::DBFactory->connect( 'eucomm_vector', @_ );
    }

    sub htgt_dbh {
        my $x = htgt(@_);
        $x->storage->dbh;
    }
}

{
    my $kermits;

    sub kermits {
        $kermits ||= HTGT::DBFactory->connect( 'kermits', @_ );
    }

    sub kermits_dbh {
        kermits(@_)->storage->dbh;
    }    
}

{
    my $vector_qc;

    sub vector_qc {
        $vector_qc ||= HTGT::DBFactory->connect( 'vector_qc', @_ );
    }

    sub vector_qc_dbh {
        vector_qc(@_)->storage->dbh;
    }
}

1;

__END__
