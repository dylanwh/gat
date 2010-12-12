package Gat::Util;
use strictures 1;
use Path::Class;

use Sub::Exporter -setup => {
    exports => [qw[ file_stream find_base_dir parse_rules ]],
};

sub file_stream {
    my @files = @_;
    
}

sub find_base_dir {
    my ($work) = @_;
    my $root = dir('');
    my $base = $work;

    until (-d $base->subdir('.gat')) {
        $base = $base->parent;
        return $work if $base eq $root;
    }
    
    return $base;
}

sub parse_rules {
    my ($file) = @_;

    my @predicates;
    my $fh = $file->openr;
    local $_;

    while ($_ = $fh->getline) {
        chomp;
        if (/^!(.+)$/) {
            push @predicates, [qr/$1/ => 0 ];
        }
        elsif (/^\s*#/) {
            next;
        }
        else {
            push @predicates, [qr/$_/ => 1 ];
        }
    }
    return \@predicates;
}


1;
