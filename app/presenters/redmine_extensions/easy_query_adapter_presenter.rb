module RedmineExtensions
  class EasyQueryAdapterPresenter < BasePresenter

    # --- GETTERS ---
    attr_accessor :loading_group, :page_module, :row_limit, :export_formats

    # should be defined in parent in future
    def initialize(query, view_context=nil, options={})
      super(query, view_context, options)
      @query = query

      @page_module = options[:page_module]

      @export_formats = ActiveSupport::OrderedHash.new
      @export_formats[:csv] = {}
      @export_formats[:pdf] = {}
      @export_formats[:xlsx] = {}
    end

    def entities(options={})
      #can not fetch, cuz gantt is fetching enstead of nil
      @entities ||= @options[:entities] || h.instance_variable_get(:@entities) #|| model.entities(options)
    end

    def entity_count(options={})
      @entity_count ||= h.instance_variable_get(:@entity_count) || model.entity_count(options)
    end

    def entity_pages
      @options[:entity_pages] || h.instance_variable_get(:@entity_pages)
    end

    def available_outputs
      outputs.available_outputs
    end

    def outputs
      @outputs ||= RedmineExtensions::EasyQueryHelpers::Outputs.new(self)
    end

    def display_save_button
      true
    end


    # ----- RENDERING HELPERS ----

    def default_name
      h.l(self.class.name.underscore, :scope => [:easy_query, :name])
    end

    def name
      @name ||= options[:easy_query_name] || (model.new_record? ? default_name : model.name)
    end

    def groups_url
      options[:groups_url] || h.params
    end

    def show_free_search?
      options.key?(:show_free_search) ? options[:show_free_search] : options[:page_module].nil? && model.searchable_columns.any?
    end

    def render_exports?
      outputs.table?
    end

    def display_columns_select?(action='edit')
      true
    end
    def display_sort_options?(action='edit')
      action == 'edit' ? true : false
    end
    def display_group_by_select?(action='edit')
      true
    end
    def display_settings?(action)
      true
    end
    def has_default_filter?
      model.filters == model.default_filter
    end

    def render_zoom_links?
      false
    end

    def to_model
      self
    end

    def model_name
      EasyQuery.model_name
    end

    def to_partial_path
      'easy_queries/easy_query'
    end

    def block_name
      options[:block_name] || ( page_module ? page_module.page_zone_module.module_name : nil )
    end
    def modul_uniq_id
      options[:modul_uniq_id] || ''
    end

    def render_zoom_links
      return unless render_zoom_links?
      # TODO: it should give a presenter itself to the partial and there decide what and how to render
      if self.page_module
        h.render(:partial => 'easy_queries/zoom_links', :locals => {:query => self, :base_url => {}, :block_name => self.page_module.page_zone_module.module_name})
      else
        h.render(:partial => 'easy_queries/zoom_links', :locals => {:query => self})
      end
    end

    def prepare_table_render
      #prepared for a period settings before render
    end

    def entity_list(entities=self.entities)
      if model.entity.class.respond_to?(:each_with_easy_level)
        model.entity.class.each_with_easy_level(entities) do |entity, level|
          yield entity, level
        end
      else
        entities.each do |entity|
          yield entity, nil
        end
      end
    end

    def self.entity_css_classes(entity, options={})
      entity.css_classes if entity.respond_to?(:css_classes)
    end
    def entity_css_classes(entity, options={})
      self.class.entity_css_classes(entity, options)
    end

    def has_context_menu?
      (options[:options] && options[:options].has_key?(:hascontextmenu)) ? options[:options][:hascontextmenu] : false
    end

    def modal_selector?
      (options[:options] && options[:options].has_key?(:modal_selector)) ? options[:options][:hascontextmenu] : false
    end

    # Returns a additional fast-icons buttons
    # - entity - instance of ...
    # - query - easy_query
    # - options - :no_link => true - no html links will be rendered
    #
    def additional_beginning_buttons(entity, options={})
      return ''.html_safe if model.nil? || entity.nil?
      easy_query_additional_buttons_method = "#{model.class.name.underscore}_additional_beginning_buttons".to_sym

      additional_buttons = ''
      if h.respond_to?(easy_query_additional_buttons_method)
        additional_buttons = h.send(easy_query_additional_buttons_method, entity, options)
      end

      return additional_buttons.html_safe
    end

    def additional_ending_buttons(entity, options={})
      return ''.html_safe if model.nil? || entity.nil?
      easy_query_additional_buttons_method = "#{model.class.name.underscore}_additional_ending_buttons".to_sym

      additional_buttons = ''
      if h.respond_to?(easy_query_additional_buttons_method)
        additional_buttons = h.send(easy_query_additional_buttons_method, entity, options)
      end

      return additional_buttons.html_safe
    end


    def column_header(column, options={})
      if !options[:disable_sort] && column.sortable
        if page_module
          h.easy_page_module_sort_header_tag(page_module, model, column.name.to_s, {:class => column.css_classes, :caption => column.caption, :default_order => column.default_order})
        else
          h.sort_header_tag(column.name.to_s, {:class => column.css_classes, :caption => column.caption, :default_order => column.default_order})
        end
      else
        h.content_tag(:th, column.caption, {:class => column.css_classes})
      end
    end

    def operators_for_select(filter_type)
      EasyQueryFilter.operators_by_filter_type[filter_type].collect { |o| [l(EasyQueryFilter.operators[o]), o] }
    end

    def other_formats_links(options={})
      if options[:no_container]
        yield RedmineExtensions::Export::EasyOtherFormatsBuilder.new(h)
      else
        h.concat('<div class="other-formats">'.html_safe)
        yield RedmineExtensions::Export::EasyOtherFormatsBuilder.new(h)
        h.concat('</div>'.html_safe)
      end
    end


    def available_columns_for_select
      h.options_for_select (model.available_columns - model.columns).reject(&:frozen?).collect {|column| [column.caption(true), column.name]}
    end

    def selected_columns_for_select
      h.options_for_select (model.columns & model.available_columns).reject(&:frozen?).collect {|column| [column.caption(true), column.name]}
    end

    #------- DATA FOR RESULTS -------

    # Returns count of entities on the list action
    # returns groups_count if query is grouped and entity_count otherwise
    def entity_count_for_list(options={})
      if model.grouped?
        return model.groups_count(options)
      else
        return model.entity_count(options)
      end
    end

    def entities_for_html(options={})
      options[:limit] ||= row_limit
      return model.entities_for_group(loading_group, options) if loading_group

      if model.grouped?
        return model.groups(options)
      else
        return model.entities(options)
      end
    end
    alias_method :prepare_html_result, :entities_for_html

    def entities_for_export(options={})
      if model.grouped?
        return model.groups(options.merge(:include_entities => true))
      else
        return {nil => {:entities => model.entities(options), :sums => model.send(:summarize_entities, entities)}}
      end
    end
    alias_method :prepare_export_result, :entities_for_export

    def filters_active?
      model.filters.any?
    end

    #------ MIDDLE LAYER ------

    # Returns count of entities on the list action
    # returns groups_count if query is grouped and entity_count otherwise
    def entity_count_for_list(options={})
      if self.grouped?
        model.groups_count(options)
      else
        model.entity_count(options)
      end
    end

    def path(params={})
      if self.new_record?
        entity_easy_query_path(self.to_params.merge(params))
      else
        entity_easy_query_path({:query_id => model}.merge(params))
      end
    end

    def entity_easy_query_path(options = {})
      options = options.dup

      h.polymorphic_path([(options.delete(:project) || self.project), self.entity], options)
    end
  end
end
