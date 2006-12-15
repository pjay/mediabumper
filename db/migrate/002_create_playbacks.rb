class AddPlaybacks < ActiveRecord::Migration
  def self.up
    create_table :playbacks do |t|
      t.column :user_id, :integer, :null => false
      t.column :media_file_id, :integer, :null => false
      t.column :created_at, :datetime
    end
    add_index :playbacks, [:user_id, :media_file_id]
  end

  def self.down
    drop_table :playbacks
  end
end
