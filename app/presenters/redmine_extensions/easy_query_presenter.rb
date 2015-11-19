module RedmineExtensions
  class EasyQueryPresenter < BasePresenter

    # --- GETTERS ---
    attr_accessor :loading_group, :page_module, :row_limit, :export_formats

    def initialize(*attrs)
      super
      @export_formats = ActiveSupport::OrderedHash.new
      @export_formats[:csv] = {}
      @export_formats[:pdf] = {}
      @export_formats[:xlsx] = {}
    end

    def entities(options={})
      @entities ||= @options[:entities] || h.instance_variable_get(:@entities) || model.entities(options)
    end

    def entity_count(options={})
      @entity_count ||= h.instance_variable_get(:@entity_count) || model.entity_count(options)
    end
    def entity_pages
      h.instance_variable_get(:@entity_pages)
    end

    def available_outputs
      outputs.available_outputs
    end

    def outputs
      @outputs ||= Outputs.new(self)
    end

    def display_save_button
      true
    end


    # ----- RENDERING HELPERS ----

    def default_name
      h.l(self.class.name.underscore, :scope => [:easy_query, :name])
    end

    def name
      model.new_record? ? default_name : model.name
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
      true
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

    def entity_css_classes(entity, options={})
      entity.css_classes if entity.respond_to?(:css_classes)
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


    # Get values from Proc, select only valid filters, sort and cache list of filters. Return array of arrays
    def filters_for_select
      @filters_for_select ||= model.available_filters.select do |name, filter|
        filter.valid?
      end.sort { |a, b| a[1] <=> b[1] }

      return @filters_for_select
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


    # ----- SERIALIZATION HELPERS ------

    def from_params(params)
      return if params.nil?

      if params['set_filter'] == '1'
        model.filters = {}
        model.group_by = ''
      else
        model.filters = model.default_filter
        model.group_by = model.default_group_by
      end

      if params['fields'] && params['fields'].is_a?(Array)
        params['values'] ||= {}

        params['fields'].each do |field|
          model.add_filter(field, params['operators'][field], params['values'][field])
        end
      else
        model.available_filters.keys.each do |field|
          model.add_short_filter(field, params[field]) if params[field]
        end
      end

      model.group_by = params['group_by'] if params['group_by'].present?
      model.show_sum_row = params['show_sum_row'].try(:to_boolean) if params['show_sum_row'].present?
      model.load_groups_opened = params['load_groups_opened'].try(:to_boolean) if params['load_groups_opened'].present?

      self.outputs_from_params(params)

      if params['easy_query'] && params['easy_query']['columns_to_export'] == 'all'
        model.column_names = available_columns.collect { |col| col.name.to_s }
      elsif params['column_names'] && params['column_names'].is_a?(Array)
        if params['column_names'].first && params['column_names'].first.include?(',')
          model.column_names = params['column_names'].first.split(',')
        else
          model.column_names = params['column_names']
        end
      end

      if params['settings'] && params['settings'].is_a?(Hash)
        if model.settings.is_a?(Hash)
          model.settings.merge!(params['settings'])
        else
          model.settings = params['settings'].dup
        end
      end

      self.set_additional_params(params)

      model.sort_criteria = params['sort_criteria'] if params['sort_criteria']

      @sort_helper = SortHelper::SortCriteria.new

      if params['sort'].present?
        @sort_helper.available_criteria = sortable_columns
        @sort_helper.from_param(params['sort'])
        @sort_helper.criteria = model.sort_criteria_init if @sort_helper.empty?
        model.sort_criteria = @sort_helper.to_a
      end

      if params['easy_query_q']
        model.use_free_search = true
        model.free_search_question = params['easy_query_q']
        model.free_search_question.strip!

        # extract tokens from the question
        # eg. hello "bye bye" => ["hello", "bye bye"]
        model.free_search_tokens = model.free_search_question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect { |m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '') }
        # tokens must be at least 2 characters long
        model.free_search_tokens = model.free_search_tokens.uniq.select { |w| w.length > 1 }
        model.free_search_tokens.slice! 5..-1 if model.free_search_tokens.size > 5
      end
    end

    def outputs_from_params(params)
      if params['outputs'].is_a?(Array)
        model.outputs = params['outputs'] & available_outputs.collect(&:to_s)
      else
        model.outputs = available_outputs.select do |output|
          if params[output.to_s].present?
            true
          elsif !params['output'].blank?
            params['output'] == output
          end
        end
      end
      model.outputs = ['table'] if model.outputs.empty?
    end

    def set_additional_params(params)
    end

    def to_params
      easy_query_params = {:set_filter => '1', :type => model.class.name, :fields => [], :operators => {}, :values => {}}

      model.filters.each do |f, o|
        easy_query_params[:fields] << f
        easy_query_params[:operators][f] = o[:operator]
        easy_query_params[:values][f] = o[:values]
      end

      easy_query_params[:group_by] = model.group_by
      easy_query_params[:column_names] = (model.column_names || []).collect(&:to_s)
      easy_query_params[:load_groups_opened] = model.load_groups_opened ? '1' : '0'
      easy_query_params[:show_sum_row] = model.show_sum_row ? '1' : '0'
      easy_query_params[:show_avatars] = model.show_avatars ? '1' : '0'
      easy_query_params
    end


    # ----- OUTPUTS HELPER CLASS ----
    class Outputs
      include Enumerable

      def initialize(presenter)
        @presenter = presenter
        @query = presenter.model
        @query.outputs = ['table'] unless @query.outputs.any?
        @outputs = @query.outputs.map{|o| RedmineExtensions::QueryOutput.output_klass_for(o).new(presenter) }
      end

      def each(&block)
        @outputs.each{|o| yield(o) }
      end

      def available_outputs
        RedmineExtensions::QueryOutput.available_outputs_for( @query )
      end

      def available_output_instances
        @available_outputs ||= RedmineExtensions::QueryOutput.available_output_klasses_for( @query ).map{|klass| klass.new(@presenter) }
      end

      def output_enabled?(output)
        @query.outputs.include?(output.to_s)
      end

      def render_edit_selects(style=:check_box, options={})
        available_output_instances.map{|o| o.render_edit_box(style, options) }.join('').html_safe
      end

      def render_edit
        @outputs.map{ |output| output.render_edit }.join('').html_safe
      end

      def method_missing(name, *args)
        if name.to_s.ends_with?('?')
          output_enabled?(name.to_s[0..-2])
        else
          super
        end
      end
    end
  end
end
