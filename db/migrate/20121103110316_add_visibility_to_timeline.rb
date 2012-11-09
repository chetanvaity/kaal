class AddVisibilityToTimeline < ActiveRecord::Migration
  def change
    add_column :timelines, :visibility, :integer, :default => 0
  end
end
