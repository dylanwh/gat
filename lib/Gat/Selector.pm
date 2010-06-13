package Gat::Selector;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose ':all';
use MooseX::Types::Structured 'Tuple';
use MooseX::Types::Path::Class ':all';

use Path::Class;

use List::MoreUtils 'first_value';
use Gat::Types ':all';

has 'rules' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => ArrayRef [ Tuple [ RegexpRef, Bool ] ],
    default => sub { [] },
    handles => {
        'all_rules' => 'elements',
        'add_rule'  => 'push',
    },
);

has 'rule_default' => (
    is       => 'ro',
    isa      => Bool,
    default  => 1,
);

has 'base_dir' => (
    is      => 'ro',
    isa     => AbsoluteDir,
    coerce  => 1,
    default => sub { Path::Class::Dir->new('.')->resolve  },
);

has 'gat_dir' => (
    is      => 'ro',
    isa     => AbsoluteDir,
    coerce  => 1,
    lazy    => 1,
    default => sub { $_[0]->base_dir->subdir('.gat') },
);

sub match {
    my ($self, $file) = @_;
    my $base_dir = $self->base_dir;
    my $gat_dir  = $self->gat_dir;

    $file = blessed $file ? $file : file($file);
    if ($file->is_relative) {
        $file = $file->absolute( $base_dir );
    }

    return 0 unless index($file, $base_dir) == 0;
    return 0 unless index($file, $gat_dir)  != 0;

    my $rel_file = $file->relative( $base_dir );
    my $rule = first_value { $rel_file =~ $_->[0] } $self->all_rules;
    return $rule ? $rule->[1] : $self->rule_default;
}

sub assert {
    my ($self, $file) = @_;

    unless ($self->match($file)) {
        Gat::Error->throw(message => "gat has been configured to ignore $file");
    }
}

__PACKAGE__->meta->make_immutable;

1;
