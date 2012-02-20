class Synchronization < ActiveRecord::Base

  synchronizable
  json_attrs :fields => [:id, :model_name, :method_name, :updated_at]
  
  acts_as_indexed :fields => [:model_name, :method_name]
  #validates :model_name, :presence => true, :uniqueness => true
  
end
