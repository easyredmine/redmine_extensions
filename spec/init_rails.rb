possible_app_dirs = [
  ENV['DUMMY_PATH'],
  File.join(Dir.pwd, 'test/dummy'),
  Bundler.root.join('test/dummy'),
]

possible_app_dirs.each do |dir|
  next if !dir
  next if !Dir.exist?(dir)

  require File.join(dir, 'plugins/easyproject/easy_plugins/easy_extensions/test/spec/rails_helper')
  break
end
