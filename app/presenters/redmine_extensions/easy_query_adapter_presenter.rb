module RedmineExtensions
  class EasyQueryAdapterPresenter < BasePresenter

    # --- GETTERS ---
    attr_accessor :loading_group, :page_module, :row_limit, :export_formats

    # should be defined in parent in future
    def initialize(query, view_context=nil, options={})
      super(query, view_context, options)
      @query = query

      @page_module = options[:page_module]

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

    # ----- RENDERING HELPERS ----

    def default_name
      h.l(self.class.name.underscore, :scope => [:easy_query, :name])
    end

    def name
      @name ||= options[:easy_query_name] || (model.new_record? ? default_name : model.name)
    end

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
