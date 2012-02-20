module Admin
  class SynchronizationsController < Admin::BaseController

    crudify :synchronization,
            :title_attribute => 'model_name', :xhr_paging => true, :order => "method_name DESC, updated_at DESC"

  end
end
