module RedmineExtensions
  class EntityGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    argument :plugin_name, type: :string, required: true, banner: 'NameOfNewPlugin'
    argument :model_name, type: :string, required: true, banner: 'Post'
    argument :attributes, type: :array, required: true, banner: 'field[:type][:index] field[:type][:index]'

    class_option :associations, type: :array, required: false, banner: '--associations association_type[:association_name][:association_class]'

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
    attr_reader :associations

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

      template 'controller_spec.rb.erb', "#{plugin_path}/test/spec/controllers/#{model_name_pluralize_underscored}_controller_spec.rb"
      template 'factories.rb.erb', "#{plugin_path}/test/factories/#{model_name_underscored}.rb"

      if File.exists?("#{plugin_path}/config/locales/en.yml")
        original_langfile = YAML.load_file("#{plugin_path}/config/locales/en.yml")

        template 'en.yml.erb', "#{plugin_path}/tmp/tmp_en.yml", pretend: true
        if File.exist?("#{plugin_path}/tmp/tmp_en.yml")
          added_translations = YAML.load_file("#{plugin_path}/tmp/tmp_en.yml")
          File.delete("#{plugin_path}/tmp/tmp_en.yml")

          merged_langfile = original_langfile.deep_merge(added_translations)
          File.open("#{plugin_path}/config/locales/en.yml", "w") do |file|
            file.write merged_langfile.to_yaml
          end
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

      template 'migration.rb.erb', "#{plugin_path}/db/migrate/#{Time.now.strftime('%Y%m%d%H%M%S%L')}_create_#{@model_name_pluralize_underscored}.rb"
      template 'model.rb.erb', "#{plugin_path}/app/models/#{model_name_underscored}.rb"
      template 'new.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/new.html.erb"
      template 'new.js.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/new.js.erb"

      if Redmine::Plugin.installed?(:easy_extensions)
        template 'easy_query.rb.erb', "#{plugin_path}/app/models/#{model_name_underscored}_query.rb"
        template 'entity_attribute_helper_patch.rb.erb', "#{plugin_path}/extra/easy_patch/easy_extensions/helpers/entity_attribute_helper_patch.rb"

        if File.exists?("#{plugin_path}/extra/easy_patch/easy_extensions/helpers/entity_attribute_helper_patch.rb")

          inject_into_file "#{plugin_path}/extra/easy_patch/easy_extensions/helpers/entity_attribute_helper_patch.rb",
              "\n       def format_html_#{model_name_underscored}_attribute(entity_class, attribute, unformatted_value, options={})" +
              "\n          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)" +
              "\n          case attribute.name" +
              "\n          when :name" +
              "\n            link_to(value, #{model_name_underscored.singularize}_path(options[:entity].id))" +
              "\n          else" +
              "\n            h(value)" +
              "\n          end" +
              "\n        end" +
              "\n", after: "base.class_eval do"

        end
      else
        template 'query.rb.erb', "#{plugin_path}/app/models/#{model_name_underscored}_query.rb"
      end

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

      if File.exists?("#{plugin_path}/after_init.rb")
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

        append_to_file "#{plugin_path}/after_init.rb", s
      end


      template 'show.api.rsb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/show.api.rsb"
      template 'show.html.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/show.html.erb"
      template 'show.js.erb.erb', "#{plugin_path}/app/views/#{model_name_pluralize_underscored}/show.js.erb"
    end

    private

    def assocs
      options[:associations]
    end

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
      prepare_associations

      attributes.each do |attr|
        attr_name, attr_type, attr_idx = attr.split(':')
        #lang_key = "field_#{model_name_underscored}_#{attr_name.to_s.sub(/_id$/, '').sub(/^.+\./, '')}"
        lang_key = "#{attr_name.to_s.sub(/_id$/, '').sub(/^.+\./, '')}"
        if attr_type == 'timestamp'
          @timestamp_exist = true
        else
          @db_columns[attr_name] = {type: attr_type || 'string', idx: attr_idx, null: true, safe: true, query_type: attr_type || 'string', lang_key: lang_key}
        end
      end

      @db_columns['project_id'] = {type: 'integer', idx: nil, null: false, safe: false, class: 'Project', list_class_name: 'name', query_type: 'list_optional', query_column_name: 'project', lang_key: "field_#{model_name_underscored}_project"} if project? && !@db_columns.key?('project_id')
      @db_columns['author_id'] = {type: 'integer', idx: nil, null: false, safe: true, class: 'User', list_class_name: 'name', query_type: 'list', query_column_name: 'author', lang_key: "field_#{model_name_underscored}_author"} if author? && !@db_columns.key?('author_id')

      @db_columns['created_at'] = {type: 'datetime', idx: nil, null: false, safe: false, query_type: 'date', lang_key: "field_#{model_name_underscored}_created_at"}
      @db_columns['updated_at'] = {type: 'datetime', idx: nil, null: false, safe: false, query_type: 'date', lang_key: "field_#{model_name_underscored}_updated_at"}
    end

    def prepare_associations
      @associations = {}

      return true if assocs.nil?

      assocs.each do |assoc|
        assoc_type, assoc_name, assoc_class = assoc.split(':')
        next if assoc_type.blank? || assoc_name.blank?

        @associations[assoc_name] = {type: assoc_type, class: assoc_class}

        assoc_model_class = assoc_class.presence || assoc_name.singularize.camelize
        assoc_model_filename = assoc_model_class.underscore
        assoc_model_path = "#{plugin_path}/app/models/#{assoc_model_filename}.rb"

        case assoc_type
        when 'has_many', 'has_one'
          if File.exists?(assoc_model_path)
            line = "class #{assoc_model_class} < ActiveRecord::Base"
            gsub_file assoc_model_path, /(#{Regexp.escape(line)})/mi do |match|
              "#{match}\n  belongs_to :#{model_name.underscore}\n"
            end
          end
        when 'belongs_to'
          if File.exists?(assoc_model_path)
            unless File.readlines(assoc_model_path).grep(/has_many\ :#{model_name.underscore.pluralize}/).any?
              line = "class #{assoc_model_class} < ActiveRecord::Base"
              gsub_file assoc_model_path, /(#{Regexp.escape(line)})/mi do |match|
                "#{match}\n  has_many :#{model_name.underscore.pluralize}\n"
              end
            end
          end

          @db_columns["#{assoc_model_class.underscore.singularize}_id"] = {type: 'integer', idx: true, lang_key: assoc_model_class.underscore, query_type: 'list_optional', null: true}
        end
      end
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
      "manage_#{@model_name_pluralize_underscored}"
    end

    def delete_permission
      "manage_#{@model_name_pluralize_underscored}"
    end

  end
end
