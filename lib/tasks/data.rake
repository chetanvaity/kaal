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
  
  desc "Populate default admin user"
  task :populate_admin_user  => :environment do
    admin_email = "kp@ap.cv"
    admin_auth_provider = "default"
    admin = User.find_by_authprovider_and_email(admin_auth_provider,admin_email)
    if admin.nil?
      admin = User.create!(name: "KaalPurush",
                   email: "kp@ap.cv",
                   authprovider: "default",
                   password: "kpapcv_qaz_123",
                   password_confirmation: "kpapcv_qaz_123")
      admin.toggle!(:isadmin)
      admin.authuid = admin.id
      admin.save
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


  desc "Read event db, generate imgURL if not present, and save it."
  task :generate_imgurl, [:start_event_id, :end_event_id] => :environment do |t, args|
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
    
    util = Util.instance
    evtcounter = 0;
    Event.find_each(:start => start_eve_id) do |evt|
      #Let's stop processing if we have already crossed end_event_id condition
      if evt.id > end_eve_id
        break;
      end
      
               
      #
      #handling for events from 'yago'
      #
      if evt.source == 'yago'
        if !evt.imgurl.blank?
          #No need to do anything. skip it
          next
        end
        
        if evt.url.blank?
          #This event does not have its page url. So we can't get image url. skip it.
          next
        end
        
        #
        # Generate image url
        #
        imgurl2write = util.get_wikipage_image_url(evt.url)
        if imgurl2write.nil? or imgurl2write.blank?
          next
        end
        puts "For evtid #{evt.id}, we got => #{imgurl2write}"
        
        #imgurl2write = Event.sanitize(imgurl2write)
        
        evt.imgurl = imgurl2write
        begin
          evt.save
        rescue  Exception => e
          print "  !!! generate_imgurl(): #{e}\n"
        end
        evtcounter += 1
        
      end   # if yago   
      
      if evtcounter == 100
        puts "================================="
        puts "AMOL: Completed up to evetid #{evt.id}"
        evtcounter = 0;
      end   
    end  #event loop

  end  # task end
  
  
  desc "Polish image urls and write to output file"
  task :polish_imageurls, [:nullout_file, :correctout_file, :start_event_id, :end_event_id, :check_img] => :environment do |t, args|
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
    
    util = Util.instance
    evtcounter = 0;
    img_exists_check = false
    if !args.check_img.blank? && args.check_img == "true"
      img_exists_check = true
    end 
    out_delim = "     "
    
    File.open(args.nullout_file, "w:UTF-8:UTF-8") do |nulloutf|
      File.open(args.correctout_file, "w:UTF-8:UTF-8") do |correctoutf|
        Event.find_each(:start => start_eve_id) do |evt|
          
          
          #Let's stop processing if we have already crossed end_event_id condition
          if evt.id > end_eve_id
            break;
          end
          #
          #handling for events from 'yago'
          #
          if evt.source == 'yago'
            if !evt.imgurl.blank?
            
              if evtcounter == 100
                puts "================================="
                puts "AMOL: evetid #{evt.id} is under processing"
                evtcounter = 0;
              end
            
              evtcounter += 1
              
              begin
                # Case 1
                if evt.imgurl.end_with?("/")
                  # ur lwithout any file name
                  puts "#{evt.id} : Processed for NULL"
                  nulloutf.puts "#{evt.id}"
                  nulloutf.flush
                  next
                end
                
                tmparr = evt.imgurl.split("/")
                last_token = tmparr[tmparr.length - 1]
                
                # Case 2
                if last_token.start_with?("%")
                  #This seems to be useless url for us.
                  puts "#{evt.id} : Processed for NULL"
                  nulloutf.puts "#{evt.id}"
                  nulloutf.flush
                  next
                end
                
                
                url2write = evt.imgurl
                modurl_flag = false
                
                # Case 3
                if last_token.start_with?("[[")
                  str2use = nil
                  if last_token.start_with?("[[File:")
                    str2use = last_token.split("[[File:")[1]
                  elsif last_token.start_with?("[[Image:")
                    str2use = last_token.split("[[Image:")[1]
                  end
                  if !str2use.nil?
                    changed_token = str2use.split("%")[0]
                    
                    mod_filename = changed_token.split("]")[0]
                    url2write = util.helper_get_wiki_infobox_image_url(mod_filename, true)
                    modurl_flag = true
                    
                    if img_exists_check == false
                      print "#{evt.id}: #{url2write}\n"
                      correctoutf.puts "#{evt.id}#{out_delim}New:#{url2write}#{out_delim}Old:#{evt.imgurl}"
                      correctoutf.flush
                      next
                    end
                  end
                else
                  token2use = nil
                  if !last_token.index(".JPG%").nil?
                    token2use = last_token.split(".JPG")[0] + ".JPG"
                  elsif !last_token.index(".jpg%").nil?
                    token2use = last_token.split(".jpg")[0] + ".jpg"
                  elsif !last_token.index(".Jpg%").nil?
                    token2use = last_token.split(".Jpg")[0] + ".Jpg"
                  end
                  if !token2use.nil?
                    url2write = util.helper_get_wiki_infobox_image_url(token2use, true)
                    modurl_flag = true
                    
                    if img_exists_check == false
                      print "#{evt.id}: #{url2write}\n"
                      correctoutf.puts "#{evt.id}#{out_delim}New:#{url2write}#{out_delim}Old:#{evt.imgurl}"
                      correctoutf.flush
                      next
                    end
                  end
                end
                
                if img_exists_check == false
                  next
                end
                
                # check if it is image and is accessible
                if util.remote_imagefile_exists?(url2write)
                  if modurl_flag == true
                    print "#{evt.id}: #{url2write}\n"
                    correctoutf.puts "#{evt.id}#{out_delim}New:#{url2write}#{out_delim}Old:#{evt.imgurl}"
                    correctoutf.flush
                  end
                  
                  next
                end
                
                # The url that we have, is not accessible. See if alternate url is accessible.
                newurl2write = url2write.sub("/commons/", "/en/")
                if util.remote_imagefile_exists?(newurl2write)
                  print "#{evt.id}: #{newurl2write}\n"
                  correctoutf.puts "#{evt.id}#{out_delim}New:#{newurl2write}#{out_delim}Old:#{evt.imgurl}"
                  correctoutf.flush
                else
                  # None of the generated urls are accessible at this moment.
                  # Hence giving benefit of doubt to 'commons' url if we have generated it.
                  #
                  if modurl_flag == true
                    print "#{evt.id}: Accepted though not accessible: #{url2write}\n"
                    correctoutf.puts "#{evt.id}#{out_delim}New:#{url2write}#{out_delim}Old:#{evt.imgurl}"
                    correctoutf.flush
                  else
                    print "#{evt.id}: existing NOT REACHABLE: #{url2write}\n"
                  end
                end
                
              rescue Exception => e
                print "  !!! polish_imgurl(): #{e}\n"
                next
              end
              
              
            end
          end   # if yago
                
        end  #event loop
      end #correct file open  
    end  #null file open
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
