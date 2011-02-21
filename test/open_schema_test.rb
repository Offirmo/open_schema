require File.join(File.dirname(__FILE__), '../init.rb')

class ModelTest < OpenSchemaThing
	agile_attribute :extra_attribute
end

ost = OpenSchemaThing.new

m = ModelTest.new
