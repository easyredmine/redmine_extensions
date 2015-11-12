require 'pp'

class EntityGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :plugin_name, type: :string, required: true, banner: 'NameOfNewPlugin'
  argument :model_name, type: :string, required: true, banner: 'Post'
  argument :attributes, type: :array, required: true, banner: 'field[:type][:index] field[:type][:index]'

  class_option :project, type: :boolean, default: true, banner: '', :desc => 'make model depends on project'
  class_option :author, type: :boolean, default: true, banner: '', :desc => 'make model depends on project'
  class_option :acts_as_activity_provider, type: :boolean, default: true, banner: '', :desc => 'changes in models are visible in user profile'
  class_option :acts_as_attachable, type: :boolean, default: true, banner: '', :desc => 'model have attachments'
  class_option :acts_as_customizable, type: :boolean, default: true, banner: '', :desc => 'model have custom fields'
  class_option :acts_as_event, type: :boolean, default: true, banner: '', :desc => 'model should be visible in a calendar'
  class_option :acts_as_list, type: :boolean, default: false, banner: '', :desc => 'model is sorted by position'
  class_option :acts_as_searchable, type: :boolean, default: true, banner: '', :desc => 'model is searchable'
  class_option :acts_as_tree, type: :boolean, default: false, banner: '', :desc => 'model have hierarchy'
  class_option :acts_as_versioned, type: :boolean, default: false, banner: '', :desc => 'model is versioned'
  class_option :acts_as_watchable, type: :boolean, default: false, banner: '', :desc => 'model have watchers'

  attr_reader :plugin_path, :plugin_name_underscored, :plugin_pretty_name, :plugin_title
  attr_reader :controller_class, :model_name_underscored, :model_name_pluralize_underscored
  attr_reader :columns

  def initialize(*args)
    super
    @plugin_name_underscored = plugin_name.underscore
    @plugin_pretty_name = @plugin_name_underscored.titleize
    @plugin_path = "plugins/#{@plugin_name_underscored}"
    @plugin_title = @plugin_name_underscored.camelize

    @model_name_underscored = model_name.underscore
    @model_name_pluralize_underscored = model_name.pluralize.underscore
    @controller_class = model_name.pluralize

    prepare_columns
  end

  def copy_templates
    template 'controller.rb.erb', "#{plugin_path}/app/controllers/#{model_name_pluralize_underscored}_controller.rb"
    template 'model.rb.erb', "#{plugin_path}/app/models/#{model_name_underscored}.rb"
    template 'index.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/index.html.erb"
    template 'show.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/show.html.erb"
    template 'new.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/new.html.erb"
    template 'edit.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/edit.html.erb"
    template '_form.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/_form.html.erb"

    if File.exists?("#{plugin_path}/config/routes.rb")
      append_to_file "#{plugin_path}/config/routes.rb" do
        "\nresources :#{model_name_pluralize_underscored}"
      end
    else
      template 'routes.rb.erb', "#{plugin_path}/config/routes.rb"
    end

    if File.exists?("#{plugin_path}/config/locales/en.yml")
      append_to_file "#{plugin_path}/config/locales/en.yml" do
        "\n  heading_#{model_name_pluralize_underscored}_new: New #{plugin_pretty_name}" +
            "\n  heading_#{model_name_pluralize_underscored}_edit: Edit #{plugin_pretty_name}"
      end
    else
      template 'en.yml.erb', "#{plugin_path}/config/locales/en.yml"
    end

    template 'migration.rb.erb', "#{plugin_path}/db/migrate/#{Time.now.strftime('%Y%m%d%H%M%S')}_create_#{@model_name_pluralize_underscored}.rb"
  end

  private

  def project?
    options[:project] == true
  end

  def author?
    options[:author] == true
  end

  def prepare_columns
    @columns = {}

    attributes.each do |attr|
      attr_name, attr_type, attr_idx = attr.split(':')
      @columns[attr_name] = {type: attr_type || 'string', idx: attr_idx, safe: true}
    end

    @columns['project_id'] = {type: 'integer', idx: nil, safe: false} if project? && !@columns.key?('project_id')
    @columns['author_id'] = {type: 'integer', idx: nil, safe: false} if author? && !@columns.key?('author_id')
    @columns['timestamps'] = {}
  end

  def safe_columns
    @columns.select{|_, column_options| column_options[:safe]}.collect{|column_name, _| column_name}
  end

  def print_column_migration(column_name, column_attrs)
    case column_name
      when 'timestamps'
        't.timestamps null: false'
      else
        "t.#{column_attrs[:type]} :#{column_name}"
    end
  end

  def view_permission
    "view_#{@model_name_pluralize_underscored}"
  end

  def edit_permission
    "edit_#{@model_name_pluralize_underscored}"
  end

end
