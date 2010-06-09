use feature 'say';
use MooseX::Declare;

class Gat::Cmd::Command::add
    extends Gat::Cmd::Command
{
    use Path::Class;
    use MooseX::Types::Path::Class 'File';
    use Data::Stream::Bulk::Path::Class;

    method invoke(Gat $gat, @args) {
        my $file = file(shift @args);
        say $gat->add($file) ? "added $file" : "failed to add $file";
    }
}

__END__

=head1 NAME

Gat::Cmd::Command::add - insert a file into the gat store.

=head1 SYNOPSIS

    gat add file [file2 [dir...]]


