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

ActiveRecord::Schema.define(:version => 20120608044945) do

  create_table "events", :force => true do |t|
    t.string   "title"
    t.string   "tags"
    t.datetime "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source"
  end

  create_table "tagmap", :force => true do |t|
    t.integer "event_id"
    t.integer "tag_id"
    t.integer "source"
  end

  add_index "tagmap", ["event_id"], :name => "index_tagmap_on_event_id"
  add_index "tagmap", ["tag_id"], :name => "index_tagmap_on_tag_id"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

end
