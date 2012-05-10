class TagsTable < ActiveRecord::Migration
  def up
    create_table :tags do |t|
      t.string :name
    end

    create_table :tagmap do |t|
      t.references :event
      t.references :tag
    end

    add_index :tagmap, :event_id
    add_index :tagmap, :tag_id
  end

  def down
    drop_table :tags
    drop_table :tagmap
    # indexes are dropped automatically when we drop a column
  end
end
