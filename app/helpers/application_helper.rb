# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def link_to_stream(text, streamable)
    link_to text, :controller => 'playlists', :action => streamable.class.name.underscore, :id => streamable
  end
  
  def link_to_download(text, file_id)
    link_to text, :controller => 'files', :action => 'download', :id => file_id
  end
  
  def current_playlist
    return unless current_user
    current_user.playlist || Playlist.new
  end
end
