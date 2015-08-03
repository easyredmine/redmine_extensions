
module RedmineExtensions
  class Engine < ::Rails::Engine
    isolate_namespace RedmineExtensions

    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

    config.autoload_paths << config.root.join('lib')

    initializer 'redmine_extensions.initialize_environment' do |app|
      RedmineExtensions.app_root = app.root
    end

    initializer 'redmine_extensions.append_migrations' do |app|
      unless app.root.to_s.match root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    initializer 'redmine_extensions.register_easy_query_otputs' do |app|
      RedmineExtensions::QueryOutput.register_output :table, RedmineExtensions::QueryOutputs::TableOutput
    end

    # include helpers
    initializer 'redmine_extensions.action_controller' do |app|
      ActiveSupport.on_load :action_controller do
        helper RedmineExtensions::RenderingHelper
      end
    end

    # initializer :add_html_formatting do |app|
    #   require "redmine_extensions/html_formatting"
    #   Redmine::WikiFormatting.register(:HTML, RedmineExtensions::HTMLFormatting::Formatter, RedmineExtensions::HTMLFormatting::Helper)
    # end

  end
end
