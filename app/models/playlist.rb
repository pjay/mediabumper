class Playlist < ActiveRecord::Base
  belongs_to :user
  
  has_many :playlists_items
  has_many :media_files, :through => :playlists_items, :order => 'position'
end
