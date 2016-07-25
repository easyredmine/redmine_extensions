module RedmineExtensions
  class EntityGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    argument :plugin_name, type: :string, required: true, banner: 'NameOfNewPlugin'
    argument :model_name, type: :string, required: true, banner: 'Post'
    argument :attributes, type: :array, required: true, banner: 'field[:type][:index] field[:type][:index]'

    class_option :project, type: :boolean, default: true, banner: '', :desc => 'make model depends on project'
    class_option :author, type: :boolean, default: true, banner: '', :desc => 'make model depends on project'
    class_option :mail, type: :boolean, default: true, banner: '', :desc => 'model have mail notifications'
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
      template '_sidebar.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/_sidebar.html.erb"
      template 'context_menu.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/context_menu.html.erb"
      template 'controller.rb.erb', "#{plugin_path}/app/controllers/#{model_name_pluralize_underscored}_controller.rb"
      template('custom_field.rb.erb', "#{plugin_path}/app/models/#{model_name_underscored}_custom_field.rb") if acts_as_customizable?
      template 'edit.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/edit.html.erb"
      template 'edit.js.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/edit.js.erb"

      if File.exists?("#{plugin_path}/config/locales/en.yml")
        append_to_file "#{plugin_path}/config/locales/en.yml" do
          "\n  activerecord:" +
            "\n  easy_query:" +
            "\n    attributes:" +
            "\n      #{model_name_underscored}:" +
            db_columns.collect { |column_name, column_options| "\n        #{column_options[:lang_key]}: #{column_name.humanize}" }.join +
            "\n    name:" +
            "\n      #{model_name_underscored}_query: #{model_name_pluralize_underscored.titleize}" +
            "\n  heading_#{model_name_underscored}_new: New #{model_name_underscored.titleize}" +
            "\n  heading_#{model_name_underscored}_edit: Edit #{model_name_underscored.titleize}" +
            "\n  button_#{model_name_underscored}_new: New #{model_name_underscored.titleize}" +
            "\n  label_#{model_name_pluralize_underscored}: #{@model_name_pluralize_underscored.titleize}" +
            "\n  label_#{model_name_underscored}: #{model_name_underscored.titleize}" +
            "\n  permission_view_#{model_name_pluralize_underscored}: View #{model_name_pluralize_underscored.titleize}" +
            "\n  permission_manage_#{model_name_pluralize_underscored}: Manage #{model_name_pluralize_underscored.titleize}" +
            "\n  title_#{model_name_underscored}_new: Click to create new #{model_name_underscored.titleize}"
        end
      else
        template 'en.yml.erb', "#{plugin_path}/config/locales/en.yml"
      end

      template 'helper.rb.erb', "#{plugin_path}/app/helpers/#{model_name_pluralize_underscored}_helper.rb"
      template 'hooks.rb.erb', "#{plugin_path}/lib/#{plugin_name_underscored}/#{model_name_underscored}_hooks.rb"
      template 'index.api.rsb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/index.api.rsb"
      template 'index.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/index.html.erb"
      template 'index.js.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/index.js.erb"

      if mail?
        template 'mailer.rb.erb', "#{plugin_path}/app/models/#{model_name_underscored}_mailer.rb"
        template 'mail_added.html.erb.erb', "#{plugin_path}/app/views/#{model_name_underscored}_mailer/#{model_name_underscored}_added.html.erb"
        template 'mail_added.text.erb.erb', "#{plugin_path}/app/views/#{model_name_underscored}_mailer/#{model_name_underscored}_added.text.erb"
        template 'mail_updated.html.erb.erb', "#{plugin_path}/app/views/#{model_name_underscored}_mailer/#{model_name_underscored}_updated.html.erb"
        template 'mail_updated.text.erb.erb', "#{plugin_path}/app/views/#{model_name_underscored}_mailer/#{model_name_underscored}_updated.text.erb"
      end

      template 'migration.rb.erb', "#{plugin_path}/db/migrate/#{Time.now.strftime('%Y%m%d%H%M%S')}_create_#{@model_name_pluralize_underscored}.rb"
      template 'model.rb.erb', "#{plugin_path}/app/models/#{model_name_underscored}.rb"
      template 'new.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/new.html.erb"
      template 'new.js.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/new.js.erb"
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
            "\n    get 'autocomplete'" +
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
        s = "\nActiveSupport.on_load(:easyproject, yield: true) do"
        s << "\n  require '#{plugin_name_underscored}/#{model_name_underscored}_hooks'\n"
        s << "\n  Redmine::AccessControl.map do |map|"
        s << "\n    map.project_module :#{model_name_pluralize_underscored} do |pmap|"
        s << "\n      pmap.permission :view_#{model_name_pluralize_underscored}, { #{model_name_pluralize_underscored}: [:index, :show, :autocomplete, :context_menu] }, read: true"
        s << "\n      pmap.permission :manage_#{model_name_pluralize_underscored}, { #{model_name_pluralize_underscored}: [:new, :create, :edit, :update, :destroy, :bulk_edit, :bulk_update] }"
        s << "\n    end "
        s << "\n  end\n"
        s << "\n  Redmine::MenuManager.map :top_menu do |menu|"
        s << "\n    menu.push :#{model_name_pluralize_underscored}, { controller: '#{model_name_pluralize_underscored}', action: 'index', project_id: nil }, caption: :label_#{model_name_pluralize_underscored}"
        s << "\n  end\n"
        if project?
          s << "\n  Redmine::MenuManager.map :project_menu do |menu|"
          s << "\n    menu.push :#{model_name_pluralize_underscored}, { controller: '#{model_name_pluralize_underscored}', action: 'index' }, param: :project_id, caption: :label_#{model_name_pluralize_underscored}"
          s << "\n  end\n"
        end
        if acts_as_customizable?
          s << "\n  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {name: '#{model_name}CustomField', partial: 'custom_fields/index', label: :label_#{model_name_pluralize_underscored}}\n"
        end
        if acts_as_searchable?
          s << "\n  Redmine::Search.map do |search|"
          s << "\n    search.register :#{model_name_pluralize_underscored}"
          s << "\n  end\n"
        end
        if acts_as_activity_provider?
          s << "\n  Redmine::Activity.map do |activity|"
          s << "\n    activity.register :#{model_name_pluralize_underscored}, {class_name: %w(#{model_name}), default: false}"
          s << "\n  end\n"
        end
        s << "\nend"

        append_to_file "#{plugin_path}/init.rb", s
      end


      template 'show.api.rsb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/show.api.rsb"
      template 'show.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/show.html.erb"
      template 'show.js.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/show.js.erb"
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

    def mail?
      options[:mail] == true
    end

    def prepare_columns
      @db_columns = {}

      attributes.each do |attr|
        attr_name, attr_type, attr_idx = attr.split(':')
        #lang_key = "field_#{model_name_underscored}_#{attr_name.to_s.sub(/_id$/, '').sub(/^.+\./, '')}"
        lang_key = "#{attr_name.to_s.sub(/_id$/, '').sub(/^.+\./, '')}"

        @db_columns[attr_name] = {type: attr_type || 'string', idx: attr_idx, null: true, safe: true, query_type: attr_type || 'string', lang_key: lang_key}
      end

      @db_columns['project_id'] = {type: 'integer', idx: nil, null: false, safe: false, class: 'Project', list_class_name: 'name', query_type: 'list_optional', query_column_name: 'project', lang_key: "field_#{model_name_underscored}_project"} if project? && !@db_columns.key?('project_id')
      @db_columns['author_id'] = {type: 'integer', idx: nil, null: false, safe: true, class: 'User', list_class_name: 'name', query_type: 'list', query_column_name: 'author', lang_key: "field_#{model_name_underscored}_author"} if author? && !@db_columns.key?('author_id')
      @db_columns['created_at'] = {type: 'datetime', idx: nil, null: false, safe: false, query_type: 'date', lang_key: "field_#{model_name_underscored}_created_at"}
      @db_columns['updated_at'] = {type: 'datetime', idx: nil, null: false, safe: false, query_type: 'date', lang_key: "field_#{model_name_underscored}_updated_at"}
    end

    def safe_columns
      @db_columns.select { |_, column_options| column_options[:safe] }
    end

    def string_columns
      @db_columns.select { |_, column_options| column_options[:safe] && column_options[:type] == 'string' }
    end

    def text_columns
      @db_columns.select { |_, column_options| column_options[:safe] && column_options[:type] == 'text' }
    end

    def form_columns
      @db_columns.select { |_, column_options| column_options[:safe] }
    end

    def name_column
      'name' if string_columns.keys.include?('name')
      string_columns.keys.first
    end

    def name_column?
      !name_column.blank?
    end

    def description_column
      'description' if text_columns.keys.include?('description')
      text_columns.keys.first
    end

    def description_column?
      !description_column.blank?
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
