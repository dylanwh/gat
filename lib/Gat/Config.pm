package Gat::Config;
use Moose;
use namespace::autoclean;

use Gat::Types 'AbsoluteDir';
use Path::Class;
use File::Basename;

extends 'Config::GitLike';

has '+confname' => ( default => 'config' );

has 'gat_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    required => 1,
);

sub dir_file {
    my ($self) = @_;
    
    return file(basename($self->gat_dir), $self->confname);
}

sub load_dirs {
    my ($self, $path) = @_;
    $path ||= $self->base_dir;
    my $file = dir($path)->file( $self->dir_file );
    $self->load_file( $file );
}

__PACKAGE__->meta->make_immutable;
1;
