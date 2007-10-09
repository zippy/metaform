# Metaform routes
map.connect 'records/listings/:list_name', :controller => 'records', :action => 'index', :conditions => {:method => :get}
map.connect 'records/:id', :controller => 'records', :action => 'update', :conditions => {:method => :put}
map.connect 'records/:id/:presentation', :controller => 'records', :action => 'update', :conditions => {:method => :put}
map.connect 'records/:id/:presentation', :controller => 'records', :action => 'show'
map.connect 'records/:id/:presentation/:tabs', :controller => 'records', :action => 'show', :conditions => {:method => :get}
map.connect 'records/:id/:presentation/:tabs', :controller => 'records', :action => 'update', :conditions => {:method => :put}
map.connect 'records/:id', :controller => 'records', :action => 'show'

map.connect 'forms/:form_id/records/', :controller => 'records', :action => 'index', :conditions => {:method => :get}
map.connect 'forms/:form_id/records/new', :controller => 'records', :action => 'new'
map.connect 'forms/:form_id/records/new/:presentation', :controller => 'records', :action => 'new'
map.connect 'forms/:form_id/records/new/:presentation/:current', :controller => 'records', :action => 'new'
map.connect 'forms/:form_id/records/', :controller => 'records', :action => 'create', :conditions => {:method => :post}
map.connect 'forms/:form_id/records/:presentation', :controller => 'records', :action => 'create', :conditions => {:method => :post}
map.connect 'forms/:form_id/records/:presentation/:current', :controller => 'records', :action => 'create', :conditions => {:method => :post}

map.stats '/stats', :controller => 'stats', :action => 'index', :conditions => {:method => :get}  
