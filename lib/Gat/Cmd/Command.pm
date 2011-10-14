package Gat::Cmd::Command;
use Gat::Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class 'Dir';
use Gat::Util 'find_base_dir';

extends qw(MooseX::App::Cmd::Command);
with 'MooseX::Getopt::Dashes';

use Gat;

has 'gat' => (
    is      => 'ro',
    isa     => 'Gat',
    builder => '_build_gat',
    lazy    => 1,
);

sub _build_gat {
    my $self = shift;

    return Gat->new(
        base_dir => find_base_dir( $self->work_dir->absolute ),
        work_dir => $self->work_dir->absolute,
    );
}

has 'verbose' => (
    traits      => ['Getopt'],
    is          => 'ro',
    isa         => 'Bool',
    default     => 0,
    cmd_aliases => 'v',
);

has 'work_dir' => (
    traits      => ['Getopt'],
    is          => 'ro',
    isa         => Dir,
    default     => '.',
    coerce      => 1,
    cmd_aliases => 'C',
);

__PACKAGE__->meta->make_immutable;

1;
