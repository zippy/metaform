require_dependency("#{RAILS_ROOT}/app/controllers/application")

class RecordsController < ApplicationController
  
  include ApplicationHelper
  
  # GET /records/listings/[/<list_name>]
  def index
    @listing_name = params[:list_name]
    render(:template => "records/#{@listing_name}")
  end

  # GET /records/1
  # GET /records/1.xml
  def show
    setup_record
    respond_to do |format|
      if params[:template]
        format.html { render :template => 'records/'<<params[:template] }
      else
        format.html # show.rhtml
      end
      format.xml  { render :xml => @record.to_xml }
    end
  end

  # GET /form/<form_id>/records/new[/<presentation_id>[/<tab>]]
  def new
    setup_new_record
  end

  # POST /form/<form_id>/records/new[/<presentation_id>[/<tab>]]
  # POST /records.xml
  def create
    setup_new_record
    before_create_record(@record) if respond_to?(:before_create_record)
    before_save_record(@record) if respond_to?(:before_save_record)
    respond_to do |format|
      if @record.save(@presentation,get_meta_data)
        after_create_record(@record) if respond_to?(:after_create_record)
        after_save_record(@record) if respond_to?(:after_save_record)
#        flash[:notice] = 'Record was successfully created.'
        redirect_url = @record.action_result[:redirect_url]
        format.html { redirect_to(redirect_url) }
        format.xml  { head :created, :location => @record.url(@presentation,@tabs) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @updated.errors.to_xml }
      end
    end
  end

  # PUT /records/1
  # PUT /records/1.xml
  def update
    setup_record
    before_update_record(@record) if respond_to?(:before_update_record)
    before_save_record(@record) if respond_to?(:before_save_record)
    respond_to do |format|
      if !params[:record] && !params[:meta]
        redirect_url = params[:_redirect_url] if params[:_redirect_url]
        format.html { redirect_url ? redirect_to(redirect_url) : render(:action => "show") }
        format.xml  { head :ok }        
      elsif @record.update_attributes(params[:record],@presentation,get_meta_data,:convert_from_html=>true,:index=>@index)
        after_update_record(@record) if respond_to?(:after_update_record)
        after_save_record(@record) if respond_to?(:after_save_record)
        flash[:notice] = 'Record was successfully updated.'
        redirect_url = @record.action_result[:redirect_url] if @record.action_result
        redirect_url = params[:_redirect_url] if !redirect_url  && params[:_redirect_url]
        format.html { redirect_url ? redirect_to(redirect_url) : render(:action => "show") }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @updated.errors.to_xml }
      end
    end
  end
    
  private
  def setup_record
    @record = Record.find(params[:id])
    @presentation = params[:presentation]
    setup_record_params
  end
  
  def setup_record_params
    @form = @record.form
    @tabs = params[:tabs]
    @index = params[:index]
  end
  
  def setup_new_record
    @presentation = params[:presentation]
    f = Zform.cache[params[:form_id]]
    f ||= params[:form_id].constantize.new
    @record = Record.make(f,@presentation,params[:record],:convert_from_html => true,:index => params[:index])
    setup_record_params
  end
  
  def get_meta_data
    meta = params[:meta]
    meta[:request] = request
    meta[:session] = session
    meta.update(meta_data_for_save) if respond_to?(:meta_data_for_save)
    meta
  end
end
