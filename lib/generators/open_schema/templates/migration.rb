class CreateOpenSchema < ActiveRecord::Migration
	def self.up
		create_table :open_schema_things do |t|
			
			# a generic 'belongs_to' association
			# id + type is the pattern for a polymorphic association
			t.integer :open_schema_thing_owner_id
			t.string  :open_schema_thing_owner_type
			
			# STI rules !
			t.string  :type
			
			# for extras ;-)
			t.string  :extra
			
			t.timestamps
		end
		
		create_table :open_schema_data do |t|
			
			# id + type is the pattern for a polymorphic association
			t.integer :open_schema_datum_owner_id
			t.string  :open_schema_datum_owner_type
			
			# whatever it is
			t.integer :open_schema_datum_owner_version
			
			# (optionnal) link to the parent to be able to filter more efficiently
			t.integer :open_schema_datum_owner_parent_id
			
			# is this data computed or entered by a human ?
			t.boolean :computed
			
			# the classic key/value
			# we use 'type' for 'key' because 1) key is a reserved word for SQL and 2) type is semantically correct and allows STI
			t.string :type
			t.string :value
			
			t.timestamps
		end
	end

	def self.down
		drop_table :open_schema_things
		drop_table :open_schema_data
	end
end
