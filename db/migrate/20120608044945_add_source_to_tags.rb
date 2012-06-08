class AddSourceToTags < ActiveRecord::Migration
  def up
    add_column :tagmap, :source, :integer
  end

  def down
    remove_column :tagmap, :source
  end
end
