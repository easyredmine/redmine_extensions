module RedmineExtensions
  class EasyQueryPresenter < BasePresenter

    # --- GETTERS ---

    def entities
      @entities ||= h.instance_variable_get(:@entities) || model.entities
    end

    def entity_count
      h.instance_variable_get(:@entity_count)
    end
    def entity_pages
      h.instance_variable_get(:@entity_pages)
    end

    def available_outputs
      outputs.available_outputs
    end

    def outputs
      @outputs ||= Outputs.new(self, h, @options)
    end

    def render_exports?
      outputs.table?
    end

    # ----- RENDERING HELPERS ----

    def render_zoom_links
      return unless @model.period_columns? || @model.grouped_by_date_column? || @model.chart_grouped_by_date_column?
      # TODO: it should give a presenter itself to the partial and there decide what and how to render
      if self.easy_page_module
        h.render(:partial => 'easy_queries/zoom_links', :locals => {:query => self, :base_url => {}, :block_name => self.easy_page_module.page_zone_module.module_name})
      else
        h.render(:partial => 'easy_queries/zoom_links', :locals => {:query => self})
      end
    end


    # ----- OUTPUTS HELPER CLASS ----
    class Outputs
      include Enumerable

      def initialize(presenter, view_context, options={})
        @presenter = presenter
        @query = presenter.model
        @outputs = @query.outputs.map{|o| QueryOutput.output_klass_for(o).new(presenter, view_context, options) }
      end

      def each(&block)
        @outputs.each{|o| yield(o) }
      end

      def available_outputs
        QueryOutput.available_outputs_for( @query )
      end

      def output_enabled?(output)
        @query.outputs.include?(output.to_s)
      end

      def method_missing(name, *args)
        if name.to_s.ends_with?('?')
          output_enabled?(name.to_s[0..-1])
        else
          super
        end
      end
    end
  end
end
