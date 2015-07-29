class CreateEasyQueriesRoles < ActiveRecord::Migration
  def up
    unless table_exists?(:easy_queries_roles)
      create_table :easy_queries_roles, :id => false do |t|
        t.column :easy_query_id, :integer, :null => false
        t.column :role_id, :integer, :null => false
      end
      add_index :easy_queries_roles, [:easy_query_id, :role_id], :unique => true, :name => :easy_queries_roles_ids
    end
  end

  def down
    drop_table :easy_queries_roles
  end
end
