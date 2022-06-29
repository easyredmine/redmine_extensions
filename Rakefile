require 'bundler/setup'

possible_app_dirs = [
  ENV['DUMMY_PATH'],
  File.join(Dir.pwd, 'test/dummy')
]
dir = possible_app_dirs.compact.first

if !File.directory?(dir)
  abort("Directory '#{dir}' does not exists")
end

APP_RAKEFILE = File.expand_path(File.join(dir, 'Rakefile'), __dir__)
load 'rails/tasks/engine.rake'
load 'rails/tasks/statistics.rake'

Bundler::GemHelper.install_tasks

namespace :redmine_extensions do
  task :generate_test_plugin do
    require_relative 'spec/init_rails'
    require RedmineExtensions::Engine.root.join('spec', 'support', 'plugin_generator').to_s
    PluginGenerator.generate_test_plugin!
  end
end
