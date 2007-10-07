class Album < ActiveRecord::Base
  belongs_to :artist
  has_many :songs
  
  class << self
    def recent(options = {})
      find_options = { :order => 'created_at DESC' }.update(options)
      find(:all, find_options)
    end
  end
end
