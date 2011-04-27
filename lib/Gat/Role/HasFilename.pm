package Gat::Role::HasFilename;
use MooseX::Role::Parameterized;
use namespace::autoclean;

parameter 'filename_isa' => (
    is       => 'ro',
    required => 1,
);

role {
    my $p = shift;

    has 'filename' => (
        is       => 'ro',
        isa      => $p->filename_isa,
        coerce   => 1,
        required => 1,
        initializer => '_cleanup_filename',
    );

    method "_cleanup_filename" => sub {
        my ( $self, $file, $set, $attr ) = @_;

        my @dirs;
        for my $dir ( File::Spec->splitdir( $file->stringify ) ) {
            if ( $dir eq '..' ) {
                pop @dirs if @dirs;
            }
            else {
                push @dirs, $dir;
            }
        }

        return $set->( Path::Class::File->new(@dirs) );
    };

    method "BUILDARGS" => sub {
        return +{ filename => $_[1] };
    };
};

1;
