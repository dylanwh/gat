package Gat::Path;
use Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class 'File', 'Dir';
use MooseX::Params::Validate;
use Gat::Types ':all';
use Path::Class;
use File::Spec;

with 'Gat::Role::HasFilename' => { filename_isa => AbsoluteFile };

sub to_label {
    my $self = shift;
    my ($ctx) = pos_validated_list( \@_, { isa => 'Gat::Context' } );

    return Gat::Label->new($self->filename->relative( $ctx->base_dir ));
}

sub is_valid {
    my $self = shift;
    my ($ctx) = pos_validated_list( \@_, { isa => 'Gat::Context' } );
    my $abs_file = $self->absolute($ctx);

    return $ctx->base_dir->subsumes($abs_file) && !$ctx->gat_dir->subsumes($abs_file);
}

__PACKAGE__->meta->make_immutable;
1;
