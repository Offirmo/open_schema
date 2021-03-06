# +agile_attribute+ allows you to instantly add attributes to your active records
# without any need for database change or migrations.
# Of course, this is slightly less powerful than real attributes, but it's very useful
# for rapid evolutions (urgent customer request ?) or prototyping without messing the core


module AgileAttribute

	extend ActiveSupport::Concern # http://www.fakingfantastic.com/2010/09/20/concerning-yourself-with-active-support-concern/
	
	included do
		# puts "Adding AgileAttribute - this will make your classes awesome. Proceed with awesomeness."
		
		class_eval do
			class_inheritable_hash :agile_attributes # to allow inheritance, cf. http://www.spacevatican.org/2008/8/19/fun-with-class-variables
			self.agile_attributes = {}
		end
	end
	
	
	module ClassMethods
		
		# CONSTANTE = 12
		# @@class_var1 = 33
		# def class_var1
			# @@class_var1
		# end
		
		# this function is used in the code
		def table_name_for_agile_attribute(attr)
			attr.to_s
		end
		
		# this function is NOT used in the code, it's here for debug/inspection
		def debug_agile_attribute(attr)
			puts "attribute                  = " + attr.inspect
			table_name = table_name_for_agile_attribute(attr)
			puts "attribute table name       = " + table_name
			base_class_name_camel = "OpenSchemaDatum"
			puts "base data class name       = " + base_class_name_camel
			base_class_name_table = base_class_name_camel.tableize.singularize
			puts "base data class table name = " + base_class_name_table
			meta_class_name = base_class_name_camel + table_name.camelize
			puts "meta class name            = " + meta_class_name
			meta_class_table_name = base_class_name_table + "_" + table_name
			puts "meta class table name      = " + meta_class_table_name
			delegated_table_name = table_name + '_' + 'value'
			puts "delegated table name       = " + delegated_table_name
		end
		# this function is NOT used in the code, it's here for debug/inspection
		def debug_agile_attributes()
			
		end
		
		# our main method
		# +agile_attribute+ accepts one symbol and many arguments, representing ...
		def agile_attribute(attribute, *params, &block)
			
			there_is_a_problem = false
			
			# note : with *, params is always an array.
			# puts ">>> Found agile_attribute declaration \"#{attribute}\" with #{params}..."
			
			# puts "CONSTANTE = " + CONSTANTE.inspect
			# puts "@@class_var1 = " + class_var1.inspect
			# puts "self.agile_attributes = " + self.agile_attributes.inspect
			
			# pre-check
			if !attribute.is_a?(Symbol) then
				raise ArgumentError, 'Please review your agile_attribute configuration : attribute name is not a symbol.'
				there_is_a_problem = true
			elsif !(params.length == 0 || (params.length == 1 && params[0].is_a?(Hash))) then
				raise ArgumentError, 'Please review your agile_attribute configuration : params are not a hash.'
				there_is_a_problem = true
			else
				table_name = table_name_for_agile_attribute(attribute)
				
				if table_name != table_name.singularize then
					raise ArgumentError, 'Please review your agile_attribute configuration : attribute name is not singular.'
					there_is_a_problem = true
				elsif self.agile_attributes.has_key?(table_name) then
					raise ArgumentError, 'Please review your agile_attribute configuration : attribute name is already used for this class.'
					there_is_a_problem = true
				end
			end

			# parse and store parameters
			params_hash = parse_and_store_parameters(attribute, *params) unless there_is_a_problem
			if params_hash == nil then there_is_a_problem = true end
			
			# install everything
			install_stuff_with_meta_programming(attribute, params_hash) unless there_is_a_problem
			
			if there_is_a_problem then
				# do we arrive here ?
				raise ArgumentError, 'Please review your agile_attribute configuration.'
			end
		end # attribute declaration

		
		# sub-method for parsing parameters
		def parse_and_store_parameters(attribute, *params)
			params_hash = {}
			
			# puts ">>> parse_and_store_parameters for \"#{attribute}\" with #{params}..."
			
			case params.length
			when 0
				# nothing to do, OK
			when 1
				# standard
				params[0].each do |k, v|
					#puts "   arg #{k} [#{k.class}] => #{v} [#{v.class}]"
					
					if not k.is_a? Symbol then
						raise ArgumentError, 'Please review your agile_attribute configuration : param key is incorrect (not a symbol).'
						there_is_a_problem = true
						break
					else
						case k
						when :computed
							# TODO
						when :default_value
							params_hash[:default_value] = v
						when :type
							if not [ :integer, :boolean, :string, :text, :decimal, :timestamp, :references ].include?(v) then
								raise ArgumentError, 'Please review your agile_attribute configuration : param value is not allowed.'
								there_is_a_problem = true
								break
							elsif params_hash.has_key?(:type) then
								# technically impossible since params is a hash
								raise ArgumentError, 'Please review your agile_attribute configuration : param key has been declared several times.'
								there_is_a_problem = true
								break
							else
								params_hash[:type] = v
							end
						else
							raise ArgumentError, 'Please review your agile_attribute configuration : param key is unknown.'
							there_is_a_problem = true
							break
						end
					end # symbol ?
				end # loop over params
			else
				# possible ???
				raise ArgumentError, 'Please review your agile_attribute configuration.'
				there_is_a_problem = true
			end # switch / case
			
			#puts params_hash.inspect
			
			return params_hash
		end # parse_and_store_parameters
		
		def install_stuff_with_meta_programming(attribute, params_hash)
			
			table_name = table_name_for_agile_attribute(attribute)
			
			base_class = OpenSchemaDatum
			record_name_camel = "OpenSchemaDatum"
			record_name_table = record_name_camel.tableize.singularize
			#record_value_field_name = "value"
			# proceed with meta-programmation
			
			# storing info about this agile attribute, for later access
			#puts ">>> prefs = " + self.agile_attributes.inspect
			self.agile_attributes[table_name] = params_hash
			
			# We create a new STI class
			meta_class_name = record_name_camel + table_name.camelize
			#puts ">>> Dynamically creating a MetaDatum STI subclass called \"#{meta_class_name}\""
			c = Class.new(base_class) # New class inheriting from the base class
			const_set meta_class_name, c # registering this new class with the desired name, cf. http://johnragan.org/2010/02/18/ruby-metaprogramming-dynamically-defining-classes-and-methods/
			
			# Check :
			# puts class_name.constantize # doesn't work but STI and relations are working perfectly
			
			meta_table_name = record_name_table + "_" + table_name
			#puts ">>> Adding a 'has_one' relation to :#{meta_table_name}..."
			has_one meta_table_name.to_sym, :as => (record_name_table + "_owner").to_sym, :foreign_key => (record_name_table + "_owner_id"), :dependent => :destroy, :autosave => true
			
			delegated_table_name = table_name + '_' + 'value'
			#puts ">>> Adding delegation for easy access of MetaDatum value via '.#{delegated_table_name}'..."
			# using a modified version of git://github.com/pahanix/delegates_attributes_to.git
			delegates_attribute_to_open_schema_datum :value, :to => meta_table_name.to_sym, :prefix => table_name.to_sym #, :autosave => false
			
			# adding accessors for the attribute
			alias_attribute table_name.to_sym, delegated_table_name.to_sym # thank you !
			
			# we override the read accessor because we need to cast the attribute type according to its desired type (since it's always stored as a string)
			# thank you http://stackoverflow.com/questions/2499247/dynamically-defined-setter-methods-using-define-method and http://stackoverflow.com/questions/373731/override-activerecord-attribute-methods
			remove_method table_name.to_sym # we remove before redefining, to show that we know what we do and suppress a ruby warning
			define_method("#{table_name}") do
				# puts "you requested the :#{table_name} attribute !"
				# puts "params for this attribute are : #{self.agile_attributes[table_name]}"
				
				# first we get the raw attribute value
				delegated_table_name = table_name + '_' + 'value'
				raw_value = self.send(delegated_table_name)
				# puts "Current raw_value is : #{raw_value} [#{raw_value.class}]"
				
				# and then we convert it if a type was provided and convert it if necessary
				final_value = raw_value # no change by default
				if (raw_value.nil?) then
					if self.agile_attributes[table_name].has_key?(:default_value) then
						# no conversion if there is a default value, cause we should not have to
						final_value = self.agile_attributes[table_name][:default_value]
					else
						# nil
						# no conversion if nil, to clearly show that the value is missing
					end
				elsif self.agile_attributes[table_name].has_key?(:type) then
					converted_value = final_value # no change by default
					case self.agile_attributes[table_name][:type]
					when :integer
						converted_value = converted_value.to_i unless converted_value.is_a?(Fixnum)
					when :boolean
						converted_value = (converted_value.to_i == 0 ? false : true) unless (converted_value.is_a?(TrueClass) || converted_value.is_a?(FalseClass))
					when :string
						# nothing to do
					when :text
						# nothing to do
					when :decimal
						converted_value = converted_value.to_f # true ?
					when :timestamp
						# nothing to do (true ?)
					when :references
						# what is this type ? I don't care for now.
					else
						# unknown type ? impossible !
						fail # TODO raise exception
					end
					final_value = converted_value
				else
					# no change
				end
				
				return final_value
			end # dynamic read accessor redefinition
			
		end # install_stuff_with_meta_programming
		
		# is this class "agile" ? Does it have agile attributes ?
		def agile?
			!agile_attribute.blank?
		end
		
	end # module ClassMethods
	
	
	module InstanceMethods
		# none
	end
	
end # module AgileAttribute

class ActiveRecord::Base
	include AgileAttribute
end
