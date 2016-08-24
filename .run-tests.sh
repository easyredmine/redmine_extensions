#!/bin/bash -l
# -v print lines as they are read
# -x print lines as they are executed
# -e abort script at first error
set -e

echo $(pwd)
echo $GITLAB_CI
echo $CI_SERVER
echo $CI_SERVER_NAME
echo $CI_SERVER_VERSION
echo $CI_SERVER_REVISION
echo $CI_BUILD_REF
echo $CI_BUILD_TAG
echo $CI_BUILD_NAME
echo $CI_BUILD_STAGE
echo $CI_BUILD_REF_NAME
echo $CI_BUILD_ID
echo $CI_BUILD_REPO
echo $CI_BUILD_TRIGGERED
echo $CI_PROJECT_ID
echo $CI_PROJECT_DIR
echo $REDMINE_SUBDIR

bundle --version

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
  config = { 'test' => config.merge({'database' => 'test_'+database}), 'development' => config }.to_yaml
  File.write(ENV['REDMINE_SUBDIR'] + '/config/database.yml', config)
"

bundle update
bundle exec rake db:drop db:create db:migrate RAILS_ENV=test
cd $REDMINE_SUBDIR
if [ "$EASY" = "true" ]; then
  bundle exec rake easyproject:install
  bundle exec rake easyproject:tests:spec
else
  bundle exec rake test
fi
cd ../..
bundle exec rake spec
bundle exec rake db:drop
