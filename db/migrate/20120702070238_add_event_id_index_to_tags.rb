class AddEventIdIndexToTags < ActiveRecord::Migration
  def change
    add_index :tags, :event_id
  end
end
