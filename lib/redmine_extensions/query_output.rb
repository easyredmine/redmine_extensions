module RedmineExtensions
  class QueryOutput

    attr_accessor :query
    delegate :options, to: :query

    def self.registered_outputs
      @@registered_outputs ||= {}
    end

    def self.registered_per_query
      @@registered_per_query ||= {}
    end

    def self.registered_whitelists
      @@registered_whitelists ||= {}
    end

    def self.register_output(klass, options={})
      register_as = (options[:as] || klass.key).to_sym
      registered_outputs[register_as] = klass
    end

    def self.register_output_for_query(klass, query_class_names, **options)
      register_as ||= (options[:as] || klass.key).to_sym
      Array.wrap(query_class_names).each do |query_class_name|
        registered_per_query[query_class_name] ||= {}
        registered_per_query[query_class_name][register_as] = klass
      end
    end

    def self.whitelist_outputs_for_query(query_class_names, outputs)
      Array.wrap(query_class_names).each do |query_class_name|
        registered_whitelists[query_class_name] ||= []
        registered_whitelists[query_class_name].concat( Array.wrap(outputs).map(&:to_s) ).uniq!
      end
    end

    def self.filter_registered_for(query, whitelist = [])
      whitelist += (registered_whitelists[query.type] || [])
      res = registered_outputs
      res = res.slice(*whitelist.map(&:to_sym)) if whitelist.any?
      res = res.select do |_name, output|
        output.available_for?(query)
      end
      res.merge(registered_per_query[query.type] || {})
    end

    def self.output_available?(query, output)
      self.filter_registered_for(query, [output]).any?
    end

    def self.available_outputs_for(query)
      filter_registered_for(query).keys
    end

    def self.available_output_klasses_for(query)
      filter_registered_for(query).values
    end

    def self.output_klass_for(output, query=nil)
      filtered = query.nil? ? registered_outputs : filter_registered_for(query)
      filtered[output.to_sym]
    end

    def self.key
      self.name.split('::').last.sub(/Output$/, '').underscore
    end


    # Take query and decide if it is possible to render it by this output
    def self.available_for?(query)
      query.is_a? Query
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
      box_id = "#{query.modul_uniq_id}output_#{key}"

      options[:class] = "#{options[:class]} #{query.modul_uniq_id}output_switch #{query.modul_uniq_id}content_switch"
      options[:enabled] = enabled? unless options.key?(:enabled)

      r = ''
      case style
      when :hidden_field
        r << h.hidden_field_tag(query.block_name.blank? ? 'outputs[]' : "#{query.block_name}[outputs][]", key, id: box_id, class: options[:class])
      when :check_box, :radio_button
        r << h.send("#{style}_tag" , query.block_name.blank? ? 'outputs[]' : "#{query.block_name}[outputs][]", key, options[:enabled], id: box_id, class: options[:class])
        r << h.label_tag(box_id, h.l('label_my_page_issue_output.' + key), :class => 'inline')
      else
        raise 'Style of edit box is not allowed'
      end
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
