module RedmineExtensions
  if Rails::VERSION::MAJOR >= 5
    class Migration < ActiveRecord::Migration[4.2]
    end
  else
    class Migration < ActiveRecord::Migration
    end
  end
end