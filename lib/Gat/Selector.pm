use MooseX::Declare;

class Gat::Selector {
    our $VERSION = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use MooseX::Types::Moose ':all';
    use MooseX::Types::Structured 'Tuple';
    use MooseX::Types::Path::Class ':all';
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

    has 'work_dir' => (
        is      => 'ro',
        isa     => AbsoluteDir,
        coerce  => 1,
        default => sub {
            Path::Class::Dir->new('.')->resolve;
        },
    );

    has 'gat_dir' => (
        is      => 'ro',
        isa     => AbsoluteDir,
        coerce  => 1,
        default => sub { $_[0]->work_dir->subdir('.gat') },
    );

    method match(AbsoluteFile $file is coerce) {
        my $work_dir = $self->work_dir;
        my $gat_dir  = $self->gat_dir;

        return 0 unless index($file, $work_dir) == 0;
        return 0 unless index($file, $gat_dir)  != 0;

        my $rel_file = $file->relative( $work_dir );
        my $rule = first_value { $rel_file =~ $_->[0] } $self->all_rules;
        return $rule ? $rule->[1] : $self->rule_default;
    }

}
