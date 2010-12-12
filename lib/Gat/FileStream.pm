package Gat::FileStream;
use Moose;
use namespace::autoclean;

use Path::Class;
use Data::Stream::Bulk::Path::Class;
use Data::Stream::Bulk::Cat;
use Data::Stream::Bulk::Array;

has 'files' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => { file_list => 'elements' },
);


has 'file_stream' => (
    is         => 'ro',
    isa        => 'Data::Stream::Bulk::Cat',
    lazy_build => 1,
    handles    => [qw[ next is_done list_cat ]],
);

with qw(Data::Stream::Bulk) => { -excludes => 'list_cat' };

sub _build_file_stream {
    my ($self) = @_;
    my (@streams, @files);

    foreach my $file ($self->file_list) {
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

    return Data::Stream::Bulk::Cat->new(
        streams => [ 
            Data::Stream::Bulk::Array->new( array => \@files ),
            @streams,
        ],
    );
}

__PACKAGE__->meta->make_immutable;
1;

