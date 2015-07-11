class CreateRedmineExtensionsEasySettings < ActiveRecord::Migration
  def up
    if table_exists?(:easy_setting)
      rename_table :easy_setting, :redmine_extensions_easy_settings
    else
      create_table :redmine_extensions_easy_settings do |t|
        t.string :name
        t.text :value
        t.references :project, index: true, foreign_key: true

        t.timestamps null: false
      end
    end
  end

  def down
    drop_table :redmine_extensions_easy_settings
  end
end
