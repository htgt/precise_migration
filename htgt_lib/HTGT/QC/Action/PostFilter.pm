package HTGT::QC::Action::PostFilter;

use Moose;
use MooseX::Types::Path::Class;
use Path::Class;
use HTGT::QC::Exception;
use YAML::Any;
use namespace::autoclean;

extends qw( HTGT::QC::Action );

has output_dir => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    traits   => [ 'Getopt' ],
    cmd_flag => 'output-dir',
    required => 1,
    coerce   => 1
);

sub execute {
    my ( $self, $opts, $args ) = @_;

    $self->log->debug( "Running post_filter" );

    for my $input_dir ( map { dir $_ } @{$args} ) {        
        for my $query_dir ( $input_dir->children ) {
            for my $target_yaml ( $query_dir->children ) {
                my $analysis = YAML::Any::LoadFile( $target_yaml );            
                if ( $self->is_wanted( $analysis ) ) {
                    my $this_out_dir = $self->output_dir->subdir( $query_dir->relative( $input_dir ) );
                    $this_out_dir->mkpath;                
                    my $out_file = $this_out_dir->file( $target_yaml->basename );
                    link $target_yaml, $out_file
                        or HTGT::QC::Exception->throw( "link $target_yaml, $out_file: $!" );                
                }
            }
        }        
    }    
}

sub is_wanted {
    confess 'is_wanted() must be overridden by a subclass';
}

__PACKAGE__->meta->make_immutable;

1;

__END__
