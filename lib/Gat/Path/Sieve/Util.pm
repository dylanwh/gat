package Gat::Path::Sieve::Util;
use strict;
use warnings;
use feature 'switch';

use Sub::Exporter -setup => {
    exports => [qw[ parse_rule load_rules ]],
};

use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class 'File';
use MooseX::Params::Validate;

use Eval::Closure 'eval_closure';
use Text::Glob 'glob_to_regex';

sub parse_rule {
    my ($line, $file, $num) = pos_validated_list(\@_,
        { isa => Str },
        { isa => File, coerce => 1, default => "unknown"},
        { isa => Int, default => 1 },
    );

    $line =~ s/\s+#.*$//s;
    $line =~ s/^\s+//s;
    $line =~ s/\s+$//s;

    my $val = ( $line =~ s/^!// ) ? 0 : 1;

    given ($line) {
        when (/^#/) {
            return ();
        }
        when (/^:(.+)$/s) {
            my $code = qq(#line $num "$file"\nsub { local \$_ = \$_[0]; $1 });
            my $func = eval_closure(
                source      => $code,
            );
            return ([ $func, $val ]);
        }
        when (/^\/(.+?)\/?$/s) {
            return ([ qr/$1/, $val ]);
        }
        when (/^(.+)$/s) {
            return ([ glob_to_regex($1), $val ]);
        }
    }
}

sub load_rules {
    my ($file) = pos_validated_list(\@_, { isa => File, coerce => 1 });

    my $fh = $file->openr;
    my @rules;
    while (my $line = $fh->getline) {
        push @rules, parse_rule($line, $file, $fh->input_line_number)
    }

    return \@rules;
}

1;
