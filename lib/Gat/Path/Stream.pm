package Gat::Path::Stream;
use Gat::Moose;
use namespace::autoclean;

use Path::Class;
use Data::Stream::Bulk::Path::Class;
use Data::Stream::Bulk::Cat;
use Data::Stream::Bulk::Array;

use MooseX::Types::Path::Class 'File', 'Dir';
use MooseX::Types::Moose 'ArrayRef', 'Str';

use Gat::Types 'Path', 'AbsoluteDir';
use Gat::Path;

has 'files' => (
    isa        => ArrayRef[Str|File|Dir],
    reader     => '_files',
    required   => 1,
);

has 'work_dir' => (
    reader   => '_work_dir',
    isa      => AbsoluteDir,
    required => 1,
);

has 'stream' => (
    init_arg   => undef,
    reader     => '_stream',
    does       => 'Data::Stream::Bulk',
    handles    => [qw[ next is_done list_cat ]],
    lazy_build => 1,
);

has 'sieve' => (
    reader   => '_sieve',
    isa      => 'Gat::Path::Sieve',
    required => 1,
);

with qw(Data::Stream::Bulk) => { -excludes => 'list_cat' };

sub _build_stream {
    my ($self) = @_;
    my (@streams, @paths);
    my $sieve = $self->_sieve;

    foreach my $file (@{ $self->_files }) {
        my $path = Gat::Path->new( file($file)->absolute( $self->_work_dir ));
        my $stat = $path->stat;

        die "File does not exist: $file" unless $stat;
        die "File not allowed: $path"    unless $sieve->match($path);
        warn "$path\n";

        if (-d $stat) {
            push @streams, Data::Stream::Bulk::Filter->new(
                filter => sub {
                    [
                        grep { $sieve->match($_) } map { Gat::Path->new($_) } @$_ 
                    ] 
                },
                stream => Data::Stream::Bulk::Path::Class->new(
                    dir        => dir( $path->filename ),
                    only_files => 1,
                )
            );
        }
        elsif (-f $stat) {
            push @paths, $path;
        }
    }

    return Data::Stream::Bulk::Cat->new(
        streams => [ Data::Stream::Bulk::Array->new( array => \@paths ), @streams ]
    );
}

__PACKAGE__->meta->make_immutable;
1;
