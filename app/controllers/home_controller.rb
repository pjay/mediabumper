class HomeController < ApplicationController
  def index
    @recent = MediaFile.recent(:limit => 10)
  end
end
