module RedmineExtensions
  class QueryOutput

    attr_accessor :query
    delegate :options, to: :query

    def self.register(klass, options={})
      registered_outputs[klass.key.to_sym] = klass
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

    def self.key
      self.name.split('::').last.sub(/Output$/, '').underscore
    end

    def key
      self.class.key
    end

    def label
      view.l('label_easy_query_output.'+key)
    end

    def enabled?
      query.outputs.output_enabled?(key)
    end

    def variables
      options.merge(query: @query, output: self, entities: @query.entities)
    end

    def header
      content = options["#{key}_header".to_sym]
      view.content_tag(:h3, content.html_safe) unless content.blank?
    end

    def render_data
      view.render partial: "easy_queries/outputs/#{key}", locals: variables
    end


    def render_edit_box(style=:check_box, options={})
      raise 'Style of edit box is not allowed' unless [:check_box, :radio_button].include?(style)

      box_id = "#{options[:modul_uniq_id]}_output_#{key}"

      options[:class] ||= "#{options[:modul_uniq_id]}content_switch"
      r = ''
      r << view.send("#{style}_tag" , "#{options[:block_name]}[output]", key, enabled?, id: box_id, class: options[:class])
      r << view.label_tag(box_id, view.l('label_easy_query_output.' + key), :class => 'inline')
      r
    end

    def render_edit
      view.content_tag(:fieldset, class: "easy-query-filters-field #{key}_settings", style: ('display: none;' unless enabled? )) do
        view.content_tag(:legend, label) +
        view.render(self.edit_form, query: query, modul_uniq_id: query.modul_uniq_id, action: 'edit')
      end
    end

    def edit_form
      'easy_queries/form_'+key+'_settings'
    end

    def view
      @query.view
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
# alias for convinience
EasyQueryOutput = RedmineExtensions::QueryOutput
