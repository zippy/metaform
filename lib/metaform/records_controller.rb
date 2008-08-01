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
      format.html { render get_show_render_options}
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
      else
        opts = {:convert_from_html=>true}
        if @index
          attribs = params[:record]
          opts[:index] = @index
        elsif params[:multi_index]
          opts[:multi_index] = true
          attrs = []
          zap_fields = params[:multi_index_fields].split(/,/)
          attribs = {0=>{}}
          params[:record].each do |k,v|
            if k =~ /_([0-9]+)_(.*)/
              idx = $1.to_i
              fn = $2
#              zap_fields << fn
              attrs[idx] ||= {}
              attrs[idx][fn] = v
            else
              attribs[0][k] = v
            end
          end

          # compact all the attributes into a hash ignoring the actual index given
          # this handles all the issues of deleting indexes
          attrs = attrs.compact
          # first merge the 0th items into attribs (because there could have been other)
          # non indexed items on the page at the 0th level
          if attrs[0]
            attribs[0].update(attrs[0])
            attrs.shift
          end
          #then copy in any indexed items
          x = 1
          attrs.each {|a| attribs[x]=a;x+=1}
          opts[:clear_indexes] = zap_fields
        else
          attribs = params[:record]
        end
        if @record.update_attributes(attribs,@presentation,get_meta_data,opts)
          after_update_record(@record) if respond_to?(:after_update_record)
          after_save_record(@record) if respond_to?(:after_save_record)
          flash[:notice] = 'Record was successfully updated.'
          redirect_url = @record.action_result[:redirect_url] if @record.action_result
          redirect_url = params[:_redirect_url] if !redirect_url  && params[:_redirect_url]
          format.html { redirect_url ? redirect_to(redirect_url) : render(:action => "show") }
          format.xml  { head :ok }
        else
          format.html { render get_show_render_options }
          format.xml  { render :xml => @updated.errors.to_xml }
        end
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
    @form.set_verification(false)
    @tabs = params[:tabs]
    @index = params[:index]
  end
  
  def setup_new_record
    @presentation = params[:presentation]
    f = Form.cache[params[:form_id]]
    f ||= params[:form_id].constantize.new
    @record = Record.make(f,@presentation,params[:record],:convert_from_html => true,:index => params[:index])
    setup_record_params
  end
  
  def get_show_render_options
    options = {:template => 'records/show'}
    if params[:template]
      tmpl = params[:template]
    elsif FileTest.exists?("#{RAILS_ROOT}/app/views/records/#{@presentation}.html.erb")
      tmpl = @presentation
    end
    options[:template] = 'records/'<< tmpl if tmpl
    options[:layout] = params[:template] if FileTest.exists?("#{RAILS_ROOT}/app/views/layouts/#{tmpl}.html.erb")
    options[:layout] = params[:layout] if params[:layout]
    options
  end
  
  def get_meta_data
    meta = params[:meta]
    meta ||= {}
    meta[:request] = request
    meta[:session] = session
    meta[:params] = params
    meta.update(meta_data_for_save) if respond_to?(:meta_data_for_save)
    meta
  end
end
