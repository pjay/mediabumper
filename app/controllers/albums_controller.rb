class AlbumsController < ApplicationController
  def index
    @albums = Album.find(:all, :order => 'created_at DESC')
  end

  def show
    @album = Album.find(params[:id], :include => [:artist, :songs])
    @files = @album.songs.map { |a| a.media_file }
  end

  # def play
  #   @album = Album.find(params[:id])
  #   @files = @album.songs.map(&:media_file)
  #   render 'playlists/xspf'
  # end
end
