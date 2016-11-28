require 'rails/generators'

module PluginGenerator
  def self.generate_test_plugin!
    Rails::Generators.invoke 'redmine_extensions:plugin', ['DummyPlugin'], behavior: :revoke, destination_root: Rails.root
    Rails::Generators.invoke 'redmine_extensions:plugin', ['DummyPlugin'], behavior: :invoke, destination_root: Rails.root
    # if Rails::VERSION::MAJOR >= 5
    #   Rails.application.reloader.reload!
    # else
    #   ActionDispatch::Reloader.cleanup!
    #   ActionDispatch::Reloader.prepare!
    # end

    generate_autocomplete!
  end

  def self.generate_autocomplete!
    generate_dummy_entity!
    generate_autocomplete_controller!
    generate_autocomplete_routes!
    generate_autocomplete_view!
  end

  def self.generate_dummy_entity!
    File.open( Rails.root.join('plugins', 'dummy_plugin', 'db', 'migrate', '20162010160230_create_dummy_entities.rb'), 'w' ) do |file|
      file.write( <<-END_RUBY )
        class CreateDummyEntities < ActiveRecord::Migration
          def change
            create_table :dummy_entities do |t|
              t.string :name
              t.integer :value
              t.references :project, index: true
            end
          end
        end
      END_RUBY
    end

    File.open( Rails.root.join('plugins', 'dummy_plugin', 'app', 'models', 'dummy_entity.rb'), 'w' ) do |file|
      file.write( <<-END_RUBY )
        class DummyEntity < ActiveRecord::Base
        end
      END_RUBY
    end
  end

  def self.generate_autocomplete_controller!
    File.open(Rails.root.join('plugins', 'dummy_plugin', 'app', 'controllers', 'dummy_autocompletes_controller.rb'), 'w') do |file|
      file.write( <<-END_RUBY )
        class DummyAutocompletesController < ApplicationController
          def index
          end
        end
      END_RUBY
    end
  end

  def self.generate_autocomplete_routes!
    File.open(Rails.root.join('plugins', 'dummy_plugin', 'config', 'routes.rb'), 'w') do |file|
      file.write("resources :dummy_autocompletes")
    end
  end

  def self.generate_autocomplete_view!
    dir = Rails.root.join('plugins', 'dummy_plugin', 'app', 'views', 'dummy_autocompletes')
    Dir.mkdir dir
    File.open(dir.join('index.html.erb'), 'w') do |file|
      file.write( <<-END_ERB )
        <%= form_tag('/dummy_autocompletes', id: 'autocompletes_form') do %>
          <%= autocomplete_field_tag('default', ['value1', 'value2'], ['value1']) %>
        <% end %>
      END_ERB
    end
  end
end
