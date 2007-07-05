# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def link_to_playlist(text, streamable)
    link_to text, url_for_playlist(streamable)
  end
  
  def url_for_playlist(streamable)
    url_for :controller => 'playlists', :action => streamable.class.name.underscore, :id => streamable
  end
  
  def url_for_stream(streamable)
    url_for :controller => 'files', :action => 'stream', :id => streamable, :filename => streamable.basename
  end
  
  def link_to_download(text, file_id)
    link_to text, url_for_download(file_id)
  end
  
  def url_for_download(file_id)
    url_for :controller => 'files', :action => 'download', :id => file_id
  end
  
  def current_playlist
    return unless current_user
    current_user.playlist || Playlist.new
  end
  
  def inline_player(options = {})
    player_options = options.to_a.map { |a| a.join('=') }.join('&')
    <<-EOC
    <div class="inline-player">
    <object type="application/x-shockwave-flash" data="/player/musicplayer.swf?#{player_options}" width="17" height="17">
      <param name="movie" value="/player/musicplayer.swf#{player_options}" />
      <img src="noflash.gif" width="17" height="17" alt="" />
    </object>
    </div>
    EOC
  end
end
