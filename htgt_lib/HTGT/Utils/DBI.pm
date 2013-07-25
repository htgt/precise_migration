package HTGT::Utils::DBI;

use base 'Exporter';

BEGIN {
    our @EXPORT      = qw( process_statement );
    our @EXPORT_OK   = @EXPORT;
    our %EXPORT_TAGS = ();
    
}

sub process_statement {
    my ( $c, $dbh, $sql ) = @_;
    
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    
    my $data = {};
    $data->{columns} = $sth->{NAME_lc};
    $data->{rows}    = $sth->fetchall_arrayref();
    
    return $data;
}

1;

__END__
