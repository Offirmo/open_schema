# == Schema Information
# Schema version: 20110215004345
#
# Table name: open_schema_things
#
#  id                           :integer(4)      not null, primary key
#  open_schema_thing_owner_id   :integer(4)
#  open_schema_thing_owner_type :string(255)
#  type                         :string(255)
#  extra                        :string(255)
#  created_at                   :datetime
#  updated_at                   :datetime
#

####### The base class for storing any thing
# just inherit from this class to quickly create a new record
class OpenSchemaThing < ActiveRecord::Base
	
	# This is a trick to make this class kind of "abstract"
	# when we are unable to use abstract_class due to STI
	validates_presence_of :type, :message => "This class is abstract, you cannot instantiate it."
	
end
