class AddSourceToEvents < ActiveRecord::Migration
  def up
    add_column :events, :source, :string
  end

  def down
    remove_column :events, :source
  end
end
