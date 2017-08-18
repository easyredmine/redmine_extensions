class CreateEasySettings < RedmineExtensions::Migration
  def up
    if table_exists?(:easy_settings)
      add_column(:easy_settings, :type, :string, null: true) unless column_exists?(:easy_settings, :type)
    else
      create_table :easy_settings do |t|
        t.string :type
        t.string :name
        t.text :value
        t.references :project, index: true, foreign_key: true
      end
    end

    unless index_exists?(:easy_settings, [:name, :project_id], unique: true)
      add_index :easy_settings, [:name, :project_id], unique: true
    end

  end

  def down
    drop_table :easy_settings
  end
end
