# ABSTRACT: Glorious Asset Manager
package Gat;
use Moose;
use Bread::Board::Declare;
use namespace::autoclean;

use Gat::Types ':all';
use Gat::Constants 'GAT_DIR';
use CHI;

has 'base_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    required => 1,
    coerce   => 1,
);

has 'work_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    required => 1,
    coerce   => 1,
);

has 'gat_dir' => (
    is    => 'ro',
    isa   => AbsoluteDir,
    block => sub {
        my $s  = shift;
        $s->param('base_dir')->subdir(GAT_DIR);
    },
    dependencies => [ 'base_dir' ],
);

has 'rules_file' => (
    is    => 'ro',
    isa   => AbsoluteFile,
    block => sub {
        my $s = shift;
        $s->param('gat_dir')->file('rules');
    },
    dependencies => ['gat_dir'],
);

has 'dsn' => (
    is    => 'ro',
    isa   => 'Str',
    block => sub {
        my $s = shift;
        return 'dbi:SQLite:dbname=' . $s->param('gat_dir')->file('model.db');
    },
    dependencies => ['gat_dir'],
);

has 'schema' => (
    is    => 'ro',
    isa   => 'Gat::Schema',
    block => sub {
        my $s = shift;
        Gat::Schema->connect( $s->param('dsn'), undef, undef,
            { RaiseError => 1, PrintError => 0, AutoCommit => 1 } );
    },
    dependencies => ['dsn'],
);

has 'model' => (
    is           => 'ro',
    isa          => 'Gat::Model',
    dependencies => ['schema'],
);

has 'config' => (
    is           => 'ro',
    isa          => 'Gat::Config',
    dependencies => ['gat_dir'],
    lifecycle    => 'Singleton',
);

has 'rules' => (
    is    => 'ro',
    block => sub {
        my $s    = shift;
        my $file = $s->param('rules_file');
        return -f $file ? load_rules($file) : [];
    },
    dependencies => ['rules_file'],
);

has 'sieve' => (
    is           => 'ro',
    isa          => 'Gat::Path::Sieve',
    dependencies => [ qw[ rules gat_dir base_dir ] ],
);

has 'path_stream' => (
    is           => 'bare',
    isa          => 'Gat::Path::Stream',
    infer        => 1,
    dependencies => [qw[ work_dir ]],
    parameters   => { files => { optional => 0 } },
);

has 'digest_type' => (
    is           => 'ro',
    isa          => 'Str',
    block        => sub {
        my $s = shift;
        $s->param('config')->get(key => 'asset_factory.digest_type');
    },
    dependencies => ['config'],
);

has 'asset_factory' => (
    is           => 'ro',
    isa          => 'Gat::Asset::Factory',
    dependencies => ['digest_type', 'file_mmagic', 'cache'],
);

has 'cache' => (
    is    => 'ro',
    isa   => 'CHI::Driver',
    block => sub {
        my $s = shift;
        CHI->new( driver => 'Memory', global => 1 ),;
    },
);

has 'file_mmagic' => (
    is    => 'ro',
    isa   => 'File::MMagic',
    block => sub { File::MMagic->new },
);

has 'repository' => (
    is    => 'ro',
    isa   => 'Gat::Repository',
    block => sub {
        my $s      = shift;
        my $args   = $s->param('config')->get_hash( key => 'repository' );
        my $format = delete $args->{format};

        return Gat::Repository->new(
            format      => $format,
            gat_dir     => $s->param('gat_dir'),
            format_args => $args
        );
    },
    dependencies => ['gat_dir', 'config'],
    lifecycle    => 'Singleton',
);

sub path_stream {
    my ($self, $files) = @_;
    $self->resolve(service => 'path_stream', parameters => { files => $files });
}

__PACKAGE__->meta->make_immutable;

1;
