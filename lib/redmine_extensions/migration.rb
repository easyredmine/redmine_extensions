module RedmineExtensions
  if Rails.version.start_with?('5')
    class Migration < ActiveRecord::Migration[4.2]
    end
  else
    class Migration < ActiveRecord::Migration
    end
  end
end