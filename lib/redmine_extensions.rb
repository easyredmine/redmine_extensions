require "redmine_extensions/engine"
require 'redmine_extensions/core_ext'

module RedmineExtensions

  def self.load_easy_plugins
    Redmine::Plugin.all.each do |plugin|
      #TODO: maybe some condition for easy_plugins only...
      queries_dir = File.join(plugin.directory, 'app', 'models', 'easy_queries')
      if File.directory?( queries_dir )
        ActiveSupport::Dependencies.autoload_paths += [queries_dir]
      end
    end
  end

end
