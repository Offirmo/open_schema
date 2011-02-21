# == Schema Information
# Schema version: 20110215004345
#
# Table name: open_schema_datas
#
#  id                               :integer(4)      not null, primary key
#  open_schema_data_owner_id        :integer(4)
#  open_schema_data_owner_type      :string(255)
#  open_schema_data_owner_version   :integer(4)
#  open_schema_data_owner_parent_id :integer(4)
#  computed                         :boolean(1)
#  type                             :string(255)
#  value                            :string(255)
#  created_at                       :datetime
#  updated_at                       :datetime
#

####### The base class for storing any data
# all data will inherit from this class
class OpenSchemaData < ActiveRecord::Base

	default_value_for :open_schema_data_owner_version, 0
	default_value_for :computed, true # most likely
	
	belongs_to :open_schema_data_owner,        :polymorphic => true, :validate => false # a meta-data can belongs to any model class which is a metadata_owner
	belongs_to :open_schema_data_owner_parent, :polymorphic => true # a meta-data can belongs to any model class which is a metadata_parent_owner
end
