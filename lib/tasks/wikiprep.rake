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

  # Read a file consisting of article ids
  # For each artcle XML file, generate a text file containing words in the article without markup
  desc "Remove markup from articles XML files"
  task :xml2txt, [:article_id_file, :outdir] do |t, args|
    wu = WikiprepUtil.instance
    open(args.article_id_file).each_line do |article_title|
      print "\n"
      print "Now processing: #{article_title}..."
      article_title.chomp!.rstrip!
      article_title =~ /(Birth:|Death:|Created:|Ended:|Started:|End:) (.*)/
      t = $&.nil? ? article_title : $2
      article_id = wu.get_article_id(t)
      next if (article_id.nil?)
      print "article_id=#{article_id}"
      (link_tags, text) = wu.get_tags_n_text_from_article(article_id)
      txtf = open(args.outdir + "/" + article_id + ".txt", "w:UTF-8")
      txtf.write(text)
      print "text written."
      txtf.close
    end
  end

end # namespace :wikiprep
