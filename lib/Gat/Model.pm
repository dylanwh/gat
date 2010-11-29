package Gat::Model;

# ABSTRACT: Maintains the gat metadata

use Moose;
use namespace::autoclean;

use MooseX::Types::Moose ':all';
use MooseX::Params::Validate;

use Gat::Schema::Asset;
use Gat::Schema::Label;

use Gat::Types 'Checksum', 'RelativeFile';
use Gat::Error;

extends 'KiokuX::Model';

sub lookup_label { 
    my ($self, $file) = @_;
    return $self->lookup("label:$file");
}

sub lookup_asset {
    my ($self, $checksum) = @_;
    return $self->lookup("asset:$checksum");
}

sub add_file {
    my $self = shift;
    my ($file, $checksum) = pos_validated_list(
        \@_, 
        { isa => RelativeFile, coerce => 1 },
        { isa => Checksum }
    );

    my $asset = $self->lookup_asset($checksum);
    if (not $asset) {
        $asset = Gat::Schema::Asset->new(
            checksum => $checksum,
        );
    }

    my $label = $self->lookup_label($file);
    if (not $label) {
        $asset->add_label(
            Gat::Schema::Label->new(
                filename => $file,
                asset => $asset,
            )
        );
    }
    else {
        $asset->add_label($label);
        $label->asset($asset);
    }
    $self->store($asset);
}

sub drop_file {
    my $self = shift;
    my ($file) = pos_validated_list(
        \@_,
        { isa => RelativeFile, coerce => 1 }
    );

    my $label = $self->lookup_label($file);
    Gat::Error->throw( message => "$file is unknown to gat" ) unless $label;

    my $asset = $label->asset;
    $label->asset(undef);
    $asset->remove_label( $label );

    $self->deep_update( $asset );
    $self->delete( $label );

    return $asset->checksum;
}

sub manifest {
    my ($self) = @_;

    Data::Stream::Bulk::Filter->new(
        filter => sub {
            my @res;
            for my $item (@$_) {
                if ($item->isa('Gat::Schema::Asset')) {
                    push @res, map { [ $item->checksum, $_ ] } $item->files;
                }
            }
            return \@res;
        },
        stream => $self->root_set,
    );
}

__PACKAGE__->meta->make_immutable;

1;
