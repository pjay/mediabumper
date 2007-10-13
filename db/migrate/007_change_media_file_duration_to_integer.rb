class ChangeMediaFileDurationToInteger < ActiveRecord::Migration
  def self.up
    remove_column :media_files, :duration
    add_column :media_files, :duration, :integer
  end

  def self.down
    add_column :media_files, :duration, :time, :null => false
    remove_column :media_files, :duration
  end
end
