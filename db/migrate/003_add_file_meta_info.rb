class AddFileMetaInfo < ActiveRecord::Migration
  def self.up
    add_column :media_files, :title, :varchar
    add_column :media_files, :artist, :varchar
    add_column :media_files, :size, :integer, :null => false
    add_column :media_files, :duration, :time, :null => false
    add_column :media_files, :bitrate, :integer, :null => false
    add_column :media_files, :vbr, :boolean, :null => false, :default => false
  end

  def self.down
    
  end
end
