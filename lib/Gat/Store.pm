use 5.10.0;
use MooseX::Declare;

class Gat::Store {
    our $VERSION = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use TryCatch;
    use autodie;
    use MooseX::Types::Path::Class 'Dir', 'File';
    use MooseX::Types::Moose ':all';
    use MooseX::Types::Structured 'Tuple';
    use Digest;
    use Carp;
    use File::Copy::Reliable 'move_reliable';
    use List::MoreUtils 'first_value';

    use Gat::Types ':all';

    has 'digest_type' => (
        is      => 'ro',
        isa     => Str,
        default => 'MD5',
    );

    has 'storage_dir' => (
        is          => 'ro',
        isa         => Dir,
        coerce      => 1,
        initializer => '_init_dir',
        required    => 1,
    );

    has 'work_dir' => (
        is          => 'ro',
        isa         => Dir,
        coerce      => 1,
        initializer => '_init_dir',
        required    => 1,
    );

    has 'rules' => (
        traits  => ['Array'],
        is      => 'ro',
        isa     => ArrayRef [ Tuple [ RegexpRef, Bool ] ],
        default => sub { [] },
        handles => {
            add_rule  => 'push',
            all_rules => 'elements',
            has_rules => 'count',
        },
    );

    method BUILD {
        $self->storage_dir->mkpath;
    }

    method _init_dir($dir, $set, $attr) {
        my $abs_dir = $dir->absolute;
        try { $abs_dir = $abs_dir->resolve }
        $set->( $abs_dir );
    }

    method relative_to_work_dir(File $file) {
        return $file->relative($self->work_dir);
    }

    method is_storable(File $file) {
        my $work_dir    = $self->work_dir;
        my $storage_dir = $self->storage_dir;
        my $abs_file    = $file->absolute->resolve;

        return 0 unless index($abs_file, $work_dir) == 0;
        return 0 unless index($abs_file, $storage_dir) != 0;
        return 1 unless $self->has_rules;

        my $rel_file = $self->relative_to_work_dir($file);
        my $rule = first_value { $rel_file =~ $_->[0] } $self->all_rules;
        return $rule ? $rule->[1] : 0;
    }

    method _resolve(Checksum $checksum) {
        my $prefix = substr($checksum, 0, 2);
        return $self->storage_dir->subdir($prefix)->subdir($checksum);
    }

    method resolve(Checksum $checksum) {
        my $path = $self->_resolve($checksum);
        confess "Unknown asset: $checksum" unless -e $path;
        return $path;
    }

    method compute_checksum(File $file) {
        my $digest = Digest->new($self->digest_type);
        my $fh     = $file->openr;
        $digest->addfile($fh);
        return $digest->hexdigest;
    }

    method insert(File $file) {
        if ($self->is_storable($file)) {
            my $checksum   = $self->compute_checksum($file);
            my $asset_file = $self->_resolve($checksum);

            if (-f $asset_file) {
                unlink($file);
            }
            else {
                $asset_file->parent->mkpath;
                move_reliable($file, $asset_file);
            }

            return $checksum;
        }
        else {
            confess "cannot insert $file into store";
        }
    }

    method symlink(File $file, Checksum $checksum) {
        confess "file ($file) exists!" if -e $file;
        
        my $asset_file = $self->resolve($checksum)->relative($file->parent);
        $file->parent->mkpath;

        symlink($asset_file, $file);
    }

    method link(File $file, Checksum $checksum) {
        confess "file ($file) exists!" if -e $file;

        my $asset_file = $self->resolve($checksum);
        $file->parent->mkpath;
        link( $asset_file, $file);
    }

    method unlink(File $file, Checksum $checksum) {
        my $asset_file = $self->resolve($checksum);
        confess "$file is foreign" if $self->compute_checksum($file) ne $checksum;
        unlink( $file );
    }
}
