use MooseX::Declare;

class Gat::Model extends KiokuX::Model {
    our $VERSION   = 0.001;
    our $AUTHORITY = 'cpan:DHARDISON';

    use MooseX::Types::Path::Class 'File', 'Dir';
    use MooseX::Types::Moose ':all';
    use Digest;

    use Gat::Schema::Asset;
    use Gat::Schema::Name;

    method lookup_name(File $filename is coerce) { return $self->lookup("name:$filename") }
    method lookup_asset(Str $checksum) { return $self->lookup("asset:$checksum") }

    method add_file(File $filename is coerce, Str $checksum) {
        $self->txn_do(
            sub {
                my $asset = $self->lookup_asset($checksum);
                if (not $asset) {
                    $asset = Gat::Schema::Asset->new(
                        checksum => $checksum,
                    );
                }
                my $name = $self->lookup_name($filename);
                if (not $name) {
                    $asset->add_name(
                        Gat::Schema::Name->new(
                            filename => $filename,
                            asset => $asset,
                        )
                    );
                }
                else {
                    $asset->add_name($name);
                    $name->asset($asset);
                }
                $self->store($asset);
            }
        );
    }

    method names() {
        return Data::Stream::Bulk::Filter->new(
            filter => sub {
                my @result;
                for my $item (@$_) {
                    if ($item->isa('Gat::Schema::Asset')) {
                        push @result, $item->names;
                    }
                }
            },
            stream => $self->root_set,
        );
    }
}
