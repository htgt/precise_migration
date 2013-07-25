package HTGT::Utils::UploadQCResults;

use Moose::Role;
use namespace::autoclean;
use MooseX::Types::IO 'IO';
use Perl6::Slurp;
use IO::File;

with 'MooseX::Log::Log4perl';
requires 'parse_csv';
requires '_build_csv_reader';
requires 'update_qc_results';

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1
);

has user => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has input => (
    is       => 'ro',
    isa      => 'IO',
    coerce   => 1,
    required => 1
);

has cleaned_input => (
    is         => 'ro',
    isa        => 'IO::File',
    lazy_build => 1,
);

sub _build_cleaned_input { 
    my $self = shift;

    my $input_file = IO::File->new_tmpfile() or die("Error creating Temp File: $!");
    my @data = split /\n|\r|\r\n/, slurp( $self->input );

    # remove blank csv lines ( just commas )
    my @cleaned_data = grep{ $_ !~ /^,*$/ } @data;
    my $cleaned_data = join "\n", @cleaned_data;

    $input_file->print($cleaned_data);
    $input_file->seek( 0, 0 );
    return $input_file;
}

has csv_reader => (
    is         => 'ro',
    isa        => 'CSV::Reader',
    lazy_build => 1,
);

has line_number => (
    is       => 'ro',
    isa      => 'Int',
    default  => 0,
    traits   => ['Counter'],
    handles  => { 
        inc_line_number   => 'inc',
        reset_line_number => 'reset'    
    }
);

has errors => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        clear_errors => 'clear',
        has_errors   => 'count',
        add_error    => 'push',
    }
);

has update_log => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        add_log     => 'push',
        has_updates => 'count',
        clear_log   => 'clear',
    }
);

1;

__END__
