class HomeController < ApplicationController
  def index
    @recent_files  = MediaFile.recent(:limit => 10)
    @recent_albums = Album.recent(:limit => 10)
  end
end
