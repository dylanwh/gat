package Gat::Remote;
use Moose::Role;
use namespace::autoclean;

requires 'store', 'fetch', 'remove', 'assets';

1;
