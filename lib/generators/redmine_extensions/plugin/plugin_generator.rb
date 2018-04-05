module RedmineExtensions
  class PluginGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    attr_reader :plugin_path, :plugin_name_underscored, :plugin_pretty_name, :plugin_title, :easy_plugin

    class_option :customer, type: :boolean, default: false, banner: '', :desc => 'plugin will act as customer modification. It is useful for changing few things and be uptodate with the core.'
    class_option :easy_plugin, type: :boolean, default: false, banner: '', :desc => 'generate easy plugin'

    def initialize(*args)
      super
      @easy_plugin = options[:easy_plugin]
      @plugin_name_underscored = options[:customer] ? "modification_#{file_name.underscore}" : file_name.underscore
      @plugin_pretty_name = plugin_name_underscored.titleize

      @plugin_path = (easy_plugin ? "plugins/easyproject/easy_plugins" : "plugins") + "/#{plugin_name_underscored}"
      @plugin_title = @plugin_name_underscored.camelize
    end

    def copy_templates
      empty_directory "#{plugin_path}/app"
      empty_directory "#{plugin_path}/app/controllers"
      empty_directory "#{plugin_path}/app/helpers"
      empty_directory "#{plugin_path}/app/models"
      empty_directory "#{plugin_path}/app/views"
      empty_directory "#{plugin_path}/db/migrate"
      empty_directory "#{plugin_path}/db/data"
      empty_directory "#{plugin_path}/assets/images"
      empty_directory "#{plugin_path}/assets/javascripts"
      empty_directory "#{plugin_path}/assets/stylesheets"
      empty_directory "#{plugin_path}/config/locales"
      empty_directory "#{plugin_path}/lib/#{plugin_name_underscored}"

      empty_directory "#{plugin_path}/lib/#{plugin_name_underscored}/easy_patch/redmine/controllers"
      empty_directory "#{plugin_path}/lib/#{plugin_name_underscored}/easy_patch/redmine/helpers"
      empty_directory "#{plugin_path}/lib/#{plugin_name_underscored}/easy_patch/redmine/models"
      empty_directory "#{plugin_path}/lib/#{plugin_name_underscored}/easy_patch/redmine/others"

      template 'gitkeep.erb', "#{plugin_path}/app/controllers/.gitkeep"
      template 'gitkeep.erb', "#{plugin_path}/app/helpers/.gitkeep"
      template 'gitkeep.erb', "#{plugin_path}/app/models/.gitkeep"
      template 'gitkeep.erb', "#{plugin_path}/app/views/.gitkeep"
      template 'gitkeep.erb', "#{plugin_path}/db/migrate/.gitkeep"
      template 'gitkeep.erb', "#{plugin_path}/assets/images/.gitkeep"
      template 'gitkeep.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/easy_patch/redmine/others/.gitkeep"

      template 'after_init.rb.erb', "#{plugin_path}/after_init.rb"
      template 'Gemfile.erb', "#{plugin_path}/Gemfile" unless easy_plugin
      template 'init.rb.erb', "#{plugin_path}/init.rb"
      template 'javascript.js', "#{plugin_path}/assets/javascripts/#{plugin_name_underscored}.js"
      template 'stylesheet.css', "#{plugin_path}/assets/stylesheets/#{plugin_name_underscored}.css"
      template 'en.yml.erb', "#{plugin_path}/config/locales/en.yml"
      template 'routes.rb.erb', "#{plugin_path}/config/routes.rb"
      template 'hooks.rb.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/hooks.rb"
      template 'internals.rb.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/internals.rb"
      template 'issue_patch.example.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/easy_patch/redmine/models/issue_patch.example"
      template 'issues_controller_patch.example.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/easy_patch/redmine/controllers/issues_controller_patch.example"
      template 'issues_helper_patch.example.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/easy_patch/redmine/helpers/issues_helper_patch.example"
    end

    hook_for :entity, as: :entity, in: :redmine_extensions, type: :boolean

  end
end
