package Gat::Label;
use Gat::Moose;

use MooseX::Params::Validate;
use Gat::Types 'RelativeFile', 'AbsoluteDir';
use MooseX::Types::Moose 'Str';

use namespace::clean -except => ['meta'];

use overload fallback => 1, q{""} => 'stringify';

with 'MooseX::OneArgNew' => { type => RelativeFile | Str, init_arg => 'filename' },
     'MooseX::Clone';


has 'filename' => (
    is          => 'ro',
    isa         => RelativeFile,
    required    => 1,
    coerce      => 1,
    initializer => '_init_filename',
    handles     => ['stringify'],
);

sub to_path {
    my $self = shift;
    my ($base_dir) = pos_validated_list(\@_, { isa => AbsoluteDir });

    return Gat::Path->new( $self->filename->absolute( $base_dir ));
}

sub _init_filename {
    my ( $self, $filename, $set, $attr ) = @_;
    $set->($filename->as_foreign('Unix'));
}

__PACKAGE__->meta->make_immutable;

1;
