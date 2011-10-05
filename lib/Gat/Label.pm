package Gat::Label;
use Moose;
use namespace::autoclean;

use MooseX::Params::Validate;
use Gat::Types 'RelativeFile', 'AbsoluteDir';
use MooseX::Types::Moose 'Str';

with 'MooseX::OneArgNew' => { type => RelativeFile | Str, init_arg => 'name' },
     'MooseX::Clone';

has 'name' => (
    is          => 'ro',
    isa         => RelativeFile,
    required    => 1,
    coerce      => 1,
    initializer => '_init_name',
);

sub to_path {
    my $self = shift;
    my ($base_dir) = pos_validated_list(\@_, { isa => AbsoluteDir });

    return Gat::Path->new( $self->name->absolute( $base_dir ));
}

sub _init_name {
    my ( $self, $name, $set, $attr ) = @_;
    $set->($name->as_foreign('Unix'));
}

__PACKAGE__->meta->make_immutable;

1;
