class AddWikiIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :wiki_id, :integer
  end
end
