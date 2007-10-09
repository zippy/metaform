require_dependency("#{RAILS_ROOT}/app/controllers/application")

class RecordsController < ApplicationController
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
      format.html # show.rhtml
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
    respond_to do |format|
      if @record.save(@presentation,params[:workflow_action])
#        flash[:notice] = 'Record was successfully created.'
        format.html { redirect_to @record.form.url_after_new_form(@presentation) }
        format.xml  { head :created, :location => Record.url(@record.id,@presentation,@tabs) }
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
    respond_to do |format|
      if @record.update_attributes(params[:record],@presentation,params[:workflow_action])
        flash[:notice] = 'Record was successfully updated.'
        format.html { render :action => "show" }
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
    @form.reset_attributes
    @tabs = params[:tabs]
  end
  
  def setup_new_record
    the_form = Form.find(params[:form_id])
#TODO there is a circularity problem here.  To set up the form we call it with a presentation
# but part of the setup gets us the default presentation if we don't have one!
#    @presentation = the_form.get_stuff(:default_create_presentation) if !@presentation
    @presentation = params[:presentation]

#TODO this is more evidence that we don't have things right.  Currently a "form instance" is spread accross
# Record, FormInstance, and "setting up" the class variables in V2Form to work correctly.  All this needs
# to be unified, because right now there will be two calls to setup.  Once here "manually" and also later
# in Record#update_attributes
    fi = FormInstance.new
    fi.form_id = the_form.to_s
    fi.workflow = the_form.workflow_for_new_form(@presentation)
    the_form.setup(@presentation,fi)
    @record = Record.new(fi,params[:record])
    setup_record_params
  end
end
