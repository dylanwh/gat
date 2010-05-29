use MooseX::Declare;

class Gat {
    our $VERSION = 0.01;
    our $AUTHORITY = 'cpan:DHARDISON';

    use MooseX::Types::Path::Class 'File';

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

    method txn_do(CodeRef $code) {
        $self->model->txn_do($code, scope => 1);
    }

    method add(File $file) {
        unless ($self->selector->match($file)) {
            $self->logger->error("Can't add $file");
            return 0;
        }

        unless (-f $file) {
            $self->logger->error("$file is not a regular file!");
            return 0;
        }

        my $checksum = $self->storage->insert($file);
        $self->model->add_file($file, $checksum);
        $self->storage->link($file, $checksum);

        $self->logger->info("Added $file ($checksum)");
        return 1;
    }

    method drop(File $file) {
        if ($self->selector->match($file)) {
            my $checksum = $self->model->drop_file($file);
            $self->storage->unlink($file, $checksum);
            return 1;
        }
        else {
            return 0;
        }
    }
    
    method restore(File $file) {
        if ($self->selector->match($file)) {
        }
        else {
            return 0;
        }
    }

    method gc() { }

}
