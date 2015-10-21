module RedmineExtensions
  module Export
    class EasyOtherFormatsBuilder
      def initialize(view)
        @view = view
      end

      # Creates a link tag of the given +name+ using for named format.
      # +query+ parameters follow +name+
      # last parameter +options+ contains *caption* or +url+ *Hash*

      # +name+, +query+, +options+
      def link_to(name, *args)
        options = args.extract_options!
        format = name.to_s.downcase
        query = args.shift
        url = options.delete(:url) || {}
        url.stringify_keys!

        params = @view.params.except('page', 'controller', 'action').merge(:format => format)
        if query && url.blank?
          url = query.path(params)
        else
          url = params.merge(url)
        end
        caption = options.delete(:caption) || name
        html_options = { :class => format, :rel => 'nofollow' }.merge(options)
        @view.content_tag('span', @view.link_to(caption, url, html_options))
      end
    end
  end
end
