ActionController::Routing::Routes.draw do |map|
  map.resources :users, :sessions
  map.resources :playlists, :artists
  map.resources :albums, :member => { :play => :get }
  
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login  '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  
  map.connect '/browse', :controller => 'files', :action => 'browse'
  map.repository '/browse/:r', :controller => 'files', :action => 'browse'
  map.browse '/browse/:r/*p', :controller => 'files', :action => 'browse'
  map.connect '/stream/:r/*p', :controller => 'files', :action => 'stream'
  
  map.connect '', :controller => 'home', :action => 'index'
  
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end
