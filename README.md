# Metaform

This plugin provides a system for defining and generating forms for complex
data-collection using a domain specific language (dsl) to create:

* a data model and a specification of how that data is constrained
* a presentation specification about how fields from forms will appear when displayed
* workflows that specify the states a form can go through and actions that move a form from one state to another
* listings to retrieve groups of forms based on arbitrary criteria
* reports to retrieve aggregate information across forms

The system also includes a "widget" system that pre-defines a number of html widgets
including radio-button and check-box groups, text-based date entry, etc.. which all
include javascript handling for in browser use of widget values regardless of how they are
displayed. For example, a date widget might be displayed as three text input boxes, but
the widget generates javascript to get the true date value out of the widget directly.


## Installation

Add this line to your application's Gemfile:

    gem 'metaform'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install metaform

Then:

1. Add the code from example/routes.rb into your config/routes.rb file.
2. Use the generator:

    $ ./script/generate metaform

This will add:

* two migrations (which you need to rake db:migrate for) 
* the "forms" directory where you will define your forms using the metaform DSL (see below)
* a javascript file to your public/javascripts
* the default css stylesheet to public/stylesheets
* records/show.rhtml and records/new.rhtml to app/views/ as sample views that use metaform to create forms

3. Include the following helper in the head of your application layout:
    <%= include_metaform_assets %>
This will load the javascripts and the stylesheets when needed.  To tell this function when to load the assets
simply add: 
    <%@metaform_include_assets = true%>
to the top of the view that shows a form.

## The Metaform Domain Specific Language (DSL)

Metaform defines an abstraction that separates data definition from data display.  Much like you are
used to in rails data model and views.  To use the metaform definition language simply create a +forms+ 
directory in your rails app, with a file in it that ends in "form.rb" Metaform will auto-create a form
class by the name of the file from definitions in the file.

### Defining the data model-- fields with constraints, and workflows

#### fields

	def_fields <field_options> do
		f <field_name>,<field_options>
	end

<field_options> are:
	:type => <field_type>
	:constrants => <constraints>
	:default => true | false
	:indexed_default_from_null_index => true|false
	:followups => {
		<value> | !<value> | /<regex>/ => f(<field_name>, <field_options>)
	}

<constraints> are a hash of key value pairs:
	'required' => true | false
	'regex' => '<regex>'
	'range' => '<start>-<end>'
	'set' => <value_label_pairs>
	'enumeration' => <value_label_pairs>

<value_label_pairs> are an array of key value pairs of the form:
  [{<value> => <human_label>},...]
  
#### workflows

	def_workflows <work_flow_name> do
		action <name>,[<legal_states>...] do |meta|
		  # the meta hash provides access to various things:
      # meta[:request] the request object
      # meta[:session] the session object
      # meta[:record] the record object
			...
			state <state_name>  # set the next state to go to
		end
	end

#### directives

To load additional form definitions use:

  include_definitions(<path>)  

To load definitions at the class level (constants, helper methods etc) use:

  include_helpers(<path>)

### Defining display appearance == presentations, questions, and tabs

  presentation <presentation_name>,<options (:legal_state, :indexed)> do
  	<q>...
  	<p>...
  end

### Listings

Record has several methods for creating filtered lists of records.  Record.search uses sql filters to have the database perform the filtering.  Record.locate uses ruby filters, with an optional sql_prefilter.  Record.locate first calls Record.search to process the sql_prefilter, if any.  Then Record.locate calls Record.gather to perform the actual ruby filtering.  If you have not passed an sql_prefilter to Record.locate, then Record.gather will do its ruby filtering on the entire database, which is time intensive.  It may be fastest to use only one field_id in the sql_prefilter, so use the biggest limiter there and save the other limiting field_ids for the ruby filter.

Record.gather can also be called directly on a list of FormInstances which you pass in as a parameter or can be given a proc to create the list of FormInstances. 

Record.search always returns an array of FormInstances, where Record.gather/locate can also return an answers hash.  An answers hash will allow the handling of indexed fields.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
