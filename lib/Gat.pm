use MooseX::Declare;

class Gat {
    # ABSTRACT: glorious asset tracker
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

    method txn_do(CodeRef $code) {
        my $dir = cwd;
        scope_guard { chdir $dir };
        chdir $self->work_dir;
        $self->model->txn_do($code, scope => 1);
    }

    method add(File $file) {
        $self->selector->assert($file);

        unless (-f $file) {
            Gat::Error->throw(message => "$file is not a regular file!");
        }

        my $checksum = $self->storage->insert($file);
        $self->model->add_file($file, $checksum);
        $self->storage->link($file, $checksum);
    }

    method drop(File $file) {
        $self->selector->assert($file);

        my $checksum = $self->model->drop_file($file);
        $self->storage->unlink($file, $checksum);
    }
    
    method restore(File $file) {
        $self->selector->assert($file);
        my $label = $self->model->lookup_label($file);
        Gat::Error->throw(message => "$file is unkown to gat") unless $label;
        Gat::Error->throw(message => "$file exists") if -e $file;
        $self->storage->link($file, $label->checksum);
    }

    method gc() { }

}

__END__

=head1 NAME

Gat - A Glorious Asset Tracker


