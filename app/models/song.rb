class Song < ActiveRecord::Base
  belongs_to :media_file
  belongs_to :artist
  belongs_to :album
end
