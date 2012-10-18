class AddOwnerIndexToEventsTimelines < ActiveRecord::Migration
  def change
    add_index :events, :ownerid
    add_index :timelines, :owner_id
  end
end
