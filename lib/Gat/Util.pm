package Gat::Util;
use strictures 1;
use Path::Class;
use Data::Stream::Bulk::Path::Class;
use Data::Stream::Bulk::Cat;
use Data::Stream::Bulk::Array;

use Sub::Exporter -setup => {
    exports => [qw[ file_stream ]],
};

sub file_stream {
    my @paths = @_;
    my (@streams, @files);

    foreach my $path (@paths) {
        if (-d $path) {
            push @streams, Data::Stream::Bulk::Path::Class->new(
                dir => dir($path),
                only_files => 1,
            );
        }
        else {
            push @files, file($path);
        }
    }

    return Data::Stream::Bulk::Cat->new(
        streams => [ 
            Data::Stream::Bulk::Array->new( array => \@files ),
            @streams,
        ],
    );
}


1;
