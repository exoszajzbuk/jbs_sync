  module ActiveRecord
    module Synchronizable
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      def getModelName
        self.class.to_s
      end

      # synchronization table handling
      def update_synchronization_record_update
        syncObj = Synchronization.where(:model_name => getModelName, :method_name => "update").first

        if (! syncObj.nil?)
          syncObj.touch
          syncObj.save
        else
          Synchronization.create!(:model_name => getModelName, :method_name => "update")
        end
      end

      def update_synchronization_record_delete
        syncObj = Synchronization.where(:model_name => getModelName, :method_name => "delete").first

        if (! syncObj.nil?)
          syncObj.touch
          syncObj.save
        else
          Synchronization.create!(:model_name => getModelName, :method_name => "delete")
        end
      end
            
      def as_json(options=nil)
        unless (self.class.json_attrs?.nil?)
          {
            self.class.name.underscore.to_sym => Hash[self.class.json_attrs?.map{|j| [j[0],send(j[1])]}]
          }
        else
          { self.class.name.underscore.to_sym => attributes }
        end
      end

      module ClassMethods
        def synchronizable(options = {})
          @synchronizable = true
          
          unless self.eql? Synchronization
            # trigger
            after_save :update_synchronization_record_update
            before_destroy :update_synchronization_record_delete
          end
          
          # heritage function fixes for heirs
          if self.respond_to? "_predecessor_klass"
            has_one _predecessor_klass.name.underscore.to_sym, :foreign_key => "heir_id", :conditions => ["heir_type = ?", self.name.to_s]
            
            #id
            define_method(_predecessor_klass.name.underscore+"_id") do
              predecessor.send("id")
            end
            
            #heir_id
            define_method(_predecessor_klass.name.underscore+"_heir_id") do
              predecessor.send("heir_id")
            end
            
            #heir_type
            define_method(_predecessor_klass.name.underscore+"_heir_type") do
              predecessor.send("heir_type")
            end
            
          end
        end
      
        def synchronizable?
          if (@synchronizable == true) then
            true
          else
            false
          end
        end
        
        def json_attrs(options)
          tmp = options[:fields].map{ |f| [f.to_s, f.to_s] }
          unless options[:mappings].nil?
            options[:mappings].each{|k,v| tmp[tmp.index([k.to_s,k.to_s])][0]=v.to_s}
            @attrs = tmp
          else
            @attrs = tmp
          end
        end
        
        def json_attrs?
          @attrs
        end
      end
    end
  end