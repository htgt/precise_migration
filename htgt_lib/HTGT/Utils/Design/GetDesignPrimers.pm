package HTGT::Utils::Design::GetDesignPrimers;

use Moose;
use namespace::autoclean;
use Const::Fast;
with 'MooseX::Log::Log4perl';

const my @COLUMN_NAMES         => ('design_id','marker_symbol', 'primer_name', 'sequence');
const my @SHORT_LOXP_PRIMERS   => ( 'PNFLR', 'LF', 'LR', );
const my $MAX_PRIMER_NUMBERS   => 3;
const my $PRIMER_RESULT_PREFIX => 'SRLOXP-';

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1
);

has input_data => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has designs => (
    is      => 'rw',
    isa     => 'HashRef[HTGTDB::Design]',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        has_designs    => 'count',
        add_design     => 'set',
        design_exists  => 'exists',
        get_design     => 'get',
    }
);

#design may be in multiple wells so store array of epd wells against designs
has design_epd_wells => (
    is  => 'rw',
    isa => 'HashRef[ArrayRef]',
    default => sub { {} },
);

#store epd wells entered as key, hash of current results as value
has epd_wells => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
    handles  => {
        epd_well_exists  => 'exists',
        set_epd_well     => 'set',
        epd_well_results => 'get'
    }
);

#store gene marker symbols entered so we can find duplicates
has gene_marker_symbols => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
    handles  => {
        gene_symbol_exists => 'exists',
        set_gene_symbol    => 'set',
    }    
);

around set_gene_symbol => sub {
    my $orig = shift;
    my $self = shift;
    my $marker_symbol = shift;

    $self->$orig( $marker_symbol, 1 );
};

has primer_feature_descriptions => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    lazy_build => 1,
);

sub _build_primer_feature_descriptions {
    my $self = shift;
    my @feature_descriptions;

    for my $feature_base_name (@SHORT_LOXP_PRIMERS) {
        map { push @feature_descriptions, $feature_base_name . $_ } ( 1 .. 3 );
    }

    return \@feature_descriptions;
}

#key design id, value hash of primer info
has design_primers => (
    is         => 'ro',
    isa        => 'HashRef',
    required   => 1,
    lazy_build => 1,
);

sub _build_design_primers {
    my $self = shift;

    my %design_primers;

    for my $design ( values %{ $self->designs } ) {
        my $primer_features = $design->features->search_rs(
            {
                'feature_type.description' => { 'IN' => $self->primer_feature_descriptions }
            },
            {   join     => 'feature_type',
                order_by => { -asc => 'feature_type.description' },
            }
        );
        next unless $primer_features->count;
        
        $design_primers{ $design->design_id }
            = [ map { $self->_get_primer_info($_) } $primer_features->all ];
    }
    return \%design_primers;
}


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

sub BUILD {
    my $self = shift;
    my @designs;

    if ( $self->input_data =~ /^$/ ) {
        $self->add_error("No Data Entered");
        return;
    }

    for my $datum ( $self->input_data =~ /(\w+)/gsm ) {
        if ( $datum =~ /EPD\d+/i ) {
            $self->_get_design_by_epd_well_name($datum);
        }
        else {
            $self->_get_design_by_marker_symbol($datum);
        }
    }
    return;
}

sub _get_design_by_epd_well_name {
    my ( $self, $well_name ) = @_;
    
    if ($self->epd_well_exists($well_name)) {
        $self->add_error( 'Duplicate epd well entered: ' . $well_name );
        return;
    }

    my $well = $self->schema->resultset('Well')->find( { well_name => $well_name } );
    unless ($well) {
        $self->add_error( 'EPD well does not exist: ' . $well_name );
        return;
    }
    
    my $plate = $well->plate;
    unless ( $plate->type eq 'EPD' ) {
        $self->add_error( "Well ($well_name) does not belong to a EPD plate "
                          . $plate->name . ' : ' . $plate->type );
        return;
    }
    
    my $design_instance = $well->design_instance;
    next unless $design_instance;
    my $design = $design_instance->design;
    my $design_id = $design->design_id;
    
    $self->add_design( $design_id => $design )
        unless $self->design_exists($design_id);
    $self->_get_epd_well_info($well);
    
    push @{ $self->design_epd_wells->{$design_id} }, $well_name;
    
    return;
}

sub _get_epd_well_info {
    my ($self, $well) = @_;
    my %primer_results;
    my $well_name = $well->well_name;
    
    my @well_data_type_names = map { $PRIMER_RESULT_PREFIX . $_ } @{ $self->primer_feature_descriptions };
    my $well_data = $well->well_data->search(
        {
            'data_type' => { 'IN' => \@well_data_type_names }
        }
    );
    
    unless ($well_data->count) {
        $self->set_epd_well($well_name);
        return
    }
    
    while ( my $well_data = $well_data->next ) {
        my $primer_name = $well_data->data_type;
        $primer_name =~ s/$PRIMER_RESULT_PREFIX//;
        $primer_results{$primer_name} = $well_data->data_value;
    }

    $self->set_epd_well($well_name => \%primer_results);
}

#for designs by marker symbol we do not know epd wells associated with the design so
#we just show primers for design, cannot update primer results or show well information
sub _get_design_by_marker_symbol {
    my ( $self, $marker_symbol ) = @_;
    
    if ($self->gene_symbol_exists($marker_symbol)) {
        $self->add_error( 'Duplicate gene marker symbol entered: ' . $marker_symbol );
        return;
    }

    my $mgi_gene = $self->schema->resultset('MGIGene')->find( { marker_symbol => $marker_symbol } );
    unless ($mgi_gene) {
        $self->add_error( 'Marker Symbol / EPD well does not exist: ' . $marker_symbol );
        return;
    }
    $self->set_gene_symbol($marker_symbol);

    my @projects = $mgi_gene->projects->search( {}, { columns => [qw/design_id/], distinct => 1 } );
    unless (@projects) {
        $self->add_error( 'Marker Symbol does not have any valid projects: ' . $marker_symbol );
        return;
    }

    for my $design ( grep { defined } map { $_->design } @projects ) {
        my $design_id = $design->design_id;
        $self->add_design($design_id => $design )
            unless $self->design_exists($design_id);
    }
    return;
}

sub _get_primer_info {
    my ( $self, $feature ) = @_;
    my %primer;
    
    my $feature_data = $feature->feature_data->find(
        { 'feature_data_type.description' => 'sequence' },
        { prefetch => 'feature_data_type' }
    );
    unless ($feature_data) {
        $self->add_error( 'Primer feature has no sequence: ' . $feature->feature_type->description
                          . ' feature id: ' . $feature->feature_id
                         );
        return;
    }
    
    $primer{sequence}    = $feature_data->data_item;
    $primer{primer_name} = $feature->feature_type->description;
    
    return \%primer;
}

sub create_report {
    my $self = shift;
    my %report;
    my @primers; 
    $report{columns} = \@COLUMN_NAMES;
    
    for my $design_id ( keys %{ $self->designs } ) {
        if ( exists $self->design_epd_wells->{$design_id} ) {
            for my $epd_well_name ( @{ $self->design_epd_wells->{$design_id} } ) {
                push @primers, @{ $self->_get_design_primers($self->get_design($design_id), $epd_well_name) };
            }
        }
        else {
            push @primers, @{ $self->_get_design_primers($self->get_design($design_id)) };
        }
    }
    $report{primers} = \@primers;

    return \%report;
}

sub _get_design_primers {
    my ($self, $design, $epd_well_name ) = @_;
    my @primers;
    
    my $marker_symbol = $design->info->mgi_gene->marker_symbol;
    my $design_id     = $design->design_id;
    
    unless ( exists $self->design_primers->{$design_id} ) {
        my %result;
        $result{design_id}     = $design_id;
        $result{marker_symbol} = $marker_symbol;
        $result{primer_name}   = 'No primers found';
        $result{sequence}      = 'N/A';
        push @primers, \%result;
        return \@primers;
    }
    
    my $epd_well_results = $epd_well_name ? $self->epd_well_results($epd_well_name) : undef;
    
    for my $primer ( @{ $self->design_primers->{$design_id} } ) {
        my %primer;
        my $primer_name = $primer->{primer_name};
        $primer{marker_symbol} = $marker_symbol;
        $primer{design_id}     = $design_id;
        $primer{sequence}      = $primer->{sequence};
        $primer{primer_name}   = $primer_name;
        
        if ($epd_well_name) {
            $primer{epd_well_name} = $epd_well_name;
            $primer{result} = $epd_well_results->{$primer_name}
                if exists $epd_well_results->{$primer_name};
        }

        push @primers, \%primer;
    }
    
    return \@primers;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
