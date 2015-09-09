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

    def self.available_output_klasses_for(query)
      result = []
      registered_outputs.each do |name, output|
        result << output if output.available_for?(query)
      end
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

    def render_edit_box(style=:check_box, options={})
      raise 'Style of edit box is not allowed' unless [:check_box, :radio_button].include?(style)

      options[:class] ||= options[:modul_uniq_id] + 'content_switch'
      h.send("#{style}_tag" , "#{block_name}[output]", key, query.outputs.output_enabled?(key), id: options[:modul_uniq_id] + '_output_' + key, class: options[:class])
      h.label_tag options[:modul_uniq_id] + '_output_' + key, h.l('label_my_page_issue_output.' + key), :class => 'inline'
    end

    def h
      @query.h
    end

  end
end
# alias for convinience
EasyQueryOutput = RedmineExtensions::QueryOutput
