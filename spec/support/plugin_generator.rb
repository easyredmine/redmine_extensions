require 'rails/generators'

module PluginGenerator
  def self.generate_test_plugin!
    Rails::Generators.invoke 'redmine_extensions:plugin', ['DummyPlugin'], behavior: :revoke, destination_root: Rails.root
    Rails::Generators.invoke 'redmine_extensions:plugin', ['DummyPlugin'], behavior: :invoke, destination_root: Rails.root
    if Rails::VERSION::MAJOR >= 5
      Rails.application.reloader.reload!
    else
      ActionDispatch::Reloader.cleanup!
      ActionDispatch::Reloader.prepare!
    end

    generate_controller!
    generate_routes!
    generate_view!
  end

  def self.generate_controller!
    File.open(Rails.root.join('plugins', 'dummy_plugin', 'app', 'controllers', 'dummies_controller.rb'), 'w') do |file|
      file.write("class DummiesController < ApplicationController")
      file.write("  def index")
      file.write("  end")
      file.write("end")
    end
  end

  def self.generate_routes!
    File.open(Rails.root.join('plugins', 'dummy_plugin', 'config', 'routes.rb'), 'w') do |file|
      file.write("resources :dummy")
    end
  end

  def self.generate_view!
    File.open(Rails.root.join('plugins', 'dummy_plugin', 'app', 'views', 'index.html.erb'), 'w') do |file|
      file.write("<%= autocomplete_field_tag('default', [['value1'], ['value2']], ['value1']) %>")
    end
  end
end
