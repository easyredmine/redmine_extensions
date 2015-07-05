module EasyCKEditor

  def self.syntaxt_higlight_default_template
    @syntaxt_higlight_default_template ||= 'github'
  end

  def self.syntaxt_higlight_templates
    @syntaxt_higlight_templates ||= ['github', 'googlecode', 'idea', 'monokai', 'monokai_sublime', 'railscasts']
  end

  def self.syntaxt_higlight_template
    EasySetting.value('ckeditor_syntax_highlight_theme') || syntaxt_higlight_default_template
  end

  def self.syntaxt_higlight_css
    "/plugin_assets/ckeditor/javascripts/ckeditor/plugins/codesnippet/lib/highlight/styles/#{syntaxt_higlight_template}"
  end

  def self.syntaxt_higlight_js
    @syntaxt_higlight_js ||= "/plugin_assets/ckeditor/javascripts/ckeditor/plugins/codesnippet/lib/highlight/highlight.pack.js"
  end

end
