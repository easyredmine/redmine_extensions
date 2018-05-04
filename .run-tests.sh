#!/bin/bash -l
# -v print lines as they are read
# -x print lines as they are executed
# -e abort script at first error
set -e

# Init database
ruby -ryaml -rsecurerandom -e "
  database = 'redmine_'+SecureRandom.hex(8).to_s
  config = {
    'adapter' => ENV['ADAPTER'],
    'database' => database,
    'host' => '127.0.0.1',
    'username' => ENV['DB_USERNAME'],
    'password' => ENV['DB_PWD'],
    'encoding' => 'utf8'
  }
  config = {
    'test' => config.merge({'database' => 'test_'+database}),
    'development' => config,
    'production' => config
  }.to_yaml
  File.write(ENV['REDMINE_SUBDIR'] + '/config/database.yml', config)
"

function before_exit {
  return_value=$?
  bundle exec rake db:drop
  exit $return_value
}

trap before_exit SIGHUP SIGINT SIGTERM EXIT

if [ "$EASY" = "true" ]; then
  cd $REDMINE_SUBDIR
  find plugins/* -maxdepth 0 -type d ! -name 'easyproject' ! -name 'easy_job' ! -name 'easysoftware' -exec rm -rf {} +
  find plugins/easyproject/easy_plugins/* -maxdepth 0 -type d ! -name 'easy_extensions' -exec rm -rf {} +
  bundle update
  bundle exec rake db:drop db:create db:migrate
  bundle exec rake easyproject:install RAILS_ENV=production
  bundle exec rake test:prepare RAILS_ENV=test
  bundle exec rake easyproject:tests:spec$TAGS RAILS_ENV=test JS_DRIVER=chrome CHROME_OPTIONS="headless no-sandbox disable-gpu window-size=1920,1080"
elif [ "$ONLY_SPEC" = "true" ]; then
  bundle update
  bundle exec rake db:drop db:create db:migrate RAILS_ENV=test
  bundle exec rake spec RAILS_ENV=test
else
  cd $REDMINE_SUBDIR
  bundle update
  bundle exec rake db:drop db:create db:migrate
  bundle exec rake test:prepare RAILS_ENV=test
  bundle exec rake test RAILS_ENV=test
fi


