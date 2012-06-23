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

  desc "Convert tags to lowercase and combine them"
  task :downcase_tags => :environment do
    tags_2b_deleted = []
    Tag.all.each do |t|
      tag_str = t.name
      print "-----\n"
      print "Dealing with tag: #{t.id}: #{tag_str}\n"
      if tag_str =~ /[A-Z]/
        # Tag has some uppercase chars
        # Check if there is a lowercase tag
        lc_tag_str = tag_str.downcase
        lc_tag = Tag.find_by_name(lc_tag_str)
        if lc_tag.nil?
          print "  No lowercase tag. Convert this tag to lowercase\n"
          t.name = lc_tag_str
          t.save! 
        else
          print "  Lowercase tag present. Move tag mappings there and mark this tag for deletion\n"
          tms_2b_deleted = []
          Tagmap.find_all_by_tag_id(t.id).each do |tm|
            Tagmap.create!(:event_id => tm.event_id, :tag_id => lc_tag.id)
            tms_2b_deleted.push(tm.id)
          end
          Tagmap.delete_all({:id => tms_2b_deleted})
          tags_2b_deleted.push(t.id)
        end
      else
        print "  Tag: #{tag_str} is all lowercase. Nothing to do.\n"
      end
    end
    print "Deleting #{tags_2b_deleted.size} marked tags...\n"
    Tag.delete_all({:id => tags_2b_deleted})
    tags_2b_deleted = []
  end

  desc "Adds source field to events"
  task :add_source, [:start_event, :end_event, :source] => :environment do |t, args|
    start_event_id = args.start_event.to_i
    end_event_id = args.end_event.to_i
    source_str = args.source
    print "Adding source=#{source_str} for events #{start_event_id} to #{end_event_id}\n"
    Event.connection.execute("update events set source=\'#{source_str}\' where id >= #{start_event_id} and id <= #{end_event_id}")
  end

  desc "Normalize tags in a text file using Babelnet"
  task :normalize_tags, [:tags_file, :out_file] do |t, args|
    util = Util.instance
    i = 0
    File.open(args.out_file, "w:UTF-8:UTF-8") do |outf|
      open(args.tags_file, "r:UTF-8:UTF-8").each_line do |line|
        arr = line.chomp.split(/\t/)
        next if arr.length != 2
        tag_str = arr[1]
        next if tag_str.nil?
        tag_str.gsub!(/ /, '_')
        norm_tag = util.get_synset(tag_str)[0]
        norm_tag.gsub!(/_/, ' ')
        outf.puts "#{arr[0]}\t#{norm_tag}"
        i=i+1
        print "#{i} tags done\n" if i%1000 == 0
      end
    end
  end

  desc "Read the Babelnet file and dump terms into babels DB table"
  task :populate_babels, [:babelnet_file] => :environment do |t, args|
    i=1
    File.open(args.babelnet_file, "r:UTF-8:UTF-8").each_line do |line|
      arr = line.chomp.split(/\s/)
      next if arr.length < 1
      norm_term = arr[0]
      norm_id = i
      arr.each do |term|
        term.gsub!(/_/, ' ')
        Babel.create!(:id => i, :term => term, :norm_term_id => norm_id)
        i=i+1
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
