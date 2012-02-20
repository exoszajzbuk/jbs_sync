class CreateSynchronizations < ActiveRecord::Migration

  def self.up
    create_table :synchronizations do |t|
      t.string :model_name
      t.string :method_name
      t.integer :position

      t.timestamps
    end

    add_index :synchronizations, :id

    load(Rails.root.join('db', 'seeds', 'synchronizations.rb'))
  end

  def self.down
    if defined?(UserPlugin)
      UserPlugin.destroy_all({:name => "synchronizations"})
    end

    if defined?(Page)
      Page.delete_all({:link_url => "/synchronizations"})
    end

    drop_table :synchronizations
  end

end
