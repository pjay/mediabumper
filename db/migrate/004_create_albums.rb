class CreateAlbums < ActiveRecord::Migration
  def self.up
    create_table :albums do |t|
      t.column :artist_id, :integer
      t.column :name, :string, :null => false
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :albums
  end
end
