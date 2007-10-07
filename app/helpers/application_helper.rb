# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def link_to_playlist(name, streamable)
    link_to_function name, "$('flash_player').loadFile({file:\"#{url_for_playlist(streamable)}\"});" + player_event(:playpause)
  end
  
  def url_for_playlist(streamable)
    url_for :controller => 'playlists', :action => streamable.class.name.underscore, :id => streamable
  end
  
  def link_to_stream(name, streamable)
    link_to_function name, "$('flash_player').loadFile({file:\"#{url_for_stream(streamable)}\"});" + player_event(:playpause)
  end
  
  def url_for_stream(streamable)
    if streamable.is_a? Hash
      url_for :controller => 'files', :action => 'stream', :r => streamable[:r], :p => streamable[:p]
    else
      url_for :controller => 'files', :action => 'stream', :id => streamable, :filename => streamable.basename
    end
  end
  
  def link_to_download(name, file_id)
    link_to name, url_for_download(file_id)
  end
  
  def url_for_download(file_id)
    url_for :controller => 'files', :action => 'download', :id => file_id
  end
  
  def current_playlist
    return unless current_user
    current_user.playlist || Playlist.new
  end
  
  # Given a repository and a path relative to the repository root, returns a
  # breadcrumb-like filesystem navigation with each directory being a link to
  # browse its content.
  #
  # The options are:
  #   * :separator: string to use as the file separator in output (default: " #{File::SEPARATOR} ")
  def path_with_browse_links(repository, relative_path, options = {})
    current_path, html = Array.new, Array.new
    
    options[:separator] ||= " #{File::SEPARATOR} "
    
    html << link_to(h(repository.name), repository_path(:r => repository.id))
    return html unless relative_path
    
    relative_path.split(File::SEPARATOR).each do |entry|
      current_path << entry
      html << if File.directory? File.join(repository.path, current_path)
        link_to(h(entry), browse_path(:r => repository, :p => current_path.join(File::SEPARATOR)))
      else
        h(entry)
      end
    end
    
    html.join h(options[:separator])
  end
end
