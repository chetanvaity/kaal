class CreateActivityLogs < ActiveRecord::Migration
  def change
    create_table :activity_logs do |t|
      t.integer :user_id
      t.string :user
      t.string :controller
      t.string :action
      t.string :params
      t.string :extra
      t.string :ip
      t.string :browser

      t.timestamps
    end
  end
end
