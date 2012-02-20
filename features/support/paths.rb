module NavigationHelpers
  module Refinery
    module Synchronizations
      def path_to(page_name)
        case page_name
        when /the list of synchronizations/
          admin_synchronizations_path

         when /the new synchronization form/
          new_admin_synchronization_path
        else
          nil
        end
      end
    end
  end
end
