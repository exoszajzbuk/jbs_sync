class SynchronizationsController < ApplicationController

  before_filter :find_all_synchronizations
  before_filter :find_page
  
  before_filter :check_model, :only => [:update_all, :delete_all]

  def index
    # you can use meta fields from your model instead (e.g. browser_title)
    # by swapping @page for @synchronization in the line below:
    present(@page)
  end

  def show
    @synchronization = Synchronization.find(params[:id])

    # you can use meta fields from your model instead (e.g. browser_title)
    # by swapping @page for @synchronization in the line below:
    present(@page)
  end
  
  # ------------------------------
  # custom synchronization methods
  
  # update sync a whole model
  def update_all
    if params[:updated_at].nil? then
      @records = @model.all
    else
      @records = @model.find(:all, :conditions => ['updated_at > ?', Time.parse(params[:updated_at])+1])
    end
      
    respond_with_records @records
  end
  
  # delete sync a whole model
  def delete_all
    @records = @model.all.collect{ |m| m.id }
    
    respond_with_records @records
  end
  
  # down sync one record
  #def update_single
  #  @record = @model.find(params[:id])
  #  respond_to do |format|
  #    format.html { render :text => t('format_error') }
  #    format.json { render :json => @record }
  #    format.xml { render :xml => @record }
  #  end
  #end

protected

  def find_all_synchronizations
    @synchronizations = Synchronization.order('position ASC')
  end

  def find_page
    @page = Page.where(:link_url => "/synchronizations").first
  end

  def check_model
    @model = params[:model_name].singularize.camelize.constantize
    
    unless (@model.synchronizable?) then
      render :text => t('not_synchronizable')
    end
  end
  
  def respond_with_records(records)
    respond_to do |format|
      #format.html { render :text => t('format_error') }
      format.json { render :json => records }
      format.xml { render :xml => records }
    end
  end

end
