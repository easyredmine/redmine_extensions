module RedmineExtensions
  module RenderingHelper

    def render_with_fallback(*attrs)
      raise 'Missing an options argument' unless attrs.last.is_a?(Hash)
      options = attrs.last
      raise 'Missing an fallback prefixes' unless options[:prefixes]
      partial = options[:partial] || attrs.first
      prefixes = options.delete(:prefixes)

      prefixes = prefixes.model if prefixes.is_a?(BasePresenter)
      prefixes = prefixes.hiearchy.map{|klass| klass.underscore.pluralize } if prefixes.is_a?(ActiveRecord::Base)

      prefixes.each do |prefix|
        if lookup_context.template_exists?(partial, prefix, true)
          partial.prepend("#{prefix}/")
          return render(*attrs)
        end
      end
      partial.prepend("#{prefixes.last}/")
      render(*attrs)
    end

    def query_outputs(presenter_or_query, options={})
      presenter = present(presenter_or_query, options) rescue RedmineExtensions::BasePresenter.new(presenter_or_query, self, options)
      RedmineExtensions::EasyQueryHelpers::Outputs.new(presenter, self)
    end
  end
end
