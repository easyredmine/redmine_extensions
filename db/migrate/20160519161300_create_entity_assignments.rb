class CreateEntityAssignments < RedmineExtensions::Migration
  def self.up
    unless table_exists?(:easy_entity_assignments)
      create_table :easy_entity_assignments do |t|
        t.references :entity_from, :polymorphic => true
        t.references :entity_to, :polymorphic => true
        t.timestamps
      end

      add_index :easy_entity_assignments, [:entity_from_type, :entity_from_id, :entity_to_type, :entity_to_id], :name => 'entity_assignment_idx', :unique => true
      add_index :easy_entity_assignments, :entity_from_id, :name => 'entity_assignment_idx_from'
      add_index :easy_entity_assignments, :entity_to_id, :name => 'entity_assignment_idx_to'
    end
  end

  def self.down
    drop_table :easy_entity_assignments
  end
end
