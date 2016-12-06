#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

begin
  require 'rdoc/task'

  desc "Generate documentation for the plugin."
  Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_dir = "rdoc"
    rdoc.title = "RedmineExtensions #{RedmineExtensions::VERSION}"
    rdoc.rdoc_files.include("README*")
    rdoc.rdoc_files.include("lib/**/*.rb")
  end
rescue LoadError
  puts 'RDocTask is not supported for this platform'
end

APP_RAKEFILE = File.expand_path("../spec/redmine/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'

# load 'rails/tasks/statistics.rake'

Bundler::GemHelper.install_tasks

Dir[File.join(File.dirname(__FILE__), 'tasks/**/*.rake')].each {|f| load f }

require 'rspec/core'
require 'rspec/core/rake_task'

desc "Run all specs in spec directory (excluding plugin specs)"

task :generate_test_plugin do
  require RedmineExtensions::Engine.root.join('spec', 'support', 'plugin_generator').to_s
  PluginGenerator.generate_test_plugin!
end
RSpec::Core::RakeTask.new(spec: [:generate_test_plugin, 'app:redmine:plugins:migrate']) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.exclude_pattern = 'spec/redmine/**/*_spec.rb'
end

# task :redmine_test do |rake|
#   Rake::Task['app:test'].invoke
# end

task :default => :spec
