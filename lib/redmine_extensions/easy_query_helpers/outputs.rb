module RedmineExtensions
  module EasyQueryHelpers
    # ----- OUTPUTS HELPER CLASS ----
    class Outputs
      include Enumerable

      def initialize(presenter, view_context = nil)
        if presenter.is_a?(RedmineExtensions::BasePresenter)
          @presenter = presenter
          @query = @presenter.model
        else
          @presenter = @query = presenter
        end
        @view_context = view_context
      end

      def view_context
        @view_context || @presenter.h
      end

      def outputs
        @outputs ||= enabled_outputs.map{|o| RedmineExtensions::QueryOutput.output_klass_for(o, @query).new(@presenter, self) }.sort_by{|a| a.order}
      end

      def each(style = :enabled, &block)
        if style == :enabled
          outputs.each(&block)
        else
          available_outputs.each(&block)
        end
      end

      def enabled_outputs
        available = available_output_names.map(&:to_s)
        res = if available.one?
          available
        else
          Array(@query.outputs).map(&:to_s) & available
        end
        res << 'list' if res.empty?
        res
      end

      def available_output_names
        @available_output_names ||= RedmineExtensions::QueryOutput.available_outputs_for( @query )
      end

      def available_outputs
        @available_outputs ||= RedmineExtensions::QueryOutput.available_output_klasses_for( @query ).map{|klass| klass.new(@presenter, self) }
      end

      def output_enabled?(output)
        enabled_outputs.include?(output.to_s)
      end

      def render_edit_selects(style=:check_box, options={})
        options.delete(:enabled)
        if available_outputs.count == 1
          available_outputs.first.render_edit_box(:hidden_field, options)
        else
          h.content_tag(:p) do
            s = h.content_tag(:label, h.l(:label_easy_query_outputs))
            available_outputs.each do |o|
              s << o.render_edit_box(style, options.dup)
            end
            s
          end
        end
      end

      def render_edit
        outputs.map{ |output| output.render_edit }.join('').html_safe
      end

      def render_data
        if outputs.any?
          outputs.map{ |output| output.render_data }.join('').html_safe
        else
          view_context.l(:label_no_output)
        end
      end

      def h
        view_context
      end

      def method_missing(name, *args)
        if name.to_s.ends_with?('?')
          output_enabled?(name.to_s[0..-2])
        else
          super
        end
      end
    end

  end #EasyQueryHelpers
end #RedmineExtensions
