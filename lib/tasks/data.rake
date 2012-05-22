# encoding: UTF-8

require 'util.rb'

namespace :data do
  desc "Copy tags from the events table to the tags table"
  task :copy_tags => :environment do
    Event.all.each do |e|
      p "Processing event # #{e.id}"
      tag_array = e.tags.split ','
      tag_array.each do |tag_str|
        # Check if the tag exists already. If not, create it
        t = Tag.find_by_name tag_str
        t ||= Tag.create!(:name => tag_str)
        # Now create a mapping entry
        Tagmap.create!(:event_id => e.id, :tag_id => t.id)
      end
    end
  end
  
  desc "Clean tags table and tagmap table"
  task :delete_tags => :environment do
    Tag.delete_all
    Tagmap.delete_all
  end

  desc "Add more tags for events"
  task :add_more_tags, [:start_event] => :environment do |t, args|
    start_event_id = args.start_event.to_i
    print "Starting from event id: #{start_event_id}\n"
    util = Util.instance
    Event.all.each do |e|
      if e.id < start_event_id
        next
      end
      print "-----\n"
      print "Adding tags for event # #{e.id}\n"
      tag_array = util.get_more_tags(e.title)
      if tag_array.nil? 
        return
      end
      tag_array.each do |tag_str|
        # Check if the tag exists already. If not, create it
        t = Tag.find_by_name tag_str
        t ||= Tag.create!(:name => tag_str)
        # Now create a mapping entry
        Tagmap.create!(:event_id => e.id, :tag_id => t.id)
      end
    end
  end
end # data namespace


# Stuff to dump and import dev database

database = "db/development.sqlite3"

namespace :db do
  
  #rake db:dump
  desc "dumps the database to a sql file"
  task :dump => :environment do
    puts "Creating #{database}.sql file."
    `sqlite3 #{database} .dump > #{database}.sql`
  end

  #rake db:dumpimport - Resets the DB.
  desc "imports the #{database}.sql file to the current db"
  task :dumpimport => [:environment, :reset] do
    `sqlite3 #{database} < #{database}.sql`
  end
end
