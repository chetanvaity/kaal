class CreateTimelines < ActiveRecord::Migration
  def change
    create_table :timelines do |t|
      t.string :title
      t.text :desc
      t.integer :owner_id
      t.string :imgurl
      t.string :events
      t.string :tags

      t.timestamps
    end
  end
end
