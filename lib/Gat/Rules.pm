package Gat::Rules;
use Moose;
use feature 'switch';
use namespace::autoclean;

use Gat::Types 'RelativeFile', 'AbsoluteDir';

use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class 'File';
use MooseX::Types::Structured 'Tuple';

use List::MoreUtils 'first_value';
use MooseX::Params::Validate;
use Eval::Closure 'eval_closure';

has 'predicates' => (
    traits  => ['Array'],
    isa     => ArrayRef [ Tuple [ RegexpRef | CodeRef, Bool ] ],
    reader  => '_predicates',
    handles => { 'predicates' => 'elements', 'add_predicate' => 'push' },
    default => sub { [] },
);

has 'base_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    required => 1,
);

sub BUILD {
    my $self = shift;
    $self->load($self->base_dir);
}

sub is_allowed {
    my $self   = shift;
    my ($file) = pos_validated_list(\@_, { isa => RelativeFile, coerce => 1 });

    my $pred   = first_value { $file ~~ $_->[0] } $self->predicates;
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

    while (my $line = $fh->getline) {
        my $val = ($line =~ s/^!//) ? 0 : 1;
        $line =~ s/\s+#.*$//;
        $line =~ s/\s+$//;

        given ($line) {
            when (/^\s*\{(.+?)\}/) {
                my $code = "sub { local \$_ = shift; $1 }";
                my $func = eval_closure(
                    source      => $code, 
                    description => "$file, line " .  $fh->input_line_number,
                );
                $self->add_predicate( [$func, $val] );
            }
            when (/^\s*\/(.+?)\/$/) {
                $self->add_predicate( [qr/$1/, $val] );
            }
            when (/^(.+)/) {
                my $bang = $val ? '' : '!';
                warn "deprecated rule: $line, use $bang/$line/";
                $self->add_predicate( [qr/$1/, $val] );
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
