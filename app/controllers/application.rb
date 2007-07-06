# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  before_filter :login_from_cookie
  
  def current_playlist
    return unless logged_in?
    current_user.playlist ||= Playlist.new(:name => 'default')
  end
end
