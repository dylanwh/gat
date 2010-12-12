package Gat::Rules;
use Moose;
use namespace::autoclean;

use Gat::Types 'RelativeFile';

use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class 'File';
use MooseX::Types::Structured 'Tuple';


use List::MoreUtils 'first_value';
use MooseX::Params::Validate;

has 'predicates' => (
    traits   => ['Array'],
    isa      => ArrayRef [ Tuple [ RegexpRef, Bool ] ],
    
    init_arg => undef,
    reader   => '_predicates',
    handles  => { 'predicates' => 'elements', 'add_predicate' => 'push' },
    default  => sub { [] },
);

sub is_allowed {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => RelativeFile, coerce => 1 });

    my $pred   = first_value { $file =~ $_->[0] } $self->predicates;
    return $pred ? $pred->[1] : 1;
}

sub load {
    my ($self, $base_dir) = @_;
    my $file = $base_dir->file('.gat', 'rules');
    $self->load_file($file) if -f $file;
}

sub load_file {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });

    my $fh = $file->openr;
    local $_;

    while ($_ = $fh->getline) {
        chomp;
        if (/^!(.+)$/) {
            $self->add_predicate([qr/$1/ => 0 ]);
        }
        elsif (/^\s*#/) {
            next;
        }
        else {
            $self->add_predicate([qr/$_/ => 1 ]);
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
