use MooseX::Declare;

class Gat::Model
    extends KiokuX::Model
{
    use MooseX::Types::Path::Class 'File', 'Dir';
    use MooseX::Types::Moose ':all';
    use Digest;
    use Carp;

    use Gat::Schema::Asset;
    use Gat::Schema::Label;
    use Gat::Types 'Checksum';
    use Gat::Error;

    method lookup_label(File $file)         { return $self->lookup("label:$file")  }
    method lookup_asset(Checksum $checksum) { return $self->lookup("asset:$checksum") }

    method add_file(File $file, Checksum $checksum) {
        my $asset = $self->lookup_asset($checksum);
        if (not $asset) {
            $asset = Gat::Schema::Asset->new(
                checksum => $checksum,
            );
        }

        my $label = $self->lookup_label($file);
        if (not $label) {
            $asset->add_label(
                Gat::Schema::Label->new(
                    filename => $file,
                    asset => $asset,
                )
            );
        }
        else {
            $asset->add_label($label);
            $label->asset($asset);
        }
        $self->store($asset);
    }

    method drop_file(File $file) {
        my $label = $self->lookup_label($file);
        Gat::Error->throw( message => "$file is unknown to gat" ) unless $label;

        my $asset = $label->asset;
        $label->asset(undef);
        $asset->remove_label( $label );

        $self->deep_update( $asset );
        $self->delete( $label );

        return $asset->checksum;
    }

    method manifest() {
        Data::Stream::Bulk::Filter->new(
            filter => sub {
                my @res;
                for my $item (@$_) {
                    if ($item->isa('Gat::Schema::Asset')) {
                        push @res, map { [ $item->checksum, $_ ] } $item->files;
                    }
                }
                return \@res;
            },
            stream => $self->root_set,
        );
    }
}
