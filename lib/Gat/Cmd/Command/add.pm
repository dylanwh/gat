package Gat::Cmd::Command::add;
use Moose;
use namespace::autoclean;
use Gat::FileStream;

extends 'Gat::Cmd::Command';

has 'force' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub execute {
    my ( $self, $opt, $files ) = @_;
    my $c = Gat::Container->new(
        work_dir => $self->work_dir->absolute,
    );

    $c->check_workspace;

    my $model  = $c->fetch('Model/instance')->get;
    my $repo   = $c->fetch('Repository/instance')->get;
    my $path   = $c->fetch('Path')->get;
    my $config = $c->fetch('Config')->get;

    my $scope = $model->new_scope;
    my $stream = Gat::FileStream->new(files => $files);


    until ($stream->is_done) {
        for my $file ($stream->items) {
            die "invalid path: $file"    unless $path->is_valid($file);
            die "disallowed path: $file" unless $path->is_allowed($file) or $self->force;

            my $cfile = $path->canonical($file);
            my $afile = $path->absolute($file);

            my ($checksum, $stat) = $repo->insert(file => $afile);
            $repo->attach(
                file     => $afile,
                checksum => $checksum,
                symlink  => $config->get( key => 'repository.use_symlinks', as => 'bool' ),
            );
            $model->add_label($cfile, $checksum, $stat->size);
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;

