class RedmineExtensionsRestGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  argument :model_name, :type => :string, :required => true, :desc => 'kuk 1', :banner => 'kuk 1'

  attr_reader :plugin_path, :plugin_name_underscored, :plugin_pretty_name, :plugin_title
  attr_reader :controller_class, :model_name_underscored, :model_name_pluralize_underscored

  def initialize(*args)
    super
    @plugin_name_underscored = file_name.underscore
    @plugin_pretty_name = plugin_name_underscored.titleize
    @plugin_path = "plugins/#{plugin_name_underscored}"
    @plugin_title = @plugin_name_underscored.camelize

    @model_name_underscored = model_name.underscore
    @model_name_pluralize_underscored = model_name.pluralize.underscore
    @controller_class = model_name.pluralize
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

  end

end
