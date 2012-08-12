class AddImgurlToEvents < ActiveRecord::Migration
  def change
    add_column :events, :imgurl, :string

  end
end
