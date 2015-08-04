module RedmineExtensions
  class QueryOutput

    unloadable # or it loose registered outputs, do the registering either on reload by standart, or solve it better

    attr_accessor :query

    def self.register_output(name, klass, options={})
      registered_outputs[name] = klass
    end

    def self.registered_outputs
      @registered_outputs ||= {}
    end

    def self.available_outputs_for(query)
      registered_outputs.select do |name, output|
        output.available_for?(query)
      end.keys
    end

    def self.output_klass_for(output)
      registered_outputs[output.to_sym]
    end


    # Take query and decide if it is possible to render it by this output
    def self.available_for?(query)
      true
    end

    def initialize(query_presenter, view_context, options={})
      @query, @view, @options = query_presenter, view_context, options
    end

    def render_data;
      raise NotImplemented
    end

    def variables
      @options.merge(easy_query: @query, output: self)
    end

    def h
      @view
    end

  end
end
# alias for convinience
EasyQueryOutput = RedmineExtensions::QueryOutput
