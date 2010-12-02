package Gat::Cmd::Command::init;
use Moose;
use namespace::autoclean;

use Gat::Container;

extends 'Gat::Cmd::Command';

sub execute {
    my ( $self, $opt, $files ) = @_;
   
    my $c = Gat::Container->new(
        work_dir => $self->work_dir->absolute,
        base_dir => $self->work_dir->absolute,
    );

    my $gat_dir = $c->fetch('gat_dir')->get;

    $gat_dir->mkpath($self->verbose);
    $gat_dir->subdir('asset')->mkpath($self->verbose);

    my $config_file = $gat_dir->file('config');
    my $config = $c->fetch('config')->get;

    $config->set(
        key      => 'repository.use_symlinks',
        value    => 0,
        as       => 'bool',
        filename => $config_file,
    );

    $config->set(
        key      => 'repository.digest_type',
        value    => 'MD5',
        filename => $config_file,
    );
}

__PACKAGE__->meta->make_immutable;
1;
