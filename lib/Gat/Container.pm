package Gat::Container;
use Moose;
use namespace::autoclean;

use Cwd;
use Carp;

use Bread::Board;
use Gat::Constants 'GAT_DIR';
use Gat::Types 'AbsoluteDir';

use Gat::Path;
use Gat::Path::Sieve;
use Gat::Path::Sieve::Util 'load_rules';
use Gat::Path::Stream;

use Gat::Repository;

extends 'Bread::Board::Container';

has '+name' => ( default => 'Gat' );

has 'base_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    coerce   => 1,
    required => 1,
);

sub BUILD {
    my ($self)   = @_;

    container $self => as {
        service 'base_dir' => $self->base_dir;

        service 'gat_dir' => (
            block        => sub { $_[0]->param('base_dir')->subdir(GAT_DIR) },
            dependencies => wire_names('base_dir'),
        );

        service 'asset_dir' => (
            block        => sub { $_[0]->param('gat_dir')->subdir('asset') },
            dependencies => wire_names('gat_dir'),
        );

        service 'rules_file' => (
            block        => sub { $_[0]->param('gat_dir')->file('rules') },
            dependencies => wire_names('gat_dir'),
        );

        service 'rules' => (
            block => sub {
                my $s = shift;
                return -f $s->param('rules_file')
                    ? load_rules( $s->param('rules_file') )
                    : [];
            },
            dependencies => wire_names('rules_file'),
        );

        service 'attach_method' => 'symlink';

        typemap 'Gat::Path::Sieve' => infer(
            dependencies => wire_names( qw[ base_dir gat_dir asset_dir rules ] ),
            parameters   => { rules => { optional => 1 } },
        );
        typemap 'Gat::Path::Stream' => infer;

        typemap 'Gat::Repository' => infer(
            dependencies => wire_names(qw[ asset_dir attach_method ])
        );
    };
}

__PACKAGE__->meta->make_immutable;

1;
