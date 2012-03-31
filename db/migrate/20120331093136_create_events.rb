class CreateEvents < ActiveRecord::Migration
  def up
    create_table 'events' do |t|
      t.string 'title'
      t.string 'tags'
      t.datetime 'date'
      
      t.timestamps
    end
  end

  def down
    drop_table 'events'
  end
end
