# encoding: UTF-8

require 'page_rankr'
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
    i = Babel.maximum(:id) + 1
    File.open(args.babelnet_file, "r:UTF-8:UTF-8").each_line do |line|
      arr = line.chomp.split(/\s/)
      next if arr.length < 1
      norm_term = arr[0]
      norm_id = i
      arr.each do |term|
        term.gsub!(/_/, ' ').downcase!
        Babel.create!(:id => i, :term => term, :norm_term_id => norm_id)
        i=i+1
      end
    end
  end
  
  desc "Read event db, generate URL if not present and regenerate rank for that event. Create an output file with this information."
  task :generate_eventurl_and_rank, [:out_file, :start_event_id, :end_event_id] => :environment do |t, args|
    start_eve_id = -1
    end_eve_id = -1
    begin
      start_eve_id = Integer(args.start_event_id)
      end_eve_id = Integer(args.end_event_id)
    rescue
      puts "Please provide valid start and end ids."
      return
    end
    
    if (start_eve_id <= 0) || (end_eve_id <= 0) || (start_eve_id > end_eve_id)
      puts "Please provide valid start and end ids."
      return
    end
    
    File.open(args.out_file, "w:UTF-8:UTF-8") do |outf|
      #
      # It is not possible to load all records in memory at once. HEnce let's use
      # find_each method which default operates in the batches of 1000 records.
      #
      Event.find_each(:start => start_eve_id) do |evt|
        if (evt.id % 10) == 0
          print "##### GC start\n"
          GC.start
        end
          
        #Let's stop processing if we have already crossed end_event_id condition
        if evt.id > end_eve_id
          break;
        end
        
        # default url and pagerank
        url2write = evt.url
        pr2write = 1
        
        #
        #handling for events from 'yago'
        #
        if evt.source == 'yago'
          #
          # Generate the url if not present
          #
          if evt.url.blank?
            evt.title =~ /(Birth:|Death:|Created:|Ended:|Started:|End:) (.*)/
            t = $&.nil? ? evt.title : $2
            wiki_t = t.gsub(/ /, '_')
            url2write = "http://en.wikipedia.org/wiki/#{wiki_t}"
            #media_caption = "Excerpt from the Wikipedia article for #{t}"
          end
          
          # get the page rank
          begin
            print "Getting rank for #{url2write}\n"          
            # prhash = PageRankr.ranks(url2write, :google)
            # if (!prhash.nil?)
            #   prval = prhash[:google]
            #   if (!prval.nil?) && (prval > 0)
            #     pr2write = prval
            #   end
            # end
          
            tracker = PageRankr::Ranks::Google.new(url2write)
            prval = tracker.run;
            if (!prval.nil?) && (prval > 0)
              pr2write = prval
            end
          rescue  Exception => e
            print "  !!! generate_eventurl_and_rank(): #{e}\n"
            next
          end
          
          #write to file
          print "#{evt.id}\t#{url2write}\t#{pr2write}\n"
          outf.puts "#{evt.id}\t#{url2write}\t#{pr2write}"
          outf.flush
        end   # if yago      
        evt = nil
      end  #event loop
    end  #file open
  end  # task end

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
