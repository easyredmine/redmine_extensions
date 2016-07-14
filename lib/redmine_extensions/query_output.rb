module RedmineExtensions
  class QueryOutput

    attr_accessor :query
    delegate :options, to: :query

    def self.register_output(klass, options={})
      register_as = (options[:as] || klass.key).to_sym
      registered_outputs[register_as] = klass
    end

    def self.registered_outputs
      @@registered_outputs ||= {}
    end

    def self.available_outputs_for(query)
      registered_outputs.select do |name, output|
        output.available_for?(query)
      end.keys
    end

    def self.available_output_klasses_for(query)
      registered_outputs.select do |name, output|
        output.available_for?(query)
      end.values
    end

    def self.output_klass_for(output)
      registered_outputs[output.to_sym]
    end

    def self.key
      self.name.split('::').last.sub(/Output$/, '').underscore
    end


    # Take query and decide if it is possible to render it by this output
    def self.available_for?(query)
      query.class > Query
    end

    def initialize(query_presenter, outputs=nil)
      @query = query_presenter
      @outputs = outputs || query_presenter.outputs
    end

    def data_partial
      'easy_queries/easy_query_'+key
    end

    def order
      10
    end

    def render_data
      h.render partial: data_partial, locals: variables
    end

    def key
      self.class.key
    end

    def label
      h.l('label_easy_query_output.'+key, default: key.humanize)
    end

    def enabled?
      @outputs.output_enabled?(key)
    end

    def variables
      options.reverse_merge(query: @query, output: self)
    end

    def header
      content = options["#{key}_header".to_sym]
      h.content_tag(:h3, content.html_safe) unless content.blank?
    end

    def render_edit_box(style=:check_box, options={})
      raise 'Style of edit box is not allowed' unless [:check_box, :radio_button].include?(style)

      box_id = "#{query.modul_uniq_id}output_#{key}"


      options[:class] = "#{options[:class]} #{query.modul_uniq_id}output_switch #{query.modul_uniq_id}content_switch"
      options[:enabled] = enabled? unless options.key?(:enabled)
      r = ''
      r << h.send("#{style}_tag" , query.block_name.blank? ? 'outputs[]' : "#{query.block_name}[outputs][]", key, options[:enabled], id: box_id, class: options[:class])
      r << h.label_tag(box_id, h.l('label_my_page_issue_output.' + key), :class => 'inline')
      r.html_safe
    end

    def render_edit(action='edit')
      h.content_tag(:fieldset, class: "easy-query-filters-field #{key}_settings", style: ('display: none;' unless enabled? )) do
        h.content_tag(:legend, label) + render_edit_form(action)
      end
    end

    def render_edit_form(action='edit')
      h.render(self.edit_form, options.reverse_merge(query: query, modul_uniq_id: query.modul_uniq_id, block_name: query.block_name, action: action, page_module: query.page_module))
    end

    def edit_form
      'easy_queries/form_'+key+'_settings'
    end

    def h
      @outputs.view_context
    end

  end
end
# alias for convinience
# EasyQueryOutput = RedmineExtensions::QueryOutput
