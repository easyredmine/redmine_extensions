require 'active_support/dependencies'
require_relative './patch_manager'
require_relative './redmine_patches/controllers/application_controller_patch'
require_relative './redmine_patches/models/project_patch'

require_relative './query_output'

module RedmineExtensions
  class Engine < ::Rails::Engine

    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

    config.autoload_paths << config.root.join('lib')
    config.eager_load_paths << config.root.join('app', 'models', 'easy_queries')
    config.assets.precompile << 'redmine_extensions/applications.js'
    config.assets.precompile << 'redmine_extensions/blocking.js'
    unless Rails.env.production?
      config.assets.precompile << 'redmine_extensions/jasmine_lib/jasmine_lib.js'
      config.assets.precompile << 'redmine_extensions/jasmine.css'
    end

    #config.to_prepare goes after Reloader.to_prepare
    RedmineExtensions::Reloader.to_prepare do
      RedmineExtensions::QueryOutput.register_output RedmineExtensions::QueryOutputs::ListOutput
      RedmineExtensions::QueryOutput.register_output RedmineExtensions::QueryOutputs::TilesOutput
      # RedmineExtensions::BasePresenter.register 'RedmineExtensions::EasyQueryPresenter', 'EasyQuery'
      # ApplicationController.send :include, RedmineExtensions::RailsPatches::ControllerQueryHelpers
      ApplicationController.include RedmineExtensions::RenderingHelper
    end

    initializer 'redmine_extensions.initialize' do |app|
      ActionDispatch::Routing::RouteSet::Generator.prepend RedmineExtensions::RailsPatches::RouteSetGeneratorPatch
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
      ActiveSupport.on_load(:action_view) do
        default_form_builder.include RedmineExtensions::RailsPatches::FormBuilderPatch
      end
    end

    initializer 'redmine_extensions.initialize_easy_plugins', after: :load_config_initializers do
      require_relative './hooks'

      unless Redmine::Plugin.installed?(:easy_extensions)
        ActiveSupport.run_load_hooks(:easyproject, self)
      end

      require_relative './easy_entity_formatters/easy_entity_formatter'
    end

    # initializer :add_html_formatting do |app|
    #   require_relative "./html_formatting"
    #   Redmine::WikiFormatting.register(:HTML, RedmineExtensions::HTMLFormatting::Formatter, RedmineExtensions::HTMLFormatting::Helper)
    # end

  end
end
