class RemoveForeignKeyFromEasySettings < RedmineExtensions::Migration
  def up
    begin
      remove_foreign_key :easy_settings, :projects
    rescue # rails 5 - if foreign_key_exists? :easy_settings, :projects
    end
  end

  def down
  end
end
