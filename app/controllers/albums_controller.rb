class AlbumsController < ApplicationController
  def show
    @album = Album.find(params[:id], :include => [:artist, :songs])
    @files = @album.songs.map { |a| a.media_file }
  end
end
