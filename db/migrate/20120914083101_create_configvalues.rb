class CreateConfigvalues < ActiveRecord::Migration
  def change
    create_table :configvalues do |t|
      t.string :paramname
      t.string :paramvalue

      t.timestamps
    end
  end
end
