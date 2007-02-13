class CreateSongs < ActiveRecord::Migration
  def self.up
    create_table :songs do |t|
      t.column :artist_id, :integer
      t.column :album_id, :integer
      t.column :media_file_id, :integer, :null => false
      t.column :name, :string, :null => false
    end
  end

  def self.down
    drop_table :songs
  end
end
