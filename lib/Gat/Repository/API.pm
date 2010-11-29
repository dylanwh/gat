package Gat::Repository::API;

# ABSTRACT: The abstract repository API (handles physical file operations)

use Moose::Role;
use namespace::autoclean;

use Digest;

use MooseX::Types::Path::Class 'File';
use MooseX::Types::Moose 'Str';
use MooseX::Params::Validate;

has 'digest_type' => (
    is      => 'ro',
    isa     => Str,
    default => 'MD5',
);

requires 'insert', 'link', 'unlink', 'assets';

sub compute_checksum {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });

    my $digest = Digest->new($self->digest_type);
    my $fh     = $file->openr;
    $digest->addfile($fh);
    return $digest->hexdigest;
}

1;
