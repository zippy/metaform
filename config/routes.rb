Rails.application.routes.draw do
  get '/records/listings/:list_name' => 'records#index'
  put '/records/:id' => 'records#update'
  put '/records/:id/:presentation' => 'records#update'
  get '/records/:id/:presentation' => 'records#show'
  get '/records/:id/:presentation/:index' => 'records#show'
  put '/records/:id/:presentation/:index' => 'records#update'
  get '/records/:id' => 'records#show'

  get '/forms/:form_id/records/' => 'records#index'
  get '/forms/:form_id/records/new' => 'records#new'
  get '/forms/:form_id/records/new/:presentation' => 'records#new'
  get '/forms/:form_id/records/new/:presentation/:current' => 'records#new'
  post '/forms/:form_id/records/' => 'records#create'
  post '/forms/:form_id/records/:presentation' => 'records#create'
  post 'forms/:form_id/records/:presentation/:current' => 'records#create'
end