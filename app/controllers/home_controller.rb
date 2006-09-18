class HomeController < ApplicationController
  def index
    @recent = MediaFile.recent(10)
  end
end
