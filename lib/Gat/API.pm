use 5.10.0;
use MooseX::Declare;

class Gat::API {
    our $VERSION = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use MooseX::Types::Path::Class 'File';

    has 'model' => (
        is       => 'ro',
        isa      => 'Gat::Model',
        required => 1,
    );

    has 'store' => (
        is       => 'ro',
        isa      => 'Gat::Store',
        required => 1,
    );

    has 'config' => (
        is       => 'ro',
        isa      => 'Gat::Config',
        required => 1,
    );

    has 'config_file' => (
        is       => 'ro',
        isa      => File,
        coerce   => 1,
        required => 1,
    );

    method txn_do(CodeRef $code) {
        $self->model->txn_do($code, scope => 1);
    }

    method add(ArrayRef[File] $files) {
        my $store  = $self->store;
        my $model  = $self->model;
        my $config = $self->config;

        for my $file (@$files) {
            my $checksum = $store->insert($file);

            my $rel_file = $store->relative_to_work_dir($file);
            $model->add_file($rel_file, $checksum);

            if ($config->use_symlinks) {
                $store->symlink($file, $checksum);
            }
            else {
                $store->link($file, $checksum);
            }
        }
    }

    method remove(ArrayRef[File] $files) {
        my $store  = $self->store;
        my $model  = $self->model;

        for my $file (@$files) {
            my $rel_file = $store->relative_to_work_dir($file);

            my $checksum = $model->remove_file($rel_file);
            $store->unlink($file, $checksum);
        }
    }

    method save_config() {
        $self->config->store( $self->config_file . "" );
    }

}
