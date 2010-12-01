package Gat::Rules;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class 'File';
use MooseX::Types::Structured 'Tuple';
use MooseX::Params::Validate;

use List::MoreUtils 'first_value';

has 'path' => (
    is       => 'ro',
    isa      => 'Gat::Path',
    required => 1,
);

has 'predicates' => (
    traits  => ['Array'],
    isa     => ArrayRef [ Tuple [ RegexpRef, Bool ] ],
    reader  => '_reader',
    handles => { 'predicates' => 'elements', 'add_predicate' => 'push' },
    default => sub { [] },
);

sub BUILD {
    my ($self) = @_;
    my $file = $self->path->gat_file('rules');
    if (-f $file and $self->predicates == 0) {
        my $fh = $file->openr;
        local $_;

        while ($_ = $fh->getline) {
            chomp;
            if (/^!(.+)$/) {
                $self->add_predicate( qr/$1/ => 0 );
            }
            elsif (/^\s*#/) {
                next;
            }
            else {
                $self->add_predicate( qr/$_/ => 1 );
            }
        }
    }
}

sub is_allowed {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });
    my $cfile  = $self->path->canonical( $file );

    my $pred   = first_value { $cfile =~ $_->[0] } $self->predicates;
    return $pred ? $pred->[1] : 1;
}


__PACKAGE__->meta->make_immutable;
1;
