module RedmineExtensions
  module RenderingHelper
    def hiearchy_for_ar(model)
      klass = model.class
      hiearchy = []
      while true
        hiearchy << klass.name
        break if klass == klass.base_class
        klass = klass.superclass
      end
      hiearchy
    end

    def render_with_fallback(*attrs)
      raise 'Missing an options argument' unless attrs.last.is_a?(Hash)
      options = attrs.last
      raise 'Missing an fallback prefixes' unless options[:prefixes]
      partial = options[:partial] || attrs.first
      prefixes = options.delete(:prefixes)

      prefixes = prefixes.model if prefixes.is_a?(BasePresenter)
      prefixes = hiearchy_for_ar(prefixes).map{|klass| klass.underscore.pluralize } if prefixes.is_a?(ActiveRecord::Base)

      prefixes.each do |prefix|
        if lookup_context.template_exists?(partial, prefix, true)
          partial.prepend("#{prefix}/")
          return render(*attrs)
        end
      end
      partial.prepend("#{prefixes.last}/")
      render(*attrs)
    end
  end
end
