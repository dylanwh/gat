package Gat::Cmd::Command;
use Moose;
use namespace::autoclean;

extends 'MooseX::App::Cmd::Command';
with 'MooseX::Getopt::Dashes';

use Try::Tiny;
use Cwd;
use MooseX::Types::Path::Class 'Dir';

use Gat::Container;

has 'container' => (
    traits     => ['NoGetopt'],
    is         => 'ro',
    isa        => 'Gat::Container',
    lazy_build => 1,
    handles    => ['app'],
);

has 'directory' => (
    traits  => [ 'Getopt' ],
    is      => 'ro',
    isa     => Dir,
    coerce  => 1,
    default => sub {cwd},
    cmd_aliases => ['C'],
);


sub _build_container { 
    my ($self) = @_;

    return Gat::Container->new(
        work_dir => $self->directory,
    );
}

sub execute {
    my ($self, undef, $args) = @_;
    my $gat = $self->app;
    try {
        $gat->txn_do(
            sub {
                $self->invoke($gat, @$args);
            }
        );
    }
    catch {
        if ($_->isa('Gat::Error')) {
            warn $_->message, "\n";
            exit 1;
        }
        else {
            die $_;
        }
    };
}

__PACKAGE__->meta->make_immutable;

1;
