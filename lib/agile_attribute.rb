# +agile_attribute+ allows you to instantly add attributes to your active records
# without any need for database change or migrations.
# Of course, this is slightly less powerful than real attributes, but it's very useful
# for rapid evolutions (urgent customer request ?) or prototyping without messing the core


module AgileAttribute

	####### The base class for storing any data
	# all data will inherit from this class
	class OpenSchemaData < ActiveRecord::Base

		default_value_for :open_schema_data_owner_version, 0
		default_value_for :computed, true # most likely
		
		belongs_to :open_schema_data_owner,        :polymorphic => true, :validate => false # a meta-data can belongs to any model class which is a metadata_owner
		belongs_to :open_schema_data_owner_parent, :polymorphic => true # a meta-data can belongs to any model class which is a metadata_parent_owner
		
		# most likely due to delegates_attribute_to, this data is marqued "changed" after a simple read !
		# It is then created in database, for nothing.
		# Thus, we prevent the save if this data is new (no id) and its value is nil
		# def before_save()
			# puts "before_save : " + self.inspect
			# is_new = self.id.nil?
			# is_empty = self.value.nil?
			# should_not_create = (is_new and is_empty)
			# puts "#{is_new} and #{is_empty} => should_not_create : #{should_not_create}"
			#!should_not_create
			# true
		# end
		
		# def after_commit()
			# should_destroy = !self.id.nil? and self.value.nil?
			# puts "should_destroy : " + should_destroy.inspect
			# if should_destroy then self.delete end
			# true
		# end
		
	end

	extend ActiveSupport::Concern # http://www.fakingfantastic.com/2010/09/20/concerning-yourself-with-active-support-concern/
	
	included do
		#puts "Adding AgileAttribute - this will make your class awesome. Proceed with awesomeness."

		class_eval do
			class_inheritable_hash :agile_attributes # to allow inheritance, cf. http://www.spacevatican.org/2008/8/19/fun-with-class-variables
			self.agile_attributes = {}
		end
	end
	
	
	
	module ClassMethods
	
		# our main method
		# +agile_attribute+ accepts one symbol and many arguments, representing ...
		def agile_attribute(attribute, *params, &block)
			
			there_is_a_problem = false

			#puts ">>> Found agile_attribute declaration \"#{attribute}\" with #{params}..."
				
			# pre-check
			if not attribute.is_a? Symbol then
				raise ArgumentError, 'Please review your agile_attribute configuration (1)'
				there_is_a_problem = true
			else
				table_name = table_name_for_attribute(attribute)
				
				if table_name != table_name.singularize then
					raise ArgumentError, 'Please review your agile_attribute configuration (2)'
					there_is_a_problem = true
				elsif self.agile_attributes.has_key?(table_name) then
					raise ArgumentError, 'Please review your agile_attribute configuration (2b)'
					there_is_a_problem = true
				end
			end

			# parse and store parameters
			params_hash = parse_and_store_parameters(attribute, *params) unless there_is_a_problem
			if params_hash == nil then there_is_a_problem = true end
			
			# install everything
			install_stuff_with_meta_programming(attribute, params_hash) unless there_is_a_problem
			
			if there_is_a_problem then
				raise ArgumentError, 'Please review your agile_attribute configuration'
			end
		end # attribute declaration

		
		# sub-method for parsing parameters
		def parse_and_store_parameters(attribute, *params)
			params_hash = {}
			
			#puts ">>> parse_and_store_parameters for \"#{attribute}\" with #{params}..."
			
			case params.length
			when 0
				# nothing to do, OK
			when 1
				# standard
				params[0].each do |k, v|
					#puts "   arg #{k} [#{k.class}] => #{v} [#{v.class}]"
					
					if not k.is_a? Symbol then
						raise ArgumentError, 'Please review your agile_attribute configuration (3)'
						there_is_a_problem = true
						break
					else
						case k
						when :computed
							# TODO
						when :type
							if not [ :integer, :boolean, :string, :text, :decimal, :timestamp, :references ].include?(v) then
								raise ArgumentError, 'Please review your agile_attribute configuration (3b)'
								there_is_a_problem = true
								break
							elsif params_hash.has_key?(:type) then
								# technically impossible since params is a hash
								raise ArgumentError, 'Please review your agile_attribute configuration (3c)'
								there_is_a_problem = true
								break
							else
								params_hash[:type] = v
							end
						else
							raise ArgumentError, 'Please review your agile_attribute configuration (4)'
							there_is_a_problem = true
							break
						end
					end # symbol ?
				end # loop over params
			else
				# possible ???
				raise ArgumentError, 'Please review your agile_attribute configuration (5)'
				there_is_a_problem = true
			end
			
			#puts params_hash.inspect
			
			return params_hash
		end # parse_and_store_parameters
		
		def install_stuff_with_meta_programming(attribute, params_hash)
			
			table_name = table_name_for_attribute(attribute)
			
			base_class = OpenSchemaData
			record_name_camel = "OpenSchemaData"
			record_name_table = record_name_camel.tableize.singularize
			#record_value_field_name = "value"
			# proceed with meta-programmation
			
			# storing info about this agile attribute, for later access
			#puts ">>> prefs = " + self.agile_attributes.inspect
			self.agile_attributes[table_name] = params_hash
			
			# We create a new STI class
			meta_class_name = record_name_camel + table_name.camelize
			#puts ">>> Dynamically creating a MetaData STI subclass called \"#{meta_class_name}\""
			c = Class.new(base_class) # New class inheriting from the base class
			const_set meta_class_name, c # registering this new class with the desired name, cf. http://johnragan.org/2010/02/18/ruby-metaprogramming-dynamically-defining-classes-and-methods/
			
			# Check :
			# puts class_name.constantize # doesn't work but STI and relations are working perfectly
			
			meta_table_name = record_name_table + "_" + table_name
			#puts ">>> Adding a 'has_one' relation to :#{meta_table_name}..."
			has_one meta_table_name.to_sym, :as => (record_name_table + "_owner").to_sym, :foreign_key => (record_name_table + "_owner_id"), :dependent => :destroy, :autosave => true
			
			delegated_table_name = table_name + '_' + 'value'
			#puts ">>> Adding delegation for easy access of MetaData value via '.#{delegated_table_name}'..."
			# using a modified version of git://github.com/pahanix/delegates_attributes_to.git
			delegates_attribute_to_open_schema_data :value, :to => meta_table_name.to_sym, :prefix => table_name.to_sym #, :autosave => false
			
			# adding accessors for the attribute
			alias_attribute table_name.to_sym, delegated_table_name.to_sym # thank you !
			
			# we override the read accessor because we need to cast the attribute type according to its desired type (since it's always stored as a string)
			# thank you http://stackoverflow.com/questions/2499247/dynamically-defined-setter-methods-using-define-method and http://stackoverflow.com/questions/373731/override-activerecord-attribute-methods
			define_method("#{table_name}") do
				#puts "you requested the :#{table_name} attribute !"
				#puts "params for this attribute are : #{self.agile_attributes[table_name]}"
				
				# first we get the raw attribute value
				delegated_table_name = table_name + '_' + 'value'
				raw_value = self.send(delegated_table_name)
				
				# and then we convert it if a type was provided and if necessary
				converted_value = raw_value # no change by default
				# no conversion if nil, to show that the value is missing
				if (!raw_value.nil?) and self.agile_attributes[table_name].has_key?(:type) then
					case self.agile_attributes[table_name][:type]
					when :integer
						converted_value = raw_value.to_i
					when :boolean
						converted_value = raw_value.to_i
					when :string
						# nothing to do
					when :text
						# nothing to do
					when :decimal
						converted_value = raw_value.to_f # true ?
					when :timestamp
						# nothing to do (true ?)
					when :references
						# what is this type ? I don't care for now.
					else
						# unknown type ? impossible !
						fail # TODO raise exception
					end
				else
					# no change
				end
				
				return converted_value
			end # dynamic read accessor redefinition
			
		end # install_stuff_with_meta_programming
		
		def table_name_for_attribute(attr)
			attr.to_s
		end
		
		# is this class "agile" ? Does it have agile attributes ?
		def agile?
			!agile_attribute.blank?
		end
	end

	
	
	module InstanceMethods
		# none
	end
	
end

class ActiveRecord::Base
	include AgileAttribute
end
