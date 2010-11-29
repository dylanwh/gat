package Gat::Storage::API;

# ABSTRACT: The abstract storage API (handles physical file operations)

use Moose::Role;
use namespace::autoclean;

use MooseX::Types::Path::Class 'File';
use MooseX::Types::Moose 'Str';
use Digest;

has 'digest_type' => (
    is      => 'ro',
    isa     => Str,
    default => 'MD5',
);

requires 'insert', 'link', 'unlink', 'check', 'assets';

sub _compute_checksum {
    my ($self, $file) = @_;

    my $digest = Digest->new($self->digest_type);
    my $fh     = $file->openr;
    $digest->addfile($fh);
    return $digest->hexdigest;
}

1;
