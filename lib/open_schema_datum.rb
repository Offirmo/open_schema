# == Schema Information
# Schema version: 20110215004345
#
# Table name: open_schema_data
#
#  id                                :integer(4)      not null, primary key
#  open_schema_datum_owner_id        :integer(4)
#  open_schema_datum_owner_type      :string(255)
#  open_schema_datum_owner_version   :integer(4)
#  open_schema_datum_owner_parent_id :integer(4)
#  computed                          :boolean(1)
#  type                              :string(255)
#  value                             :string(255)
#  created_at                        :datetime
#  updated_at                        :datetime
#

####### The base class for storing any datum
# all data will inherit from this class
class OpenSchemaDatum < ActiveRecord::Base
	
	default_value_for :open_schema_datum_owner_version, 0
	default_value_for :computed, true # most likely
	
	belongs_to :open_schema_datum_owner,        :polymorphic => true, :validate => false # a meta-datum can belongs to any model class which is a metadatum_owner
	belongs_to :open_schema_datum_owner_parent, :polymorphic => true # a meta-datum can belongs to any model class which is a metadatum_parent_owner
	
end
