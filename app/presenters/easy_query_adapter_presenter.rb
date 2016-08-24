class EasyQueryAdapterPresenter < RedmineExtensions::BasePresenter

  # --- GETTERS ---
  attr_accessor :page_module, :row_limit

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
    outputs.available_output_names
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

end
