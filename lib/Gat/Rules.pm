package Gat::Rules;
use Gat::Moose;
use feature 'switch';
use namespace::autoclean;

use MooseX::Params::Validate;

use MooseX::Types::Moose ':all';
use MooseX::Types::Structured 'Tuple';
use MooseX::Types::Path::Class 'File';
use Gat::Types ':all';

use List::MoreUtils 'first_value';
use Eval::Closure 'eval_closure';

has 'predicates' => (
    traits  => ['Array'],
    isa     => ArrayRef [ Tuple [ RegexpRef | CodeRef, Bool ] ],
    reader  => '_predicates',
    handles => {
        'predicates'     => 'elements',
        'add_predicate'  => 'push',
        'has_predicates' => 'count',
    },
    default => sub { [] },
);

# operates on a label
sub is_allowed {
    my $self    = shift;
    my ($label) = pos_validated_list( \@_, { isa => Label } );
    my $file    = $label->filename;
    my $pred    = first_value { $file ~~ $_->[0] } $self->predicates;
    return $pred ? $pred->[1] : 1;
}

sub load_file {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });

    my $fh = $file->openr;
    local $_;

    while (my $line = $fh->getline) {
        my $val = ($line =~ s/^!//) ? 0 : 1;
        $line =~ s/\s+#.*$//;
        $line =~ s/\s+$//;

        given ($line) {
            when (/^\s*\{(.+?)\}/) {
                my $line = $fh->input_line_number;
                my $code = qq(#line $line "$file"\nsub { local \$_ = \$_[0]; $1 );
                my $func = eval_closure(
                    source      => $code, 
                );
                $self->add_predicate( [$func, $val] );
            }
            when (/^\s*\/(.+?)\/$/) {
                $self->add_predicate( [qr/$1/, $val] );
            }
            when (/^(.+)/) {
                my $bang = $val ? '' : '!';
                $self->add_predicate( [qr/$1/, $val] );
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
