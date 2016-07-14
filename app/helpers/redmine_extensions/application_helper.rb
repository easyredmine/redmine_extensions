module RedmineExtensions
  module ApplicationHelper
    include RenderingHelper

    # -------= Hack methods =------

    def plugin_settings_path(plugin, *attrs)
      if plugin.is_a?(Redmine::Plugin) && (plugin.settings[:only_easy] || plugin.settings[:easy_settings])
        redmine_extensions_engine.edit_easy_setting_path(plugin, *attrs)
      else
        super
      end
    end

    # -------= Rendering and presenting methods =-------

    def present(model, options={}, &block)
      if model.is_a?(RedmineExtensions::BasePresenter)
        presenter = model.update_options(options.merge(view_context: self))
      else
        presenter = RedmineExtensions::BasePresenter.present(model, self, options)
      end
      if block_given?
        yield presenter
      else
        presenter
      end
    end

    # --- COMMON RENDERING ----

    # hide elements for issues and users
    def detect_hide_elements(uniq_id, user = nil, default = true)
      return ''.html_safe if uniq_id.blank?
      return 'style="display:none"'.html_safe if !toggle_button_expanded?(uniq_id, user, default)
    end

    def url_to_entity(entity, options={})
      m = "url_to_#{entity.class.name.underscore}".to_sym
      if respond_to?(m)
        send(m, entity, options)
      else
        nil
      end
    end

    def query_for_entity(entity_class)
      entity_class_name = entity_class.name
      query_class = "Easy#{entity_class_name}Query".constantize rescue nil
      return query_class if query_class && query_class < EasyQuery
      query_class ||= "#{entity_class_name}Query".constantize rescue nil
    end

    def render_entity_assignments(entity, target_entity, options = {}, &block)
      options ||= {}
      collection_name = options.delete(:collection_name) || target_entity.name.pluralize.underscore
      query_class = query_for_entity(target_entity)

      return '' if !query_class || !entity.respond_to?(collection_name)

      project = options.delete(:project)

      query = query_class.new(:name => 'c_query')
      query.project = project
      query.set_entity_scope(entity, collection_name)
      query.column_names = options[:query_column_names] unless options[:query_column_names].blank?

      entities = query.entities

      entities_count = entities.size
      options[:entities_count] = entities_count
      options[:module_name] ||= "entity_#{entity.class.name.underscore}_#{entity.id}_#{collection_name}"
      options[:heading] ||= l("label_#{query.entity}_plural", :default => 'Heading')

      if options[:context_menus_path].nil?
        options[:context_menus_path] = [
          "context_menu_#{collection_name}_path".to_sym,
          "context_menus_#{collection_name}_path".to_sym,
          "#{collection_name}_context_menu_path".to_sym
        ].detect do |m|
          m if respond_to?(m)
        end
      end

      query.output = options[:display_style] || (entities_count > 3 ? 'list' : 'tile')

      render(:partial => 'easy_entity_assignments/assignments_container', :locals => {
        :entity => entity,
        :query => query, :project => project,
        :entities => entities, :entities_count => entities_count, :options => options})
    end

    def entity_css_icon(entity_or_entity_class)
      return '' if entity_or_entity_class.nil?

      if entity_or_entity_class.is_a?(Class) && entity_or_entity_class.respond_to?(:css_icon)
        entity_or_entity_class.css_icon
      elsif entity_or_entity_class.is_a?(ActiveRecord::Base)
        if entity_or_entity_class.respond_to?(:css_icon)
          entity_or_entity_class.css_icon
        elsif entity_or_entity_class.class.respond_to?(:css_icon)
          entity_or_entity_class.class.css_icon
        else
          "icon icon-#{entity_or_entity_class.class.name.dasherize}"
        end
      else
        "icon icon-#{entity_or_entity_class.class.name.dasherize}"
      end
    end


    # ==== Options
    # * <tt>class: Hash or String</tt> - This option can be used to add custom CSS classes. It can be *String* or *Hash*.
    #       class: {heading: 'heading-additional-css', container: 'container-additional-css'}
    # * <tt>heading_tag: name of HTML element of module heading</tt> - By default its its *h3*
    # ** Aliases for this options are: wrapping_heading_element, header_tag
    # * <tt>toggle: false</tt> - This disable toggle function (collapsible and remember)
    # ** Aliases for this options are: collapsible, no_expander
    # * <tt>remember: false</tt> - This disable remember function of toggle container
    # ** Aliases for this options are: ajax_call
    #
    def render_module_easy_box(id, heading, options = {}, &block) # with fallback to old
      options[:toggle] = true unless options.key?(:toggle)
      options[:remember] = options.delete(:ajax_call) if options.key?(:ajax_call)
      options[:collapsible] = !options.delete(:no_expander) if options.key?(:no_expander)

      renderer = EasyBoxRenderer.new(self, id, heading, options)
      renderer.content = capture {yield renderer}

      renderer.render
    end

    EasyBoxRenderer = Struct.new(:view, :id, :heading, :options) do

      attr_writer :container_class, :heading_class, :content_class
      attr_writer :heading_links, :footer, :icon
      attr_accessor :content

      def container_class
        s = (@container_class.presence || css_classes[:container]).to_s
        s << ' collapsible' if collapsible?
        s << ' collapsed' if collapsed?

        s
      end

      def saving_state_enabled?
        collapsible? && (options[:remember].nil? || !!options[:remember])
      end

      def heading_tag
        (options[:wrapping_heading_element] || (options[:header_tag] || options[:heading_tag])).presence || 'h3'
      end

      def heading_class
        (@heading_class || css_classes[:heading]).to_s
      end

      def icon
        @icon ||= options[:icon] && " icon #{options[:icon]}"
      end

      def heading_links
        if block_given?
          @heading_links = view.capture { yield }
        else
          @heading_links.to_s.html_safe
        end
      end

      def collapsible?
        return @collapsible unless @collapsible.nil?
        @collapsible ||= !!options[:toggle] && (options[:collapsible].nil? || !!options[:collapsible])
      end

      def collapsed?
        !!options[:default] || !!options[:collapsed] || !!options[:default_button_state]
      end

      def footer
        if block_given?
          @footer = view.capture { yield }
        else
          @footer.to_s.html_safe
        end
      end

      def render
        view.render({partial: 'common/collapsible_module_layout', locals: {renderer: self, content: content}} )
      end
      private

      def css_classes
        return @css_classes if @css_classes
        if (css_class = options.delete(:class)).is_a?(Hash)
          @css_classes = css_class
        else
          @css_classes = {
              container: css_class,
              heading: css_class,
              content: css_class
          }
        end
      end

    end


    def autocomplete_field_tag(name, jsonpath_or_array, selected_values, options = {})
      options.reverse_merge!({select_first_value: false, show_toggle_button: false, load_immediately: false})
      options[:id] ||= sanitize_to_id(name)

      selected_values ||= []

      if jsonpath_or_array.is_a?(Array)
        source = jsonpath_or_array.to_json
      else
        source = "'#{jsonpath_or_array}'"
      end

      content_tag(:span, :class => 'easy-multiselect-tag-container') do
        text_field_tag('', '', (options[:html_options] || {}).merge(id: options[:id])) +
          javascript_tag("$('##{options[:id]}').easymultiselect({multiple: true, rootElement: #{options[:rootElement].to_json}, inputName: '#{name}', preload: true, source: #{source}, selected: #{selected_values.to_json}, show_toggle_button: #{options[:show_toggle_button]}, select_first_value: #{options[:select_first_value]}, load_immediately: #{options[:load_immediately]}, autocomplete_options: #{(options[:jquery_auto_complete_options]||{}).to_json} });")
      end
    end

  end
end
