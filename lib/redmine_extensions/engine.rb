require 'redmine_extensions/patch_manager'
require 'redmine_extensions/redmine_patches/patches'

module RedmineExtensions
  class Engine < ::Rails::Engine

    def self.automount!(path = nil)
      engine = self
      path ||= engine.to_s.underscore.split('/').first
      Rails.application.routes.draw do
        mount engine => path
        resources :easy_settings, only: [:edit]
      end
    end

    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

    config.autoload_paths << config.root.join('lib')
    config.eager_load_paths << config.root.join('app', 'models', 'easy_queries')

    #config.to_prepare goes after Reloader.to_prepare
    ActionDispatch::Reloader.to_prepare do
      RedmineExtensions::QueryOutput.register_output RedmineExtensions::QueryOutputs::ListOutput
      RedmineExtensions::QueryOutput.register_output RedmineExtensions::QueryOutputs::TileOutput
      # RedmineExtensions::BasePresenter.register 'RedmineExtensions::EasyQueryPresenter', 'EasyQuery'
      # ApplicationController.send :include, RedmineExtensions::RailsPatches::ControllerQueryHelpers
      ApplicationController.send :include, RedmineExtensions::RenderingHelper
    end

    initializer 'redmine_extensions.initialize' do |app|
      ActionDispatch::Routing::RouteSet::Generator.send(:include, RedmineExtensions::RailsPatches::RouteSetGeneratorPatch)
    end

    initializer 'redmine_extensions.append_migrations' do |app|
      unless app.root.to_s.match root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
      if true
        js_dir = app.root.join('public', 'javascripts', 'redmine_extensions')
        FileUtils.mkdir(js_dir) unless File.directory?(js_dir)
        Dir.glob( root.join('app', 'assets', 'javascripts', 'redmine_extensions', '*.js') ) do |js_file|
          begin
            FileUtils.cp(js_file, app.root.join('public', 'javascripts', 'redmine_extensions'))
          rescue
          end
        end
      end
    end

    # include helpers
    initializer 'redmine_extensions.rails_patching', before: :load_config_initializers do |app|
      ActiveSupport.on_load :action_controller do
        helper RedmineExtensions::ApplicationHelper
        # helper RedmineExtensions::EasyQueryHelper
      end
      ActiveSupport.on_load(:active_record) do
        include RedmineExtensions::RailsPatches::ActiveRecord
      end
    end

    initializer 'redmine_extensions.initialize_easy_plugins', after: :load_config_initializers do
      require 'redmine_extensions/hooks'
      RedmineExtensions.load_easy_plugins

      unless Redmine::Plugin.installed?(:easy_extensions)
        ActiveSupport.run_load_hooks(:easyproject, self)
      end

      require 'redmine_extensions/easy_query_adapter'
      require 'redmine_extensions/easy_entity_formatters/easy_entity_formatter'
    end

    # initializer :add_html_formatting do |app|
    #   require "redmine_extensions/html_formatting"
    #   Redmine::WikiFormatting.register(:HTML, RedmineExtensions::HTMLFormatting::Formatter, RedmineExtensions::HTMLFormatting::Helper)
    # end

  end
end
