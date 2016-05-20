class EasyEntityAssignment < ActiveRecord::Base

  belongs_to :entity_from, :polymorphic => true
  belongs_to :entity_to, :polymorphic => true

end
