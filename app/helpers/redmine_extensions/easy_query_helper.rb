module RedmineExtensions
  module EasyQueryHelper

    def options_for_filters(query)
      filters = query.filters_for_select
      grouped_options = ActiveSupport::OrderedHash.new { |hash, key| hash[key] = Array.new }
      query_default_group_name = l("label_filter_group_#{query.class.name.underscore}")
      grouped_options[query_default_group_name]

      if query.entity == Issue
        grouped_options[l(:field_issue) + ' ' + l(:label_filter_group_custom_fields_suffix)]
        grouped_options[l(:label_filter_group_relations)]
      end

      filters.each do |field|
        group = field[1][:group] || l(:label_filter_group_unknown)
        def_lang_key = field[0].to_s.gsub(/_id$/, '')
        grouped_options[group] << [field[1][:name] || l(('field_' + def_lang_key).to_sym), field[0].gsub(/\./, '_')] if !query.has_filter?(field[0])
      end

      grouped_options.delete_if{|key, value| value.blank?}

      # copied grouped_options_for_select ( due to ordering... )
      body = ''

      grouped_options.each do |group|
        body << content_tag(:optgroup, options_for_select(group[1]), :label => group[0])
      end

      body.html_safe
    end

    def easy_render_format_options_dialog(query, format, params)
      @easy_format_options_dialog_rendered ||= []
      return if @easy_format_options_dialog_rendered.include?(format)
      @easy_format_options_dialog_rendered << format
      render(:partial => 'easy_queries/format_options_dialog', :locals => {:query => query, :params => params, :format => format})
    end

  end
end
