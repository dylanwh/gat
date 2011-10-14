package Gat::Config;
use Moose;
use namespace::autoclean;

use Gat::Types ':all';
use MooseX::Types::Moose 'Maybe';
use Moose::Util::TypeConstraints 'enum';
use MooseX::Params::Validate;
use JSON ();

extends 'Config::GitLike';

has '+confname' => (default => 'gatconfig');

has 'gat_dir' => (
    is       => 'ro',
    isa      => AbsoluteDir,
    required => 1,
);

override "dir_file" => sub {
    my $self = shift;

    return $self->gat_dir->file('config');
};

override "load_dirs" => sub {
    my ($self, $path) = @_;
    # $path is ignored.

    $self->load_file($self->dir_file);
};

around 'group_set' => sub {
    my ($method, $self, $filename, @args) = @_;
    $filename //= $self->dir_file;

    $self->$method($filename, @args);
};

override "cast" => sub {
    my $self = shift;
    my ($value, $as, $human) = validated_list(\@_,
        value => { isa => 'Any' },
        as    => { isa => Maybe[enum['bool', 'int', 'num', 'json'] ], optional => 1},
        human => { isa => 'Bool', optional => 1 },
    );

    if ($as && $as eq 'json') {
        if ($human) {
            return JSON::encode_json($value);
        }
        else {
            return JSON::decode_json($value);
        }
    }
    else {
        return super;
    }
};

sub get_hash {
    my $self = shift;
    my ($key_prefix) = validated_list(\@_, key => { isa => 'Str' });
    my $key_re = qr/^\Q$key_prefix.\E/;
    my $info = $self->get_regexp(key => $key_re);

    foreach my $key (keys %$info) {
        my $new_key = $key;
        $new_key =~ s/$key_re//;
        $info->{$new_key} = delete $info->{$key};
    }

    return $info;
}

sub set_hash {
    my $self = shift;
    my ( $key_prefix, $value ) = validated_list(
        \@_,
        key   => { isa => 'Str' },
        value => { isa => 'HashRef[Str]' },
    );

    foreach my $key ( keys %$value ) {
        $self->set( key => "$key_prefix.$key", value => $value->{$key} );
    }
}

__PACKAGE__->meta->make_immutable;
1;
