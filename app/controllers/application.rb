# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  
  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :login_from_cookie
  
  def current_playlist
    return unless current_user
    current_user.playlist || Playlist.new
  end
end
