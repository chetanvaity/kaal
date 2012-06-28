class AddIdToTags < ActiveRecord::Migration
  def change
    add_column :tags, :id, :primary_key
  end
end
