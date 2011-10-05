package Gat::Schema::Result::Attribute;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Gat::Schema::Result::Attribute

=cut

__PACKAGE__->table("attribute");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 asset

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "asset",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "value",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("asset_name_unique", ["asset", "name"]);

=head1 RELATIONS

=head2 asset

Type: belongs_to

Related object: L<Gat::Schema::Result::Asset>

=cut

__PACKAGE__->belongs_to(
  "asset",
  "Gat::Schema::Result::Asset",
  { id => "asset" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-09-09 16:03:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wbIeSQttHHndSaQKn7Xotg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
