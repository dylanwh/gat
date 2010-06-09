use MooseX::Declare;

role Gat::Storage::API {
    use MooseX::Types::Path::Class 'File';
    use MooseX::Types::Moose 'Str';
    use Digest;

    has 'digest_type' => (
        is      => 'ro',
        isa     => Str,
        default => 'SHA1',
    );

    method _compute_checksum(File $file) {
        my $digest = Digest->new($self->digest_type);
        my $fh     = $file->openr;
        $digest->addfile($fh);
        return $digest->hexdigest;
    }

    requires 'insert', 'link', 'unlink', 'check', 'assets';
}
