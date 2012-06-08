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

  desc "For all events in DB, check if we have a wikipedia entry"
  task :check_wikipedia_for_event, [:start_event] => :environment do |t, args|
    se = args.start_event.to_i
    print "Starting from event id: #{se}\n"

    wu = WikiprepUtil.instance
    Event.find_each(:start => se) do |e|
      e.title =~ /(Birth:|Death:|Created:|Ended:|Started:|End:) (.*)/
      article_id = $&.nil? ? wu.get_article_id(e.title) : wu.get_article_id($2)
      if article_id.nil?
        print "#{e.id}\t#{e.title}: No article found.\n"
      end
    end
  end

  desc "For all events, add tags from an article XML file"
  task :add_tags, [:start_event, :articles_dir] => :environment do |t, args|
    se = args.start_event.to_i
    print "Starting from event id: #{se}\n"

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
      
      (prefix1, prefix2) = wu.make_path_prefix(article_id)
      fname = args.articles_dir + "/" + prefix1 + "/" + prefix2 +
        "/#{article_id}.xml"

      # get tags from the links in the wikipedia text
      (link_tags, text) =  wu.get_tags_n_text_from_article(fname)
      print "Got tags from links in wiki text\n"
      # do NLP and get nouns from the wikipedia text
      nouns = text.nil? ? [] :
        uu.get_nouns_from_NLP_response(uu.get_NLP_response(text))
      print "Got tags from NLP of wiki text\n"
      combined_tags = link_tags | nouns

      combined_tags.each do |tag_str|
        # Check if the tag exists already. If not, create it
        print "Tag.find_by_name() start..."
        t = Tag.find_by_name tag_str
        print "done\n"
        print "Tag.create() start..."
        t ||= Tag.create!(:name => tag_str)
        print "done\n"
        # Now create a mapping entry
        # Tag Source: 1 = wikitext
        print "Tagmap.create() start..."
        Tagmap.create!(:event_id => e.id, :tag_id => t.id, :source => '1')
        print "done\n"
      end
      
      print "tags=#{combined_tags}\n"
    end
  end

end # namespace :wikiprep
