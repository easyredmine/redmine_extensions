module RedmineExtensions
  module ApplicationHelper

    def url_for(options=nil)
      if options.is_a?(Hash)
        main_app.url_for(options)
      else
        super
      end
    end

    def method_missing(method, *args, &block)
      if (method.to_s.end_with?('_path') || method.to_s.end_with?('_url')) && main_app.respond_to?(method)
        main_app.send(method, *args)
      else
        super
      end
    end

  end
end
