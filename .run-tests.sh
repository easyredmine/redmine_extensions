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
  File.write('config/database.yml', config)
"

bundle install
bundle exec rake db:drop
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake app:redmine:plugins:migrate
bundle exec rake app:easyproject:tests:spec
bundle exec rake spec
bundle exec rake db:drop
