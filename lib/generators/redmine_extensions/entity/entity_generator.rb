module RedmineExtensions
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
    attr_reader :db_columns

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
      template '_form.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/_form.html.erb"
      template '_view_custom_fields_form_custom_field.html.erb.erb', "#{plugin_path}/app/views/custom_fields/_view_custom_fields_form_#{model_name_underscored}_custom_field.html.erb"
      template 'context_menu.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/context_menu.html.erb"
      template 'controller.rb.erb', "#{plugin_path}/app/controllers/#{model_name_pluralize_underscored}_controller.rb"
      template('custom_field.rb.erb', "#{plugin_path}/app/models/#{model_name_underscored}_custom_field.rb") if acts_as_customizable?
      template 'edit.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/edit.html.erb"

      if File.exists?("#{plugin_path}/config/locales/en.yml")
        append_to_file "#{plugin_path}/config/locales/en.yml" do
          "\n  heading_#{model_name_underscored}_new: New #{model_name_underscored.titleize}" +
            "\n  heading_#{model_name_underscored}_edit: Edit #{model_name_underscored.titleize}" +
            "\n  button_#{model_name_underscored}_new: New #{model_name_underscored.titleize}" +
            "\n  label_#{model_name_pluralize_underscored}: #{@model_name_pluralize_underscored.titleize}" +
            "\n  label_#{model_name_underscored}: #{model_name_underscored.titleize}" +
            "\n  permission_view_#{model_name_pluralize_underscored}: View #{model_name_pluralize_underscored.titleize}" +
            "\n  permission_manage_#{model_name_pluralize_underscored}: Manage #{model_name_pluralize_underscored.titleize}" +
            "\n  title_#{model_name_underscored}_new: Click to create new #{model_name_underscored.titleize}"
        end
        append_to_file "#{plugin_path}/config/locales/en.yml" do
          db_columns.collect{|column_name, _| "\n  field_#{model_name_underscored}_#{column_name}: #{column_name.humanize}"  }.join
        end
      else
        template 'en.yml.erb', "#{plugin_path}/config/locales/en.yml"
      end

      template 'helper.rb.erb', "#{plugin_path}/app/helpers/#{model_name_pluralize_underscored}_helper.rb"
      template 'hooks.rb.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/#{model_name_underscored}_hooks.rb"
      template 'index.api.rsb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/index.api.rsb"
      template 'index.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/index.html.erb"
      template 'migration.rb.erb', "#{plugin_path}/db/migrate/#{Time.now.strftime('%Y%m%d%H%M%S')}_create_#{@model_name_pluralize_underscored}.rb"
      template 'model.rb.erb', "#{plugin_path}/app/models/#{model_name_underscored}.rb"
      template 'new.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/new.html.erb"
      template 'query.rb.erb', "#{plugin_path}/app/models/#{model_name_underscored}_query.rb"

      if File.exists?("#{plugin_path}/config/routes.rb")
        if project?
          append_to_file "#{plugin_path}/config/routes.rb" do
            "\nresources :projects do " +
              "\n  resources :#{model_name_pluralize_underscored}" +
              "\nend\n"
          end
        end
        append_to_file "#{plugin_path}/config/routes.rb" do
          "\nresources :#{model_name_pluralize_underscored} do" +
            "\n  collection do " +
            "\n    get 'bulk_edit'" +
            "\n    post 'bulk_update'" +
            "\n    get 'context_menu'" +
            "\n  end" +
            "\nend"
        end
      else
        template 'routes.rb.erb', "#{plugin_path}/config/routes.rb"
      end

      if File.exists?("#{plugin_path}/init.rb")
        append_to_file "#{plugin_path}/init.rb" do
          "\nrequire '#{plugin_name_underscored}/#{model_name_underscored}_hooks'" +
            "\nRedmine::AccessControl.map do |map|" +
            "\n  map.project_module :#{model_name_pluralize_underscored} do |pmap|" +
            "\n    pmap.permission :view_#{model_name_pluralize_underscored}, { :#{model_name_pluralize_underscored} => [:index, :show] }, read: true" +
            "\n    pmap.permission :manage_#{model_name_pluralize_underscored}, { :#{model_name_pluralize_underscored} => [:new, :create, :edit, :update, :destroy, :bulk_edit, :bulk_update, :context_menu] }" +
            "\n  end " +
            "\nend\n" +
            "\nRedmine::MenuManager.map :top_menu do |menu|" +
            "\n  menu.push :#{model_name_pluralize_underscored}, { :controller => '#{model_name_pluralize_underscored}', :action => 'index' }, caption: :label_#{model_name_pluralize_underscored}" +
            "\nend\n" +
            "\nRedmine::MenuManager.map :project_menu do |menu|" +
            "\n  menu.push :#{model_name_pluralize_underscored}, { :controller => '#{model_name_pluralize_underscored}', :action => 'index' }, param: :project_id, caption: :label_#{model_name_pluralize_underscored}" +
            "\nend\n"
        end
        if acts_as_customizable?
          append_to_file "#{plugin_path}/init.rb" do
            "\nCustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => '#{model_name}CustomField', :partial => 'custom_fields/index', :label => :label_#{model_name_pluralize_underscored}}"
          end
        end
      end


      template 'show.api.rsb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/show.api.rsb"
      template 'show.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/show.html.erb"
    end

    private

    def project?
      options[:project] == true
    end

    def author?
      options[:author] == true
    end

    def acts_as_customizable?
      options[:acts_as_customizable] == true
    end

    def acts_as_searchable?
      options[:acts_as_searchable] == true
    end

    def acts_as_activity_provider?
      options[:acts_as_activity_provider] == true
    end

    def acts_as_attachable?
      options[:acts_as_attachable] == true
    end

    def acts_as_event?
      options[:acts_as_event] == true
    end

    def acts_as_list?
      options[:acts_as_list] == true
    end

    def acts_as_tree?
      options[:acts_as_tree] == true
    end

    def acts_as_versioned?
      options[:acts_as_versioned] == true
    end

    def acts_as_watchable?
      options[:acts_as_watchable] == true
    end

    def prepare_columns
      @db_columns = {}

      attributes.each do |attr|
        attr_name, attr_type, attr_idx = attr.split(':')
        @db_columns[attr_name] = {type: attr_type || 'string', idx: attr_idx, null: true, safe: true, query_type: attr_type || 'string'}
      end

      @db_columns['project_id'] = {type: 'integer', idx: nil, null: false, safe: false, class: 'Project', list_class_name: 'name', query_type: 'list_optional', query_column_name: 'project'} if project? && !@db_columns.key?('project_id')
      @db_columns['author_id'] = {type: 'integer', idx: nil, null: false, safe: true, class: 'User', list_class_name: 'name', query_type: 'list', query_column_name: 'author'} if author? && !@db_columns.key?('author_id')
      @db_columns['created_at'] = {type: 'datetime', idx: nil, null: false, safe: false, query_type: 'date'}
      @db_columns['updated_at'] = {type: 'datetime', idx: nil, null: false, safe: false, query_type: 'date'}
    end

    def safe_columns
      @db_columns.select { |_, column_options| column_options[:safe] }.collect { |column_name, _| column_name }
    end

    def string_columns
      @db_columns.select { |_, column_options| column_options[:safe] && column_options[:type] == 'string' }.collect { |column_name, _| column_name }
    end

    def form_columns
      @db_columns.select { |_, column_options| column_options[:safe] }
    end

    def name_column?
      safe_columns.include?('name')
    end

    def name_column
      'name' if name_column?
    end

    def view_permission
      "view_#{@model_name_pluralize_underscored}"
    end

    def edit_permission
      "edit_#{@model_name_pluralize_underscored}"
    end

    def delete_permission
      "edit_#{@model_name_pluralize_underscored}"
    end

  end
end
