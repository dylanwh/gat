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
    handles  => { files => 'elements' },
);

has 'path' => (
    is       => 'ro',
    isa      => 'Gat::Path',
    required => 1,
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
    my $path = $self->path;

    return Data::Stream::Bulk::Filter->new(
        filter => sub {
            return [ 
                grep { $path->is_valid($_) && $path->is_allowed($_) } @$_
            ]
        },
        stream => $stream,
    );
}

__PACKAGE__->meta->make_immutable;
1;

