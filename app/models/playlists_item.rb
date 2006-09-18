class PlaylistsItem < ActiveRecord::Base
  belongs_to :playlist
  belongs_to :media_file
end
