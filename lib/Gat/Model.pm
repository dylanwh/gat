package Gat::Model;
use Gat::Moose;
use namespace::autoclean;

use Gat::Types ':all';
use Gat::Asset;
use Gat::Label;

use Data::Stream::Bulk::DBIC;
use Data::Stream::Bulk::Util 'filter';

has 'schema' => (
    reader   => '_schema',
    isa      => 'Gat::Schema',
    required => 1,
    handles  => {
        _labels => [ 'resultset', 'Label' ],
        _assets => [ 'resultset', 'Asset' ],
        init    => 'deploy',
    },
);

sub bind {
    my $self = shift;
    my ($label, $asset) = pos_validated_list(\@_,
        { isa => Label },
        { isa => Asset },
    );

    my $db_asset = $self->_assets->find_or_create(
        {   
            checksum     => $asset->checksum,
            mtime        => $asset->mtime,
            size         => $asset->size,
            content_type => $asset->content_type,
        },
    );
    my $db_label = $db_asset->labels->find_or_create(
        { filename => $label->filename }
    );
}

sub unbind {
    my $self = shift;
    my ($label) = pos_validated_list(\@_, { isa => Label });

    $self->_labels->search( { filename => $label->filename } )->delete;
}

sub find_asset {
    my $self = shift;
    my ($label) = pos_validated_list( \@_, { isa => Label } );

    my $db_asset = $self->_labels->find( { filename => $label->filename } )->asset;

    return to_Asset($db_asset);
}

sub find_labels {
    my $self = shift;
    my ($asset) = pos_validated_list(\@_, { isa => Asset });

    my $stream = Data::Stream::Bulk::DBIC->new(
        resultset => scalar $self->_labels->search(
            { 'asset.checksum' => $asset->checksum },
            { join => 'asset' },
        )
    );

    return scalar filter { [ map { to_Label($_) } @$_ ] } $stream;
}

sub labels {
    my $self = shift;
    
    my $stream = Data::Stream::Bulk::DBIC->new( resultset => scalar $self->_labels);
    return filter { [ map { to_Label($_) } @$_ ] } $stream;
}

sub assets {
    my $self = shift;
    
    my $stream = Data::Stream::Bulk::DBIC->new( resultset => scalar $self->_assets);
    return filter { [ map { to_Asset($_) } @$_ ] } $stream;
}

__PACKAGE__->meta->make_immutable;

1;
