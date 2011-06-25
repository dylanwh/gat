package Gat::Path::Stream;
use Moose;
use namespace::autoclean;

use Path::Class;
use Data::Stream::Bulk::Path::Class;
use Data::Stream::Bulk::Cat;
use Data::Stream::Bulk::Array;

use Gat::Types 'Path';
use MooseX::Types::Moose 'ArrayRef';

has 'paths' => (
    traits   => ['Array'],
    reader   => '_paths',
    isa      => ArrayRef[Path],
    handles  => { _all_paths => 'elements' },
    required => 1,
);

has 'sieve' => (
    reader   => '_sieve',
    isa      => 'Gat::Path::Sieve',
    required => 1,
);

has '_stream' => (
    is         => 'ro',
    init_arg   => undef,
    does       => 'Data::Stream::Bulk',
    handles    => [qw[ next is_done list_cat ]],
    lazy_build => 1,
);

with qw(Data::Stream::Bulk) => { -excludes => 'list_cat' };

sub _build__stream {
    my ($self) = @_;
    my (@streams, @paths);

    my $sieve = $self->_sieve;

    foreach my $path ($self->_all_paths) {
        next unless $path->exists;

        if ($path->is_dir) {
            push @streams, Data::Stream::Bulk::Filter->new(
                filter => sub { [ map { Gat::Path->new(filename => $_) } @$_ ] },
                stream => Data::Stream::Bulk::Path::Class->new(
                    dir        => dir( $path->filename ),
                    only_files => 1,
                )
            );
        }
        elsif ($path->is_file) {
            push @paths, $path;
        }
    }

    return Data::Stream::Bulk::Filter->new(
        filter => sub {
            return [ grep { $sieve->match($_) } @$_ ];
        },
        stream => Data::Stream::Bulk::Cat->new(
            streams => [ Data::Stream::Bulk::Array->new( array => \@paths ), @streams, ],
        )
    );
}

__PACKAGE__->meta->make_immutable;
1;

