##
## Initialize the environment
##
unless Rails::VERSION::MAJOR == 3 && Rails::VERSION::MINOR >= 0
  raise "This plugin requires Rails 3.0 or higher."
end

require File.join(File.dirname(__FILE__), 'lib', 'open_schema')
require File.join(File.dirname(__FILE__), 'lib', 'delegates_attribute_to_open_schema_data')
require File.join(File.dirname(__FILE__), 'lib', 'agile_attribute')
