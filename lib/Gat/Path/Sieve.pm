package Gat::Path::Sieve;
use Moose;
use namespace::autoclean;
use feature 'switch';

use MooseX::Params::Validate;

use MooseX::Types::Moose ':all';
use MooseX::Types::Structured 'Tuple';


use Path::Class 'dir';
use List::MoreUtils 'first_value';

use Gat::Types ':all';

has 'rules' => (
    traits  => ['Array'],
    isa     => ArrayRef [ Tuple [ RegexpRef | CodeRef, Bool ] ],
    reader  => '_rules',
    handles => {
        'add_rule'  => 'push',
        'has_rules' => 'count',
        'rules'     => 'elements',
    },
    default => sub { [] },
);

has [ 'base_dir', 'gat_dir', 'asset_dir' ] => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

sub match {
    my $self = shift;
    my ($path) = pos_validated_list( \@_, { isa => Path } );

    return
           $self->_is_file($path)
        && $self->_is_valid( $path->filename )
        && $self->_is_allowed( $path->filename->relative( $self->base_dir ) );
}

sub _is_allowed {
    my ($self, $name) = @_;
    my $pred = first_value { $name ~~ $_->[0] } $self->rules;
    return $pred ? $pred->[1] : 1;
}

sub _is_valid {
    my ( $self, $file ) = @_;

    return
           $self->base_dir->subsumes($file)
        && !$self->gat_dir->subsumes($file)
        && !$self->asset_dir->subsumes($file);
}

sub _is_file {
    my ($self, $path) = @_;

    my $stat = $path->stat;
    return $stat->is_file if $stat->exists;
    return 1;
}

__PACKAGE__->meta->make_immutable;
1;
