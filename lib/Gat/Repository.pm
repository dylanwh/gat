package Gat::Repository;
use Moose;

use namespace::autoclean;
use feature 'switch';

use Gat::Types ':all';
use Gat::Constants ':all';
use Gat::Path;

use MooseX::Params::Validate;


has 'asset_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

has 'attach_method' => (
    is       => 'ro',
    isa      => AttachMethod,
    default  => 'copy',
);

# store(Path $path) -> Bool (true if stored, 0 if not)
sub store {
    my $self   = shift;
    my ( $path ) = pos_validated_list( \@_, { isa => Path });

    die "invalid path" unless $self->_is_valid($path);

    if ($path->exists) {
        my $asset_path = $self->_asset_path( $path->checksum );
        
        if ($asset_path->exists) {
            # already stored, so remove original
            # Is this a good idea?
            $path->unlink;
            return 0;
        }
        else {
            # move into asset dir
            $path->move($asset_path);
            $asset_path->chmod("a-w");
            return 1;
        }
    }
    else {
        # what to do here?
    }
}

# remove(Checksum $checksum)
sub remove {
    my $self   = shift;
    my ($checksum) = pos_validated_list( \@_, { isa => Checksum }  );
    my $asset_path = $self->_asset_path( $checksum );

    $asset_path->unlink if $asset_path->exists && $asset_path->is_file;
}

# attach(Path $path, Checksum $checksum)
sub attach {
    my $self = shift;
    my ( $path, $checksum ) = pos_validated_list( \@_, { isa => Path }, { isa => Checksum } );

    my $asset_path    = $self->_asset_path($checksum);
    my $attach_method = $self->attach_method;

    $asset_path->$attach_method( $path );
}

# detach(Path $path, Checksum $checksum)
sub detach {
    my $self = shift;
    my ( $path, $checksum ) = pos_validated_list( \@_, { isa => Path }, { isa => Checksum } );

    # unlink $path if it points to $checksum, error otherwise.
}

sub _asset_path {
    my ($self, $checksum) = @_;

    Gat::Path->new(
        filename => $self->asset_dir->file( substr($checksum, 0, 2), substr($checksum, 2) )
    );
}

__PACKAGE__->meta->make_immutable;

1;
