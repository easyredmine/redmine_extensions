class CreateRedmineExtensionsEasySettings < ActiveRecord::Migration
  def change
    create_table :redmine_extensions_easy_settings do |t|
      t.string :name
      t.text :value
      t.references :project, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
