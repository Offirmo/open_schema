##
## Initialize the environment
##
unless Rails::VERSION::MAJOR >= 3 && Rails::VERSION::MINOR >= 0
  raise "This plugin requires Rails 3.0 or higher."
end

require File.join(File.dirname(__FILE__), 'lib', 'open_schema_datum')
require File.join(File.dirname(__FILE__), 'lib', 'delegates_attribute_to_open_schema_datum')
require File.join(File.dirname(__FILE__), 'lib', 'agile_attribute')
require File.join(File.dirname(__FILE__), 'lib', 'open_schema_thing')

# reminder that open_schema requires a migration
# warn "Cannot find OpenSchemaThing in database. The open-schema plugin requires a migration. run 'rails generate open_schema'" unless OpenSchemaThing.table_exists?
# warn "Cannot find OpenSchemaData in database. The open-schema plugin requires a migration. run 'rails generate open_schema'" unless OpenSchemaData.table_exists?
