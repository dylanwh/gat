use MooseX::Declare;

class Gat::Storage::Directory
    with Gat::Storage::API
{
    use File::Copy::Reliable 'move_reliable';

    use MooseX::Types::Path::Class 'File';
    use MooseX::Types::Moose ':all';
    use Gat::Types ':all';
    use Gat::Error;
    use Digest;

    use Data::Stream::Bulk::Path::Class;
    use Data::Stream::Bulk::Filter;

    has 'storage_dir' => (
        is       => 'ro',
        isa      => AbsoluteDir,
        coerce   => 1,
        required => 1,
    );

    has 'use_symlinks' => (
        is      => 'ro',
        isa     => Bool,
        default => 1,
    );

    method BUILD { $self->storage_dir->mkpath }
    
    method _resolve_safe(Checksum $checksum) {
        my $prefix = substr($checksum, 0, 2);
        return $self->storage_dir->subdir($prefix)->subdir($checksum);
    }

    method _resolve(Checksum $checksum) {
        my $file = $self->_resolve_safe($checksum);
        Gat::Error->throw( message => "invalid asset $file" )  unless -f $file;
        return $file;
    }

    method insert(File $file) {
        Gat::Error->throw(message => "$file does not exist")        unless -e $file;
        Gat::Error->throw(message => "$file is not a regular file") unless -f _;

        my $checksum   = $self->_compute_checksum($file);
        my $asset_file = $self->_resolve_safe($checksum);

        if (-f $asset_file) { # already have that, so remove it.
            unlink($file);
        }
        else {                                   # don't have it
            $asset_file->parent->mkpath;         # ensure path exists
            move_reliable($file, $asset_file);   # move the file over.
        }

        return $checksum;
    }

    method link(File $file, Checksum $checksum) {
        Gat::Error->throw( message => "Can't overwrite $file" ) if -e $file;

        my $asset_file = $self->_resolve($checksum);
        $file->parent->mkpath;

        if ($self->use_symlinks) {
            symlink( $asset_file->relative($file->parent), $file );
        }
        else {
            link( $asset_file, $file);
        }
    }

    method unlink(File $file, Checksum $checksum) {
        Gat::Error->throw(message => "$file does not exist")        unless -e $file;
        Gat::Error->throw(message => "$file is not a regular file") unless -f _;

        my $asset_file = $self->_resolve($checksum);
        if ($self->_compute_checksum($file) ne $checksum) {
            Gat::Error->throw( message => "Cannot unlink unmanaged file: $file" );
        }
        unlink( $file );
    }

    method check(File $file, Checksum $checksum) {
        my $asset_file = $self->_resolve_safe($checksum);

        return undef unless -e $asset_file;
        return 0     unless -e $file;
        return 0     unless $self->_compute_checksum($file) eq $checksum;
        return 1;
    }

    method assets() {
        return Data::Stream::Bulk::Filter->new(
            filter => sub { [ map { $_->basename } @$_ ] },
            stream => Data::Stream::Bulk::Path::Class->new(
                dir        => $self->storage_dir,
                only_files => 1,
            ),
        );
    }
}
