class AddModelUpdatedAtToSynchronizations < ActiveRecord::Migration
  def self.up
    add_column :synchronizations, :model_updated_at, :datetime
  end

  def self.down
    remove_column :synchronizations, :model_updated_at
  end
end
