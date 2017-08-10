module RedmineExtensions
  class Hooks < Redmine::Hook::ViewListener
    @visited = false
    def easy_extensions_blocking_javascripts_hook(context={})
      if defined?(EasyExtensions)
        @visited = true
        context[:template].require_asset('redmine_extensions/blocking')
      end
    end

    def easy_extensions_javascripts_hook(context={})
      if defined?(EasyExtensions)
        context[:template].require_asset('redmine_extensions/blocking') unless @visited
        context[:template].require_asset('redmine_extensions/application')
        # context[:hook_caller].javascript_include_tag('redmine_extensions/application')
      end
    end

    def view_layouts_base_html_head(context={})
      unless defined?(EasyExtensions)
        javascript_include_tag('redmine_extensions/blocking_polyfill') +
        javascript_include_tag('redmine_extensions/blocking_schedule') +
        javascript_include_tag('redmine_extensions/blocking_module') +
        javascript_include_tag('redmine_extensions/jquery.entityarray') +
        javascript_include_tag('redmine_extensions/redmine_extensions') +
        javascript_include_tag('redmine_extensions/easy_togglers')
      end
    end
  end
end
