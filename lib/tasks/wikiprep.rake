# encoding: UTF-8

require 'util.rb'
require 'wikipreputil.rb'

namespace :wikiprep do
  desc "Read the wikiprep hgw.xml file and create article files"
  task :create_articles, [:wikiprep_file,:out_dir] do |t, args|
    wu = WikiprepUtil.instance
    wpfname = args.wikiprep_file
    outdir = args.out_dir

    wu.make_pages2(wpfname, outdir)    
  end

  desc "For all events, populate URL with wikipedia page and populate wiki_id"
  task :populate_url_wiki_id, [:start_event] => :environment do |t, args|
    se = args.start_event.to_i
    print "Starting from event id: #{se}\n"

    wu = WikiprepUtil.instance
    Event.find_each(:start => se) do |e|
      e.title =~ /(Birth:|Death:|Created:|Ended:|Started:|End:) (.*)/
      t = $&.nil? ? e.title : $2
      wiki_t = t.gsub(/ /, '_')
      url = "http://en.wikipedia.org/wiki/#{wiki_t}"
      wiki_id = wu.get_article_id(t)
      if wiki_id.nil?
        print "#{e.id}\t#{e.title}: No article found.\n"
      else
        e.wiki_id = wiki_id
      end
      e.url = url
      e.save
      if (e.id % 1000) == 0
        print "#{e.id}\t#{e.title} done\n"
      end
    end
  end

  desc "For all events, collect tags from an article XML file"
  task :collect_tags, [:start_event, :articles_dir] => :environment do |t, args|
    se = args.start_event.to_i
    print "Starting from event id: #{se}\n"

    tagf = open(args.articles_dir + "/tags.txt", "w:UTF-8")

    wu = WikiprepUtil.instance
    uu = Util.instance
    Event.find_each(:start => se) do |e|
      print "-----\n"
      print "Adding tags for event ##{e.id} #{e.title}\n"

      e.title =~ /(Birth:|Death:|Created:|Ended:|Started:|End:) (.*)/
      article_id = $&.nil? ? wu.get_article_id(e.title) : wu.get_article_id($2)
      if article_id.nil?
        print "#{e.id}\t#{e.title}: No article found.\n"
        next
      end
      print "Article wiki id: #{article_id}\n"
      
      # get tags from the links in the wikipedia text
      (link_tags, text) = wu.get_tags_n_text_from_article(article_id)
      print "Got tags from links in wiki text: #{link_tags}\n"
      # do NLP and get nouns from the wikipedia text
      nouns = text.nil? ? [] :
        uu.get_nouns_from_NLP_response(uu.get_NLP_response(text))
      nouns |= []
      print "Got tags from NLP of wiki text: #{nouns}\n"
      combined_tags = link_tags | nouns

      tags_str = ""
      combined_tags.each { |tag_str| tags_str = tags_str + tag_str + ","}
      tagf.puts("#{e.id}:#{tags_str}")

      print "tags=#{combined_tags}\n"
    end
  end

  #
  desc "Create a category graph file"
  task :make_catgraph do |t, args|
    wu = WikiprepUtil.instance
    wu.make_catgraph
  end

  # For each artcle XML file, generate a text file containing words in the article without markup
  desc "Remove markup from articles XML files"
  task :xml2txt, [:start_event, :end_event, :outdir] => :environment do |t, args|
    se = args.start_event.to_i
    ee = args.end_event.to_i
    wu = WikiprepUtil.instance
    Event.find_each(:start => se) do |e|
      abort("e.id exceeded end_event") if (e.id > ee)
      print "\nNow processing: event_id: #{e.id}\n" if (e.id % 1000) == 0
      next if e.wiki_id.nil?
      wiki_id = e.wiki_id.to_s
      (link_tags, text) = wu.get_tags_n_text_from_article(wiki_id)
      if text.nil?
        Rails.logger.info("xml2txt(): nil returned as text for event=#{e.id}, wiki_id=#{wiki_id}")
        next
      end
      (prefix1, prefix2) = wu.make_path_prefix(wiki_id)
      deep_dir = args.outdir + "/" + prefix1 + "/" + prefix2
      FileUtils.mkdir_p(deep_dir)
      File.open(deep_dir + '/' + wiki_id + ".txt", "w:UTF-8") do |of|
        of.write(text)
      end
    end
  end

  desc "Follow redirects and correct wiki_ids for all events"
  task :correct_redirected_ids, [:start_event,:end_event] => :environment do |t, args|
    se = args.start_event.to_i
    ee = args.end_event.to_i
    print "Starting from event id: #{se}\n"

    wu = WikiprepUtil.instance
    Event.find_each(:start => se) do |e|
      Rails.logger.info("correct_redirected_ids(): HELLO")
      abort("e.id exceeded end_event") if (e.id > ee)
      print "Starting with #{e.id}\n" if (e.id % 1000) == 0

      next if e.wiki_id.nil?
      resolved_id = wu.resolve_redirects(e.wiki_id.to_s, 0)
      if !(resolved_id.nil?)
        res_id = resolved_id.to_i
        if (res_id != e.wiki_id)
          print "event_id=#{e.id}, id=#{e.wiki_id}, resolved_id=#{resolved_id}\n"
          e.wiki_id = resolved_id
          e.save
        end
      end
    end
  end

  # For each article txt file, get a bag-of-words file
  # This file will consist of only nouns - got by using Stanford POS tagger
  desc "Get Bag of Words for all article TXT files"
  task :txt2bow, [:start_event, :end_event, :txtdir, :outdir] => :environment do |t, args|
    se = args.start_event.to_i
    ee = args.end_event.to_i
    wu = WikiprepUtil.instance
    Event.find_each(:start => se) do |e|
      abort("e.id exceeded end_event") if (e.id > ee)
      print "#{Time.now}: Now processing: event_id: #{e.id}\n" if (e.id % 100) == 0
      next if e.wiki_id.nil?
      wiki_id = e.wiki_id.to_s
      (prefix1, prefix2) = wu.make_path_prefix(wiki_id)
      txt_file = args.txtdir + "/" + prefix1 + "/" + prefix2 + "/" + wiki_id + ".txt"
      nouns = wu.get_nouns_from_article_txt(txt_file)
      if nouns.nil?
        Rails.logger.info("txt2bow(): nil returned as nouns for event=#{e.id}, wiki_id=#{wiki_id}")
        next
      end

      norm_nouns = []
      nouns.map { |n| norm_nouns += Tag.get_normalized_names(n) } 
      
      deep_dir = args.outdir + "/" + prefix1 + "/" + prefix2
      FileUtils.mkdir_p(deep_dir)
      File.open(deep_dir + '/' + wiki_id + ".txt", "w:UTF-8") do |of|
        of.write(norm_nouns.join("\n"))
      end
    end
  end

  desc "Adds extra_words from wiki bag of words to events"
  task :add_extra_words, [:start_event, :end_event, :bowdir] => :environment do |t, args|
    se = args.start_event.to_i
    ee = args.end_event.to_i
    wu = WikiprepUtil.instance
    Event.find_each(:start => se) do |e|
      abort("e.id exceeded end_event") if (e.id > ee)
      print "#{Time.now}: Now processing: event_id: #{e.id}\n" if (e.id % 100) == 0
      next if e.wiki_id.nil?
      wiki_id = e.wiki_id.to_s
      (prefix1, prefix2) = wu.make_path_prefix(wiki_id)
      bow_file = args.bowdir + "/" + prefix1 + "/" + prefix2 + "/" + wiki_id + ".txt"
      begin
        s = open(bow_file).readlines.map { |word| word.chomp }.join('\t')
      rescue
        print "Error reading file: event_id=#{e.id}, #{bow_file}\n"
        next
      end
      e.extra_words = s
      e.save
    end         
  end

end # namespace :wikiprep
