#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;


{
    package Foo;
    use Path::Class;
    use Moose;
    use Test::Exception;

    use ok 'Gat::Types', ':all';

    has rel_file => ( is => 'ro', isa => RelativeFile, coerce => 1);
    has abs_file => ( is => 'ro', isa => AbsoluteFile, coerce => 1);
    has rel_path => ( is => 'ro', isa => RelativePath, coerce => 1);
    has abs_path => ( is => 'ro', isa => AbsolutePath, coerce => 1);

    lives_ok {
        Foo->new(rel_file => "foo");
    };

    lives_ok {
        Foo->new(rel_file => file("foo"));
    };

    dies_ok {
        Foo->new(rel_file => dir("foo"));
    };

    dies_ok {
        Foo->new(rel_file => "/foo");
    };

    lives_ok {
        Foo->new(abs_file => "/foo");
    };

    dies_ok {
        Foo->new(abs_file => "foo");
    };

    lives_ok {
        Foo->new(rel_path => "foo");
    };

    lives_ok {
        Foo->new(rel_path => file("foo"));
    };

    lives_ok {
        Foo->new(rel_path => dir("foo"));
    };

    dies_ok {
        Foo->new(rel_path => "/foo");
    };

    dies_ok {
        Foo->new(rel_path => file("/foo"));
    };

    dies_ok {
        Foo->new(rel_path => dir("/foo"));
    };


    lives_ok {
        Foo->new(abs_path => "/foo");
    };

    lives_ok {
        Foo->new(abs_path => file("/foo"));
    };

    lives_ok {
        Foo->new(abs_path => dir("/foo"));
    };

    dies_ok {
        Foo->new(abs_path => "foo");
    };

    dies_ok {
        Foo->new(abs_path => file("foo"));
    };

    dies_ok {
        Foo->new(abs_path => dir("foo"));
    };



    



}

done_testing;

