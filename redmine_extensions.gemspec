$:.push File.expand_path("../lib", __FILE__)

require "redmine_extensions/version"

Gem::Specification.new do |spec|
  spec.name        = "redmine_extensions"
  spec.version     = RedmineExtensions::VERSION
  spec.authors     = ["Easy Software Ltd"]
  spec.email       = ["info@easyredmine.com"]
  spec.homepage    = "https://www.easyredmine.com"
  spec.summary     = "Redmine Extensions is set of usefull features for Redmine. Main focus is on development helpers, but many users can find it helpfull"
  spec.description = "Redmine Extensions provide many extended functionalities for Redmine project."
  spec.license     = 'GPL-2'

  spec.test_files = Dir["spec/**/*"]

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.rdoc"]

  spec.add_dependency "rails", "~> 4.2.1"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'capybara'
  spec.add_development_dependency 'factory_girl_rails'
  spec.add_development_dependency 'database_cleaner'
end
