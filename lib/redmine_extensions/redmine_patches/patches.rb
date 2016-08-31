require 'active_support/dependencies'
patch_path = File.join(File.dirname(__FILE__), '**', '*_patch.rb')
Dir.glob(patch_path).each do |file|
  require_dependency file
end
