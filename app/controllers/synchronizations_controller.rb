require 'rack/oauth2'
class SynchronizationsController < ApplicationController
  class Unauthorized < StandardError; end

  rescue_from ::BadRequest, :with => :bad_request
  rescue_from ::RecordConflict, :with => :record_conflict
  rescue_from ::Forbidden, :with => :forbidden

  before_filter :find_all_synchronizations
  before_filter :find_page
  
  before_filter :check_model, :only => [:update_all, :delete_all, :update_one, :create_record, :update_record]

  def forbidden(ex)
      Rails.logger.info "Forbidden: " + ex.why
      error_str = { :error => ex.why }
      render :json => error_str, :status => 403
  end

  def bad_request
      Rails.logger.info "Bad request exception got"
      error_str = { :error => "Bad request" }
      render :json => error_str, :status => 400
  end
  
  def record_conflict(ex)
      Rails.logger.info "Record is in conflict with: " + ex.record_in_conflict.as_json
      render :json => ex.record_in_conflict, :status => 409
  end

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

  def signup
    @user = User.new
    @referral_id = params[:referral_id]
    Rails.logger.info "Referral ID: " + params[:referral_id]
  end
  
  # ------------------------------
  # login methods
  
  def testlogin
    return unless auth_with_user == true

    render :json => @user
  end

  def auth_with_user
    # authenticate
    Rails.logger.info "Authenticating ..."
    if defined? params[:fb_identifier] and !params[:fb_identifier].nil? and defined? params[:fb_auth_token] and !params[:fb_auth_token].nil? then
      Rails.logger.info "Authenticating with facebook credentials: id: " + params[:fb_identifier] + ", auth token: " + params[:fb_auth_token]
      fb_user = FbGraph::User.new(params[:fb_identifier], :access_token => params[:fb_auth_token]).fetch

      # Facebook object is saved here
      fbObj = Facebook.identify(fb_user) 
      raise Unauthorized unless fbObj
    
      # If the user exists for that Facebook account search for it else create a new one
      @user = User.find_by_facebook_id(fbObj.id)
      if not @user.nil? then
        Rails.logger.info "User is already registered"
        true
      else
        @user = User.find_by_email(fb_user.email)
        unless @user.nil? then
          Rails.logger.info "User exists but without fb, connecting profiles... "
          @user.facebook_id = fbObj.id
          @user.save
        else
          random_password = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{fb_user.email}--#{params[:fb_auth_token]}--")[0,10]
          Rails.logger.info "User needs registration: name: #{fb_user.first_name} #{fb_user.last_name}, email: #{fb_user.email}, pass: #{random_password}"
          @user = User.create!({ :name => fb_user.first_name + " " + fb_user.last_name, :email => fb_user.email, :facebook_id => fbObj.id, :username => fb_user.email, :password => random_password, :password_confirmation => random_password })
          Rails.logger.info "User is registered"
          true
        end
      end
    else
      Rails.logger.info "Authenticating with http basic auth"
      authenticate_or_request_with_http_basic "Authentication Required" do |email, password|
        @user = User.find_by_email(email)
        if @user.nil?
          Rails.logger.info "User0: " + @user.to_s
          @user = User.find_by_username(email)
          Rails.logger.info "User1: " + @user.to_s
        end
        unless @user.nil?
          (email == @user.username || email == @user.email) && @user.valid_password?(password)
        end
      end
    end
  end

  def auth_with_credentials
    authenticate_or_request_with_http_basic "Authentication Required" do |username, password|
      username == @model.credentials[:username] && password == @model.credentials[:password]
    end
  end

  def user_info
    return unless auth_with_user == true
    
    render :json => @user
  end

  # ------------------------------
  # create user
  def create_user
    Rails.logger.info "User params: email: " + params[:user][:email].to_s + ", name: " + params[:user][:name].to_s
    if params[:user].nil?
      @user = User.new(:username => params[:email], :email => params[:email], :password => params[:password], :password_confirmation => params[:password], :phone => params[:phone],
        :name => params[:name])
    else
      Rails.logger.info "ASDFASDFASDFASDF Referral ID: " + params[:user][:referral_id]
      @user = User.new(:username => params[:user][:email], :email => params[:user][:email], :password => params[:user][:password], :password_confirmation => params[:user][:password], :phone => params[:user][:phone], :name => params[:user][:name])
      referral = params[:user][:referral_id]
    end
    @user.add_role("Normal")
    
    if @user.save then
      Rails.logger.info "User saved4"
      if defined? referral and not referral.nil? then
        signup = Signup.create(:user_id => @user.id, :referring_user => referral, :name => "Sign up bonus", :points => 100)
        CollectedActivityitem.create(:user_id => @user.id, :activityitem_id => signup.activityitem_id, :collected_at => DateTime.now )
        TeamMember.create(:user_id => @user.id, :member_id => referral)
        TeamMember.create(:user_id => referral, :member_id => @user.id)
        
        referral_act = Referral.create(:user_id => referral, :referred_user => @user.id, :name => "Referring " + @user.name, :points => 100)
        CollectedActivityitem.create(:user_id => referral, :activityitem_id => referral_act.activityitem_id, :collected_at => DateTime.now )
      end
      render :json => @user
    else
      Rails.logger.info "User not saved properly"
      error_str = ""
      @user.errors.each_full { |msg| error_str = error_str+msg }
      render :json => { :error => error_str }, :status => 409
    end
  end

  # ------------------------------
  # create records
  def create_record
    Rails.logger.info "First OK"
    if @model.needs_authentication? then
      Rails.logger.info "Second here"
      return unless auth_with_user == true
    else @model.uses_credentials?
      Rails.logger.info "Third here"
      return unless auth_with_credentials == true
    end
    Rails.logger.info "Params: " + params.to_s

    Rails.logger.info "Adding user_id to params, " + @user.nil?.to_s + ", " + @model.new.respond_to?(:user_id).to_s
    if @model.new.respond_to?(:user_id) and not @user.nil? then
      Rails.logger.info "Adding user_id to params" + @user.id.to_s
      params[:user_id] = @user.id
    end

    params.delete(:controller)
    params.delete(:model_name)
    params.delete(:action)
    params.delete(:locale)
    Rails.logger.info "Creating record with params: " + params.to_s
    
    record = @model.create_record(params)
    Rails.logger.info "Creating record finsihed"

    unless record.nil? then
      Rails.logger.info "Rendering object: " + record.as_json
      render :json => record
    else
      Rails.logger.info "Error"
      render :json => "ERROR", :status => 500
    end
  end
  
  # ------------------------------
  # create records
  def update_record
    Rails.logger.info "First OK"
    if @model.needs_authentication? then
      Rails.logger.info "Second here"
      return unless auth_with_user == true
    else @model.uses_credentials?
      Rails.logger.info "Third here"
      return unless auth_with_credentials == true
    end
    Rails.logger.info "Params: " + params.to_s

    Rails.logger.info "Adding user_id to params, " + @user.nil?.to_s + ", " + @model.new.respond_to?(:user_id).to_s
    if @model.new.respond_to?(:user_id) and not @user.nil? then
      Rails.logger.info "Adding user_id to params" + @user.id.to_s
      params[:user_id] = @user.id
    end

    params.delete(:controller)
    params.delete(:model_name)
    params.delete(:action)
    params.delete(:locale)
    Rails.logger.info "Creating record with params: " + params.to_s
    
    record = @model.update_record(params)

    unless record.nil? then
      render :json => record
    else
      error_str = { :error => "record conflict" }
      render :json => error_str, :status => 409
    end
  end
  
  # ------------------------------
  # custom synchronization methods
  
  # update sync a whole model
  def update_all
    if @model.needs_authentication? then
      update_all_authenticated
    elsif @model.uses_credentials? then
      update_all_with_credentials
    else
      update_all_unauthenticated
    end
  end
  
  def update_all_unauthenticated
    if params[:updated_at].nil? then
      @records = @model.all
    else
      @records = @model.find(:all, :conditions => ['updated_at > ?', Time.parse(params[:updated_at])+1])
    end
        
    respond_with_records @records    
  end
  
  def update_all_authenticated
    # authenticate  
    return unless auth_with_user == true
    
    @records = @model.find_all_by_user_id(@user.id)
    
    respond_with_records @records
  end
  
  
  def update_all_with_credentials
    # authenticate
    return unless auth_with_credentials == true
    
    update_all_unauthenticated
  end
    
  # delete sync a whole model
  def delete_all
    if @model.needs_authentication? then
      render :text => t('needs_authentication')
    else
      @records = @model.all.collect{ |m| m.id }
    
      respond_with_records @records
    end
  end
  
  # down sync one record
  #def update_one
  #  if @model.needs_authentication? then
  #    update_one_authenticated
  #  else
  #    update_one_unauthenticated
  #  end
  #end
  
  #def update_one_unauthenticated
  #  @record = @model.find(params[:id])
  #  respond_to do |format|
  #    format.html { render :text => t('format_error') }
  #    format.json { render :json => @record }
  #    format.xml { render :xml => @record }
  #  end
  #end
  
  #def update_one_authenticated
  #
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
