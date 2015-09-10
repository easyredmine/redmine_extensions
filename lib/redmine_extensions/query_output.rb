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
      result
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

    def label
      h.l('label_easy_query_output.'+key)
    end

    def enabled?
      query.outputs.output_enabled?(key)
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

      box_id = "#{options[:modul_uniq_id]}_output_#{key}"

      options[:class] ||= "#{options[:modul_uniq_id]}content_switch"
      r = ''
      r << h.send("#{style}_tag" , "#{options[:block_name]}[output]", key, enabled?, id: box_id, class: options[:class])
      r << h.label_tag(box_id, h.l('label_easy_query_output.' + key), :class => 'inline')
      r
    end

    def render_edit
      h.content_tag(:fieldset, class: "easy-query-filters-field #{key}_settings", style: ('display: none;' unless enabled? )) do
        h.content_tag(:legend, label) +
        h.render(self.edit_form, query: query, modul_uniq_id: query.modul_uniq_id, action: 'edit')
      end
    end

    def edit_form
      'easy_queries/form_'+key+'_settings'
    end

    def h
      @query.h
    end

  end
end
# alias for convinience
EasyQueryOutput = RedmineExtensions::QueryOutput
