# ABSTRACT: A Glorious Asset Tracker

package Gat;
use strictures;

use Gat::Container;
use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class ':all';
use MooseX::Params::Validate;

# Gat::init( { work_dir => Dir } )
# Gat::add({ work_dir => Dir, files => ArrayRef[File], force => Bool })
# Gat::rm({ work_dir => Dir, files => ArrayRef[File] });
# Gat::manifest 

sub init {
    my ($work_dir, $verbose) = validated_list(\@_, 
        work_dir => { isa => Dir, coerce => 1 },
        verbose  => { isa => Bool, default => 0 },
    );

}

sub add {
    my ($work_dir, $verbose) = validated_list(\@_, 
        work_dir => { isa => Dir, coerce => 1 },
        verbose  => { isa => Bool, default => 0 },
        files    => { isa => ArrayRef[File|Str] },
    );

    my $c = Gat::Container->new(
        work_dir => $work_dir->absolute,
        base_dir => $work_dir->absolute,
    );

    my $gat_dir = $c->fetch('gat_dir')->get;

    $gat_dir->mkpath($verbose);
    $gat_dir->subdir('asset')->mkpath($verbose);

    my $config_file = $gat_dir->file('config');
    my $config = $c->fetch('config')->get;

    $config->set(
        key      => 'repository.use_symlinks',
        value    => 0,
        as       => 'bool',
        filename => $config_file,
    );

    $config->set(
        key      => 'repository.digest_type',
        value    => 'MD5',
        filename => $config_file,
    );


}


1;
