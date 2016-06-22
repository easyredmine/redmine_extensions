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

    # options:
    # => options[:heading] = text beside of plus button
    # => options[:container_html] = a hash of html attributes
    # => options[:default_button_state] = (true => expanded -), (false => collapsed +)
    # => options[:ajax_call] = make ajax call for saving state (true => ajax call, false => no call, no save)
    # => options[:wrapping_heading_element] = html element outside heading => h3, h4
    def render_toggler(container_uniq_id, user = nil, options={}, &block)
      user ||= User.current
      options[:heading] ||= ''
      options[:heading_links] ||= []
      options[:heading_links] = [options[:heading_links]] if options[:heading_links] && !options[:heading_links].is_a?(Array)
      options[:container_html] ||= {}
      options[:default_button_state] = false #if is_mobile_device?
      options[:default_button_state] = true if options[:default_button_state].nil?
      options[:ajax_call] = true if options[:ajax_call].nil?

      s = ''
      if !options.key?(:no_heading_button)
        options[:heading] << content_tag(:div, options[:heading_links].join(' ').html_safe, :class => 'module-heading-links') unless options[:heading_links].blank?
        s << render_toggler_header(user, options[:heading].html_safe, container_uniq_id, options)
      end

      if options[:ajax_call] == false
        expanded = options[:default_button_state]
      else
        expanded = true
      end

      s << (content_tag(:div, {
        :id => container_uniq_id,
        :style => (expanded ? '' : 'display:none')
      }.merge(options[:container_html]) { |k, o, n| "#{o}; #{n}" }, &block))
      s.html_safe
    end

    def render_toggler_header(user, content, modul_uniq_id, options={})
      expander_options = options[:expander_options] || {}
      wrapping_heading_element = options[:wrapping_heading_element] || 'h3'
      wrapping_heading_element_classes = (options[:wrapping_heading_element_classes] || '') + ' module-heading'
      wrapping_heading_element_styles = options[:wrapping_heading_element_styles]
      ajax_call = options.delete(:ajax_call) ? 'true' : 'false'

      html = ''

      if options[:no_expander]
        html << content_tag(wrapping_heading_element, content, :class => wrapping_heading_element_classes, :style => wrapping_heading_element_styles)
      else
        html << '<div class="module-toggle-button">'
        html << "<div class='group open' >"
        html << content_tag(wrapping_heading_element, content, :class => wrapping_heading_element_classes, :style => wrapping_heading_element_styles, :onclick => "var event = arguments[0] || window.event; if( !$(event.target).hasClass('do_not_toggle') && !$(event.target).parent().hasClass('module-heading-links') ) toggleMyPageModule(this,'#{modul_uniq_id}','#{user.id}', #{ajax_call})")
        html << "<span class='expander #{expander_options[:class]}' onclick=\"toggleMyPageModule($(this),'#{modul_uniq_id}','#{user.id}', #{ajax_call}); return false;\" id=\"expander_#{modul_uniq_id}\">&nbsp;</span>"
        html << '</div></div>'
      end

      html.html_safe
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
          javascript_tag("$('##{options[:id]}').easymultiselect({multiple: true, rootElement: #{options[:rootElement]}, inputName: '#{name}', preload: true, source: #{source}, selected: #{selected_values.to_json}, show_toggle_button: #{options[:show_toggle_button]}, select_first_value: #{options[:select_first_value]}, load_immediately: #{options[:load_immediately]}, autocomplete_options: #{(options[:jquery_auto_complete_options]||{}).to_json} });")
      end
    end

  end
end
