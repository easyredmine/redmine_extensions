source 'https://rubygems.org'

# Possible directories for dummy application
possible_app_dirs = [
  ENV['DUMMY_PATH'],
  File.join(Dir.pwd, 'test/dummy'),
  Bundler.root.join('test/dummy'),
]

# Find first gemfile on the possible directories
# Keep it at the end of the file (because of abort on the bottom)
gems_rb_found = false
gems_rb = ['Gemfile', 'gems.rb']
possible_app_dirs.each do |dir|
  break if gems_rb_found
  next if !dir
  next if !Dir.exist?(dir)

  gems_rb.each do |gems_rb|
    gems_rb = File.expand_path(File.join(dir, gems_rb))

    if File.exist?(gems_rb)
      eval_gemfile(gems_rb)
      gems_rb_found = true
      break
    end
  end
end

if !gems_rb_found
  abort("Dummy application's gemfile not found")
end

# Current gem specification file
gemspec_file = Dir.glob(File.join(__dir__, '*.gemspec')).first

# Not valid gem
if gemspec_file.nil? || !File.exist?(gemspec_file)
  abort('Gemspec not found')
end

# Dummy application may already include this gem
# You cannot specify the same gem twice
current_gem_spec = Bundler.load_gemspec(gemspec_file)
@dependencies.delete_if {|d| d.name == current_gem_spec.name }

# Load current gem and its dependencies
gemspec
