package Gat::Cmd::Command::Init;
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

    my $base_dir = $c->fetch('base_dir')->get;
    my $gat_dir  = $base_dir->subdir('.gat');
    $gat_dir->mkpath( $self->verbose );
    $gat_dir->subdir('model')->mkpath( $self->verbose );
    $gat_dir->subdir('asset')->mkpath( $self->verbose );

    my $rules_file = $gat_dir->file('rules');
    $rules_file->openw->print("");

    my $config_file = $gat_dir->file('config');
    my $config = $c->fetch('Config')->get;

    $config->set(
        key      => 'repository.attach_method',
        value    => 'symlink',
        filename => $config_file,
    );

   $config->set(
        key      => 'repository.digest_type',
        value    => 'MD5',
        filename => $config_file,
    );



    my $model = $c->fetch('Model')->get;
}

__PACKAGE__->meta->make_immutable;
1;
