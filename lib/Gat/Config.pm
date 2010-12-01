package Gat::Config;
use Moose;
use namespace::autoclean;

use Path::Class;

extends 'Config::GitLike';

has '+confname' => ( default => 'config' );

has 'path' => (
    is       => 'ro',
    isa      => 'Gat::Path',
    required => 1,
);

sub dir_file {
    my ($self) = @_;
    
    return dir($self->path->gat_dir_name)->file('config');
}

sub load {
    my ($self, $path) = @_;
    $path ||= $self->path->base_dir;
    $self->SUPER::load($path);
}

sub load_dirs {
    my ($self, $path) = @_;
    my $file = dir($path)->subdir( $self->dir_file );
    $self->load_file( $file );
}


__PACKAGE__->meta->make_immutable;
1;

