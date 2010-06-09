package Gat;
use Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class 'File';
use Guard;
use Cwd;

use Gat::Storage::API;
use Gat::Model;
use Gat::Selector;
use Gat::Types ':all';

has 'model' => (
    is       => 'ro',
    isa      => 'Gat::Model',
    required => 1,
);

has 'storage' => (
    is       => 'ro',
    does     => 'Gat::Storage::API',
    required => 1,
);

has 'selector' => (
    is       => 'ro',
    isa      => 'Gat::Selector',
    required => 1,
);

has 'work_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    required => 1,
);

sub txn_do {
    my ($self, $code) = @_;
    my $dir = cwd;
    scope_guard { chdir $dir };
    chdir $self->work_dir;
    $self->model->txn_do($code, scope => 1);
}

sub add {
    my ($self, $file) = @_;
    $self->selector->assert($file);

    unless (-f $file) {
        Gat::Error->throw(message => "$file is not a regular file!");
    }

    my $checksum = $self->storage->insert($file);
    $self->model->add_file($file, $checksum);
    $self->storage->link($file, $checksum);
}

sub drop {
    my ($self, $file) = @_;
    $self->selector->assert($file);

    my $checksum = $self->model->drop_file($file);
    $self->storage->unlink($file, $checksum);
}

sub restore {
    my ($self, $file) = @_;
    $self->selector->assert($file);
    my $label = $self->model->lookup_label($file);
    Gat::Error->throw(message => "$file is unkown to gat") unless $label;
    Gat::Error->throw(message => "$file exists") if -e $file;
    $self->storage->link($file, $label->checksum);
}

sub gc { }

__PACKAGE__->meta->make_immutable;

1;

__DATA__

=head1 NAME

Gat - A Glorious Asset Tracker

pants.
