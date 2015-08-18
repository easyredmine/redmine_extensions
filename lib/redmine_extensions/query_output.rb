module RedmineExtensions
  class QueryOutput

    attr_accessor :query
    delegate :options, to: :query

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

    def initialize(query_presenter)
      @query = query_presenter
    end

    def render_data;
      raise NotImplemented
    end

    def key
      self.class.name.split('::').last.sub(/Output$/, '').underscore
    end

    def variables
      options.merge(easy_query: @query, output: self)
    end

    def header
      content = options["#{key}_header".to_sym]
      h.content_tag(:h3, content.html_safe) unless content.blank?
    end

    def h
      @query.h
    end

  end
end
# alias for convinience
EasyQueryOutput = RedmineExtensions::QueryOutput
