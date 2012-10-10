class CreateTlImages < ActiveRecord::Migration
  def change
    create_table :tl_images do |t|
      t.string :title
      t.string :fname

      t.timestamps
    end
  end
end
