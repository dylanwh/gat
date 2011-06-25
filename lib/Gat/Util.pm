package Gat::Util;
use strict;
use warnings;
use feature 'switch';

use Sub::Exporter -setup => {
    exports => [qw[ find_base_dir ]],
};

use Path::Class 'dir';
use Gat::Constants 'GAT_DIR';
use Gat::Types 'AbsoluteDir';
use MooseX::Params::Validate;

sub find_base_dir {
    my ($work_dir) = pos_validated_list(\@_, { isa => AbsoluteDir, coerce => 1 });
    my $root_dir   = dir('');
    my $base_dir   = $work_dir

    until (-d $base_dir->subdir(GAT_DIR)) {
        $base_dir = $base_dir->parent;
        return $work_dir if $base_dir eq $root_dir;
    }

    return $base_dir;
}


1;
