package HTGT::Utils::Report::GenericIterator;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use URI;
use Moose::Util::TypeConstraints;

requires qw( _build_iterator _build_columns _build_name );

subtype 'HTGT::Utils::Report::GenericIterator::URI' => as class_type( 'URI' );

coerce 'HTGT::Utils::Report::GenericIterator::URI'
    => from 'Str'
    => via { URI->new( $_ ) };

has schema => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
);

has name => (
    is         => 'rw',
    isa        => 'Str',
    lazy_build => 1,        
);

has csv_uri => (
    is   => 'rw',
    isa  => 'HTGT::Utils::Report::GenericIterator::URI',
);

sub csv_filename {
    my $self = shift;
    my $filename = $self->name;
    for ( $filename ) {
        s{\s+}{_}g;
        s{/}{}g;
    }
    return "$filename.csv";
}

has table_id => (
    is         => 'rw',
    isa        => 'Str | Undef',
    lazy_build => 1,
);

sub _build_table_id { undef }

has preamble => (
    is         => 'rw',
    isa        => 'Str | Undef',
    lazy_build => 1,
);

sub _build_preamble { undef }

has columns => (
    isa     => 'ArrayRef[Str]',
    traits  => [ 'Array' ],
    handles => {
        columns => 'elements'
    },
    lazy_build => 1,
);

has iterator => (
    is         => 'ro',
    isa        => 'Iterator',
    lazy_build => 1,    
);

sub has_next {
    shift->iterator->isnt_exhausted;
}

sub next_record {
    shift->iterator->value;
}

1;

__END__
