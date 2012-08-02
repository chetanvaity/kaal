class AddExtraWordsToEvents < ActiveRecord::Migration
  def change
    add_column :events, :extra_words, :text
  end
end
