module RedmineExtensions
  class Hooks < Redmine::Hook::ViewListener

    if defined?(EasyExtensions)
      if EasyExtensions.try(:deferred_js)

        ### DEFERRED JAVASCRIPTS ###
        def easy_extensions_blocking_javascripts_hook(context={})
          context[:template].require_asset('redmine_extensions/blocking')
        end

        def easy_extensions_javascripts_hook(context={})
          context[:template].require_asset('redmine_extensions/application')
        end
      else
        ### JAVASCRIPTS IN HEADER ###
        def easy_extensions_javascripts_hook(context={})
          context[:template].require_asset('redmine_extensions/blocking')
          context[:template].require_asset('redmine_extensions/application')
        end
      end
    else
      ### JAVASCRIPTS IN REDMINE ###
      def view_layouts_base_html_head(context={})
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
