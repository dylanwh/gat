package Gat::Util;
use strict;
use warnings;
use feature 'switch';

use Sub::Exporter -setup => {
    exports => [qw[ find_base_dir cleanup_filename ]],
};

use MooseX::Types::Path::Class 'File', 'Dir';
use Path::Class 'dir', 'file';
use Gat::Constants 'GAT_DIR', 'GAT_REALPATH';
use Gat::Types 'AbsoluteDir';
use Cwd 'realpath';
use MooseX::Params::Validate;

sub find_base_dir {
    my ($work_dir) = pos_validated_list(\@_, { isa => AbsoluteDir, coerce => 1 });
    my $root_dir   = dir('');
    my $base_dir   = $work_dir;

    until (-d $base_dir->subdir(GAT_DIR)) {
        $base_dir = $base_dir->parent;
        return $work_dir if $base_dir eq $root_dir;
    }

    return $base_dir;
}

sub cleanup_filename {
    my ($filename) = pos_validated_list(\@_, { isa => File, coerce => 1 });

    if (GAT_REALPATH) {
        my $realpath   = realpath("$filename");

        return file($realpath) if defined $realpath;
    }

    my @dirs;
    for my $dir ( File::Spec->splitdir($filename->stringify) ) {
        if ( $dir eq '..' ) {
            pop @dirs if @dirs;
        }
        elsif ( $dir eq '.') {
            next;
        }
        elsif ( $dir eq '') {
            push @dirs, '' unless @dirs;
        }
        else {
            push @dirs, $dir;
        }
    }
    
    return file(@dirs);
}


1;
