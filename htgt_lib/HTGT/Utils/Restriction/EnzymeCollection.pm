package HTGT::Utils::Restriction::EnzymeCollection;

use Moose;
use MooseX::Singleton;
use Bio::Restriction::IO;
use Bio::Restriction::EnzymeCollection;
use Path::Class;
use namespace::autoclean;
use version;
use Const::Fast;

# BioPerl 1.5 can't handle all the Rebase enzymes
const my $REQUIRED_BIOPERL_VERSION => version->parse( '1.6.1' );

with 'MooseX::Log::Log4perl';

has enzyme_collection => (
    isa      => 'Bio::Restriction::EnzymeCollection',
    handles  => [
        qw( enzymes each_enzyme get_enzyme available_list longest_cutter blunt_enzymes cutters )
    ],
    builder => '_build_enzyme_collection'
);

sub _build_enzyme_collection {
    my $self = shift;

    ( my $filename = __PACKAGE__ . ".pm" ) =~ s{::}{/}g;
    confess "failed to locate $filename in \%INC" unless defined $INC{$filename};
    my $rebase_path = file( $INC{$filename} )->dir->file( 'rebase.withrefm' );

    if ( version->parse( $Bio::Root::Version::VERSION ) >= $REQUIRED_BIOPERL_VERSION and defined $rebase_path and -r $rebase_path ) {
        $self->log->debug( "reading enzyme data from $rebase_path" );
        return Bio::Restriction::IO->new(
            -file   => $rebase_path,
            -format => 'withrefm',
        )->read;
    }
    else {
        $self->log->debug( "using BioPerl default enzyme collection" );
        return Bio::Restriction::EnzymeCollection->new;
    }
}

sub get_enzymes {
    my ( $self, @enzyme_names ) = @_;

    my @enzymes;
    for my $name ( @enzyme_names ) {
        my $enzyme = $self->get_enzyme( $name )
            or confess "no such enzyme: $name";
        push @enzymes, $enzyme;
    }
    
    my $enzyme_collection = Bio::Restriction::EnzymeCollection->new( -empty => 1 );
    $enzyme_collection->enzymes( @enzymes );

    return $enzyme_collection;
}


__PACKAGE__->meta->make_immutable;

1;

__END__
