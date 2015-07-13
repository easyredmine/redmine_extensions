class CreateEasySettings < ActiveRecord::Migration
  def up
    unless table_exists?(:easy_setting)
      create_table :easy_settings do |t|
        t.string :name
        t.text :value
        t.references :project, index: true, foreign_key: true
      end
    end

    unless index_exists?(:easy_setting, [:name, :project_id], unique: true)
      add_index :easy_settings, [:name, :project_id], unique: true
    end

  end

  def down
    drop_table :easy_settings
  end
end
