package Gat::Config;
use Moose;
use namespace::autoclean;

use Carp;
use File::Basename;

use Path::Class;
use Gat::Types 'AbsoluteFile';

extends 'Config::GitLike';

has '+confname' => ( default => 'config' );

sub dir_file {
    my ($self) = @_;

    return '.gat/config';
}

sub load_dirs {
    my ($self, $path) = @_;
    croak "$path required!\n" unless $path;

    my $file = dir($path)->file( $self->dir_file );
    $self->load_file( $file );
}

__PACKAGE__->meta->make_immutable;
1;
