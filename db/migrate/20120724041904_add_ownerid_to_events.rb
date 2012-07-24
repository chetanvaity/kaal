class AddOwneridToEvents < ActiveRecord::Migration
  def change
    add_column :events, :ownerid, :integer

  end
end
