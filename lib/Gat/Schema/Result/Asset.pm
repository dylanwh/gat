package Gat::Schema::Result::Asset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Gat::Schema::Result::Asset

=cut

__PACKAGE__->table("asset");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 size

  data_type: 'integer'
  is_nullable: 0

=head2 mtime

  data_type: 'timestamp'
  is_nullable: 0

=head2 checksum

  data_type: 'text'
  is_nullable: 0

=head2 content_type

  data_type: 'text'
  is_nullable: 0

=head2 digest_type

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "size",
  { data_type => "integer", is_nullable => 0 },
  "mtime",
  { data_type => "timestamp", is_nullable => 0 },
  "checksum",
  { data_type => "text", is_nullable => 0 },
  "content_type",
  { data_type => "text", is_nullable => 0 },
  "digest_type",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("checksum_unique", ["checksum"]);

=head1 RELATIONS

=head2 labels

Type: has_many

Related object: L<Gat::Schema::Result::Label>

=cut

__PACKAGE__->has_many(
  "labels",
  "Gat::Schema::Result::Label",
  { "foreign.asset" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 attributes

Type: has_many

Related object: L<Gat::Schema::Result::Attribute>

=cut

__PACKAGE__->has_many(
  "attributes",
  "Gat::Schema::Result::Attribute",
  { "foreign.asset" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-09 14:28:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hUjOhr/q5CChZnHm5+aPew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
