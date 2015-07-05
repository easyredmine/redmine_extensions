$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "redmine_extensions/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "redmine_extensions"
  s.version     = RedmineExtensions::VERSION
  s.authors     = ["EasySoftware, ltd"]
  s.email       = ["ondrej.ezr@easy.cz"]
  s.homepage    = "http://www.easyredmine.com"
  s.summary     = "RedmineExtensions is set of usefull features for Redmine. Main focus is on development helpers, but many users can find it helpfull"
  s.description = "RedmineExtensions provide many extended functionalities for Redmine project."
  s.license     = 'GPL-2'

  s.test_files = Dir["spec/**/*"]

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2.1"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_girl_rails'
end
