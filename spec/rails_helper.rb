# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require File.expand_path("../redmine/config/environment.rb",  __FILE__)
# Add additional requires below this line. Rails is not loaded until this point!
require 'rspec/rails'
require 'factory_bot_rails'
require 'database_cleaner'

  Rails.backtrace_cleaner.remove_silencers!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

# warning supress for ruby 2.0 and new capybara see https://gist.github.com/ericboehs/7125105
class WarningSuppressor
  IGNORES = [
    /QFont::setPixelSize: Pixel size <= 0/,
    /CoreText performance note:/,
    /Heya! This page is using wysihtml5/,
    /You must provide a success callback to the Chooser to see the files that the user selects/
  ]

  class << self
    def write(message)
      if suppress?(message) then 0 else puts(message);1;end
    end

    private
      def suppress?(message)
        IGNORES.any? { |re| message =~ re }
      end
  end
end

require 'capybara/poltergeist'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    inspector: 'google-chrome-stable',
    js_errors: true,
    timeout: 1.hour.seconds.to_i,
    phantomjs_options: ['--ignore-ssl-errors=yes'],
    phantomjs_logger: WarningSuppressor
  })
end

Capybara.register_driver :chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    'chromeOptions' => {
      'args' => ENV['CHROME_OPTIONS'].to_s.split(' ')
    }
  )

  Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.javascript_driver = ENV['JS_DRIVER'].present? ? ENV['JS_DRIVER'].downcase.to_sym : :poltergeist

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
    RequestStore.clear! # invalidates cache
  end

  config.before(:each, clear_cache: true) do
    Rails.cache.clear
  end



  config.after(:each) do
    DatabaseCleaner.clean
  end
end
