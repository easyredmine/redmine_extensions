source 'https://rubygems.org'

# Declare your gem's dependencies in redmine_extensions.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

stored = []
stored << @dependencies.find { |d| d.name == 'redmine_extensions' }
stored << @dependencies.find { |d| d.name == 'factory_girl_rails' }
stored.compact!
stored.each{|dep| @dependencies.delete dep }

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]
group :development, :test do
  gem 'pry-rails'
  Dir.glob File.expand_path("../spec/redmine/Gemfile", __FILE__) do |file|
    eval_gemfile file
  end
end

@dependencies.delete @dependencies.find { |d| d.name == 'redmine_extensions' }
@dependencies.delete @dependencies.find { |d| d.name == 'factory_girl_rails' }
@dependencies.concat(stored)
