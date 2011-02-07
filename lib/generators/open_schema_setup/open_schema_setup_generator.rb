module Rails
  module Generators
    class OpenSchemaSetupGenerator < Rails::Generators::Base #metagenerator
      #argument :js_lib, :type => :string, :default => 'prototype', :desc => 'js_lib for activescaffold (prototype|jquery)' 

      def install_plugins
        plugin 'delegates_attributes_to', :git => 'git://github.com/toto/delegates_attributes_to.git'
      end
      
      def configure_model
        # TODO
      end     
    end
  end
end