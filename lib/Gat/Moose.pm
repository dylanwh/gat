package Gat::Moose;
use Moose ();
use MooseX::StrictConstructor ();
use Moose::Exporter;
use MooseX::Params::Validate;

Moose::Exporter->setup_import_methods(
    as_is => [ \&pos_validated_list ],
    also  => [ 'Moose', 'MooseX::StrictConstructor' ],
);

1;
