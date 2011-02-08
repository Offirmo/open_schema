# based on delegates_attributes_to
# but customized for our needs
module DelegatesAttributesToOpenSchemaData

	DEFAULT_REJECTED_COLUMNS = ['created_at','created_on','updated_at','updated_on','lock_version','type','id','position','parent_id','lft','rgt'].freeze
	DIRTY_SUFFIXES = ["_changed?", "_change", "_will_change!", "_was"].freeze

	def self.included(base)
		base.extend ClassMethods
		base.send :include, InstanceMethods

		base.alias_method_chain :assign_multiparameter_attributes, :open_schema_data_delegation

		base.class_inheritable_accessor :default_rejected_delegate_columns
		base.default_rejected_delegate_columns = DEFAULT_REJECTED_COLUMNS.dup

		base.class_inheritable_accessor :delegated_attributes
		base.delegated_attributes = HashWithIndifferentAccess.new
	end

	module ClassMethods

		ATTRIBUTE_SUFFIXES = (['', '='] + DIRTY_SUFFIXES).freeze

		# has_one :profile
		# delegate_attributes :to => :profile
		def delegates_attribute_to_open_schema_data(*attributes)
			options = attributes.extract_options!
			unless options.is_a?(Hash) && association = options[:to]
				raise ArgumentError, "Delegation needs a target. Supply an options hash with a :to key as the last argument (e.g. delegate_attribute :hello, :to => :greeter"
			end
			prefix = options[:prefix] && "#{options[:prefix] == true ? association : options[:prefix]}_"
			reflection = reflect_on_association(association)
			raise ArgumentError, "Unknown association #{association}" unless reflection

			if (options.has_key?(:autosave) && options[:autosave] == false) then
				#puts "autosave set to false"
				reflection.options[:autosave] = false
			else
				#puts "autosave stays to default (#{reflection.options[:autosave]})"
			end

			if attributes.empty? || attributes.delete(:defaults)
				attributes += reflection.klass.column_names - default_rejected_delegate_columns
			end

			attributes.each do |attribute|
				delegated_attributes.merge!("#{prefix}#{attribute}" => [association, attribute])

				if (true) then
					# Offirmo modif
					# I don't want the object to be created on read access !
					define_method("#{prefix}#{attribute}") do |*args|
						association_object = send(association)
						association_object.nil? ? nil : association_object.send("#{attribute}", *args)
					end
					# I don't want the object to be created on nil write !
					define_method("#{prefix}#{attribute}=") do |*args|
						association_object = send(association)
						#puts "setter args = " + args.inspect
						if association_object.nil? then
							if args.first.nil? then
								#puts "unnecessary creation avoided."
							else
								association_object = send("build_#{association}")
							end
						end
						
						association_object.send("#{attribute}=", *args) unless association_object.nil?
					end
				else
					ATTRIBUTE_SUFFIXES.each do |suffix|
						puts "define method #{prefix}#{attribute}#{suffix} [association #{association}]..."
						define_method("#{prefix}#{attribute}#{suffix}") do |*args|
							association_object = send(association) || send("build_#{association}")
							association_object.send("#{attribute}#{suffix}", *args)
						end
					end
				end # YEJ
			end # adding accessors for every attributes
		end

		# unnecessary methods suppressed
		
	end # ClassMethods

	module InstanceMethods

		private

		def assign_multiparameter_attributes_with_open_schema_data_delegation(pairs)
			delegated_pairs = {}
			original_pairs  = []

			pairs.each do |name, value|
				# it splits multiparameter attribute
				# 'published_at(2i)'  => ['published_at(2i)', 'published_at', '(2i)']
				# 'published_at'      => ['published_at',     'published_at',  nil  ]
				__, delegated_attribute, suffix = name.match(/^(\w+)(\([0-9]*\w\))?$/).to_a
				association, attribute = self.class.delegated_attributes[delegated_attribute]

				if association
					(delegated_pairs[association] ||= {})["#{attribute}#{suffix}"] = value
				else
					original_pairs << [name, value]
				end
			end

			delegated_pairs.each do |association, attributes|
				association_object = send(association) || send("build_#{association}")
				# let association_object handle its multiparameter attributes
				association_object.attributes = attributes
			end

			assign_multiparameter_attributes_without_open_schema_data_delegation(original_pairs)
		end

		# redefinition
		def changed_attributes
			result = {}

			if not self.class.delegated_attributes.nil? then
				self.class.delegated_attributes.each do |delegated_attribute, (association, attribute)|
					# If an association isn't loaded it hasn't changed at all. So we skip it.
					# If we don't skip it and have mutual delegation beetween 2 models
					# we get SystemStackError: stack level too deep while trying to load
					# a chain like user.profile.user.profile.user.profile...
					next unless send("loaded_#{association}?")
					#puts "loaded_#{association}? send true..."
					# skip if association object is nil
					next unless association_object = send(association)
					#puts "#{association_object.inspect} true..."
					# call private method #changed_attributes
					association_changed_attributes = association_object.send(:changed_attributes)
					#puts "association_changed_attributes = #{association_changed_attributes.inspect}..."
					# next if attribute hasn't been changed
					next unless association_changed_attributes.has_key?(attribute.to_s)

					result.merge! delegated_attribute => association_changed_attributes[attribute]
				end
			end

			changed_attributes = super
			changed_attributes.merge!(result)
			#puts "final changed attributes : " + changed_attributes.inspect
			changed_attributes
		end
	end # InstanceMethods
	
end

#DelegateBelongsTo = DelegatesAttributesTo unless defined?(DelegateBelongsTo)

ActiveRecord::Base.send :include, DelegatesAttributesToOpenSchemaData
