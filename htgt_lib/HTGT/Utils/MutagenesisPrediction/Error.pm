package HTGT::Utils::MutagenesisPrediction::Error;

use Moose;
use namespace::autoclean;

extends 'Throwable::Error';

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__
