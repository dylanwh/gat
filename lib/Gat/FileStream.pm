package Gat::FileStream;
use Moose;
use namespace::autoclean;

use Path::Class;
use Data::Stream::Bulk::Path::Class;
use Data::Stream::Bulk::Cat;
use Data::Stream::Bulk::Array;

has '_files' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    init_arg => 'files',
    required => 1,
    handles  => { files => 'elements' },
);

has 'filter' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_filter',
);

has 'file_stream' => (
    is         => 'ro',
    does       => 'Data::Stream::Bulk',
    lazy_build => 1,
    handles    => [qw[ next is_done list_cat ]],
);

with qw(Data::Stream::Bulk) => { -excludes => 'list_cat' };

sub _build_file_stream {
    my ($self) = @_;
    my (@streams, @files);

    foreach my $file ($self->files) {
        if (-d $file) {
            push @streams, Data::Stream::Bulk::Path::Class->new(
                dir        => dir($file),
                only_files => 1,
            );
        }
        else {
            push @files, file($file);
        }
    }

    my $stream = Data::Stream::Bulk::Cat->new(
        streams => [ 
            Data::Stream::Bulk::Array->new( array => \@files ),
            @streams,
        ],
    );

    if ($self->has_filter) {
        return Data::Stream::Bulk::Filter->new(
            filter => $self->filter,
            stream => $stream,
        );
    }
    else {
        return $stream;
    }
}

__PACKAGE__->meta->make_immutable;
1;

