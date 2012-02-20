require 'rails'

  class Railtie < Rails::Railtie
    
    initializer 'refinerycms-synchronizations' do |app|
      
      ActiveSupport.on_load(:active_record) do
        require 'refinerycms-synchronizations/active_record/synchronizable'
        ::ActiveRecord::Base.send(:include, ActiveRecord::Synchronizable)
      end
      
    end
    
  end
