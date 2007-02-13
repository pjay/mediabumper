class DropObsoleteMediaFilesFields < ActiveRecord::Migration
  def self.up
    remove_column :media_files, :title
    remove_column :media_files, :artist
  end

  def self.down
    add_column :media_files, :title, :string
    add_column :media_files, :artist, :string
  end
end
