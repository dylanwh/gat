package Gat::Repository::API;
use Moose::Role;
use namespace::autoclean;

use Gat::Types ':all';
use MooseX::Types;
use MooseX::Params::Validate;

has 'gat_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

requires qw[ init add remove attach is_attached clone is_valid ];

# init()
# add(Path $path, Asset $asset)
# remove(Asset $asset)
# attach(Path $path, Asset $asset)
# detach(Path $path, Asset $asset)
# is_valid(Asset $asset) -> Bool
# is_attached(Path $path, Asset $asset)
# clone(Asset $asset) -> Path -- for editing files

sub detach {
    my $self = shift;
    my ($path, $asset) = pos_validated_list(\@_, { isa => Path }, { isa => Asset });

    if ($self->is_attached($path, $asset)) {
        $path->unlink; # path must exist of ->is_attached() returned true.
    }
}

1;
