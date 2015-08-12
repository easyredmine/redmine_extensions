module RedmineExtensions
  class EasyQueryPresenter < BasePresenter

    # --- GETTERS ---
    attr_accessor :loading_group

    def entities(options={})
      @entities ||= h.instance_variable_get(:@entities) || model.entities(options)
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
      @outputs ||= Outputs.new(self, h, @options)
    end

    def render_exports?
      outputs.table?
    end

    def to_partial_path
      'easy_queries/easy_query'
    end

    # ----- RENDERING HELPERS ----

    def render_zoom_links
      return unless @model.period_columns? || @model.grouped_by_date_column? || @model.chart_grouped_by_date_column?
      # TODO: it should give a presenter itself to the partial and there decide what and how to render
      if self.easy_page_module
        h.render(:partial => 'easy_queries/zoom_links', :locals => {:query => self, :base_url => {}, :block_name => self.easy_page_module.page_zone_module.module_name})
      else
        h.render(:partial => 'easy_queries/zoom_links', :locals => {:query => self})
      end
    end

    def prepare_table_render
      #prepared for a period settings before render
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

      def initialize(presenter, view_context, options={})
        @presenter = presenter
        @query = presenter.model
        @outputs = @query.outputs.map{|o| RedmineExtensions::QueryOutput.output_klass_for(o).new(presenter, view_context, options) }
      end

      def each(&block)
        @outputs.each{|o| yield(o) }
      end

      def available_outputs
        QueryOutput.available_outputs_for( @query )
      end

      def output_enabled?(output)
        @query.outputs.include?(output.to_s)
      end

      def method_missing(name, *args)
        if name.to_s.ends_with?('?')
          output_enabled?(name.to_s[0..-1])
        else
          super
        end
      end
    end
  end
end
