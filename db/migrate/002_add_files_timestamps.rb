class AddFilesTimestamps < ActiveRecord::Migration
  def self.up
    add_column :media_files, :created_at, :timestamp, :null => false
    add_column :media_files, :updated_at, :timestamp, :null => false
  end

  def self.down
    remove_column :media_files, :created_at
    remove_column :media_files, :updated_at
  end
end
