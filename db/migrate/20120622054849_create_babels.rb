class CreateBabels < ActiveRecord::Migration
  def change
    create_table :babels do |t|
      t.string :term, :null => false
      t.integer :norm_term_id, :null => false
    end

    add_index :babels, :term
  end
end
