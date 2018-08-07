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
    generate_entities_view!
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
              t.text :array_of_dummies
            end
          end
        end
      END_RUBY
    end

    File.open( Rails.root.join('plugins', 'dummy_plugin', 'app', 'models', 'dummy_entity.rb'), 'w' ) do |file|
      file.write( <<-END_RUBY )
        class DummyEntity < ActiveRecord::Base
          include Redmine::SafeAttributes
          safe_attributes 'name',
                          'value',
                          'project_id',
                          'array_of_dummies'

          attr_protected :id

          serialize :array_of_dummies, Array
        end
      END_RUBY
    end

    File.open(Rails.root.join('plugins', 'dummy_plugin', 'app', 'controllers', 'dummy_entities_controller.rb'), 'w') do |file|
      file.write( <<-END_RUBY )
        class DummyEntitiesController < ApplicationController
          def index
          end

          def create
            @entity = DummyEntity.new
            @entity.safe_attributes = params[:dummy_entity]
            @entity.save
          end
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
      file.write( <<-END_ROUTES )
        resources :dummy_autocompletes
        resources :dummy_entities
      END_ROUTES
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

        <%= form_for(DummyEntity.new(array_of_dummies: ['value1'])) do |f| %>
          <%= f.autocomplete_field(:array_of_dummies, ['value1', 'value2'], {}, id: 'dummy_entities_autocomplete') %>
        <% end %>
      END_ERB
    end
  end

  def self.generate_entities_view!
    dir = Rails.root.join('plugins', 'dummy_plugin', 'app', 'views', 'dummy_entities')
    Dir.mkdir dir
    File.open(dir.join('index.html.erb'), 'w') do |file|
      file.write( <<-END_ERB )
        <% DummyEntity.all.each do |entity| %>
          <%= entity.name %>: <%= entity.value %>
        <% end %>
      END_ERB
    end
  end
end
