class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table "media_files", :force => true do |t|
      t.column "relative_path", :string, :default => "", :null => false
      t.column "repository_id", :integer, :default => 0, :null => false
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
      t.column "title", :string
      t.column "artist", :string
      t.column "size", :integer, :default => 0, :null => false
      t.column "duration", :time, :default => Sat Jan 01 00:00:00 CET 2000, :null => false
      t.column "bitrate", :integer, :default => 0, :null => false
      t.column "vbr", :boolean, :default => false, :null => false
    end

    create_table "playlists", :force => true do |t|
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "name", :string, :default => "", :null => false
    end

    create_table "playlists_items", :force => true do |t|
      t.column "playlist_id", :integer, :default => 0, :null => false
      t.column "media_file_id", :integer, :default => 0, :null => false
      t.column "position", :integer, :default => 0, :null => false
    end

    create_table "repositories", :force => true do |t|
      t.column "path", :string, :default => "", :null => false
      t.column "name", :string, :default => "", :null => false
    end

    create_table "users", :force => true do |t|
      t.column "login", :string
      t.column "email", :string
      t.column "crypted_password", :string, :limit => 40
      t.column "salt", :string, :limit => 40
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "remember_token", :string
      t.column "remember_token_expires_at", :datetime
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
