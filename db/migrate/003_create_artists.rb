class CreateArtists < ActiveRecord::Migration
  def self.up
    create_table :artists do |t|
      t.column :name, :string, :null => false
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :artists
  end
end
