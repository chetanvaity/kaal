class AddDescAndUrlToEvents < ActiveRecord::Migration
  def change
    add_column :events, :desc, :text
    add_column :events, :url, :string
  end
end
