module RedmineExtensions
  module EasyQueryHelpers
    # ----- OUTPUTS HELPER CLASS ----
    class Outputs
      include Enumerable

      def initialize(presenter)
        @presenter = presenter
        @query = @presenter.model
      end

      def outputs
        @outputs ||= enabled_outputs.map{|o| RedmineExtensions::QueryOutput.output_klass_for(o).new(@presenter) }.sort{|a,b| a.order <=> b.order}
      end

      def each(style = :enabled, &block)
        if style == :enabled
          outputs.each(&block)
        else
          available_output_instances.each(&block)
        end
      end

      def enabled_outputs
        res = @query.outputs.map{|o| o == 'table' ? 'list' : o}
        res << 'list' if res.empty? && available_outputs.empty?
        res
      end

      def available_output_names
        @available_output_names ||= RedmineExtensions::QueryOutput.available_outputs_for( @query )
      end

      def available_outputs
        @available_outputs ||= RedmineExtensions::QueryOutput.available_output_klasses_for( @query ).map{|klass| klass.new(@presenter) }
      end

      def output_enabled?(output)
        enabled_outputs.include?(output.to_s)
      end

      def render_edit_selects(style=:check_box, options={})
        available_output_instances.map{|o| o.render_edit_box(style, options) }.join('').html_safe
      end

      def render_edit
        outputs.map{ |output| output.render_edit }.join('').html_safe
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
