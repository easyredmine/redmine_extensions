class EasyProjectQuery < EasyQuery

  def entity
    Project
  end

  attributes_options :id, :easy_baseline_for_id, reject: true

end

begin
  require_dependency Rails.root.join('plugins', 'easyproject', 'easy_plugins', 'easy_extensions', 'app', 'models', 'easy_queries', 'easy_project_query')
rescue LoadError
  Rails.logger.warn 'EasyRedmine is not installed, please visit a www.easyredmine.com for feature preview and consider installation.'
end
