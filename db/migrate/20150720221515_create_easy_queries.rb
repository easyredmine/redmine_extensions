class CreateEasyQueries < ActiveRecord::Migration
  def up
    if table_exists?(:easy_queries)
      add_column :easy_queries, :settings, :text unless column_exists?(:easy_queries, :settings)
      unless column_exists?(:easy_queries, :visibility)
        add_column :easy_queries, :visibility, :integer, :default => 0
        EasyQuery.where(:is_public => true).update_all(:visibility => 2)
        remove_column :easy_queries, :is_public
      end
      add_column :easy_queries, :is_for_subprojects, :boolean unless column_exists?(:easy_queries, :is_for_subprojects)

      add_column :easy_queries, :outputs, :text, null: true, default: ['table'].to_yaml unless column_exists?(:easy_queries, :outputs)
      remove_column :easy_queries, :table if column_exists?(:easy_queries, :table)
      remove_column :easy_queries, :chart if column_exists?(:easy_queries, :chart)
      remove_column :easy_queries, :calendar if column_exists?(:easy_queries, :calendar)

      add_column :easy_queries, :chart_settings, :text, null: true unless column_exists?(:easy_queries, :chart_settings)
      add_column :easy_queries, :period_settings, :text, null: true unless column_exists?(:easy_queries, :period_settings)

    else
      create_table :easy_queries do |t|
        t.string  :type

        t.references :project, foreign_key: true
        t.references :user, index: true, foreign_key: true
        t.string  :name,          default: '',    null: false
        t.text    :filters
        t.integer :visibility,    default: 0
        t.text    :column_names
        t.text    :sort_criteria
        t.string  :group_by

        t.text :outputs,          null: true
        t.text :settings
        t.text :chart_settings,   null: true
        t.text :period_settings,  null: true

        t.timestamps null: false
      end
    end

    adapter_name = EasyQuery.connection_config[:adapter]
    case adapter_name.downcase
    when 'mysql', 'mysql2'
      change_column :easy_queries, :filters, :text, {:limit => 4294967295, :default => nil}
      change_column :easy_queries, :column_names, :text, {:limit => 4294967295, :default => nil}
      change_column :easy_queries, :sort_criteria, :text, {:limit => 4294967295, :default => nil}
      change_column :easy_queries, :settings, :text, {:limit => 4294967295, :default => nil}
      change_column :easy_queries, :chart_settings, :text, {:limit => 4294967295, :default => nil}
      change_column :easy_queries, :period_settings, :text, {:limit => 4294967295, :default => nil}
    end
  end

  def down
    drop_table :easy_queries
  end
end
