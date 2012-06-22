# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120622054849) do

  create_table "babels", :force => true do |t|
    t.string  "term",         :null => false
    t.integer "norm_term_id", :null => false
  end

  add_index "babels", ["term"], :name => "index_babels_on_term"

  create_table "events", :force => true do |t|
    t.text    "title",                :null => false
    t.integer "jd",                   :null => false
    t.string  "source", :limit => 10
  end

  create_table "tags", :id => false, :force => true do |t|
    t.integer "event_id",               :null => false
    t.string  "name",     :limit => 80, :null => false
    t.integer "source"
  end

  add_index "tags", ["name"], :name => "name_of_tags"

end
