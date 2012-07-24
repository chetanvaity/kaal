# encoding: UTF-8
require 'nokogiri'
require 'fileutils'
require 'singleton'
require 'logger'

class WikiprepUtil
  include Singleton

  def initialize
    @log = Logger.new("/home/chetanv/source/kaal/log/wikipreputil.log",
                      "monthly") 
    @log.level = Logger::INFO
    @log.info "initialize(): -----"

    @enwiki_dir = "/media/My Passport/timeline/en-wiki/articles"
    @articles_map = {} # article name -> wikipedia id
    @idmap_file = @enwiki_dir + "/idmap.txt"
    @catgraph_file = @enwiki_dir + "/catgraph.txt"

    #open(@idmap_file).each_line do |line|
    #  terms = line.chomp.split("\t")
    #  @articles_map[terms[0]] = terms[1]
    #end
    #@log.info "initialize(): done reading #{@idmap_file}"
  end

  # from the articles map (idmap.txt), get id for this article
  # The title is the human readable string
  # return nil if not found
  def get_article_id(title)
    return @articles_map[title]
  end

  # Read the wikiprep hgw.xml file and seperate it into article files
  # Also make a title->id mapping and write it to idmap file
  def make_pages(fname, outdir)
    reader = Nokogiri::XML::Reader(File.open(fname)) # encoding?
    File.open(outdir + '/idmap.txt', "w") do |idmapf|
      i = 0
      id = nil
      reader.each do |node|
        if node.name == "page" &&
            node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
          id = node.attribute("id")
          print "##{i}: id=#{id}\n"
          (prefix1, prefix2) = make_path_prefix(id)
          deep_dir = outdir + "/" + prefix1 + "/" + prefix2
          FileUtils.mkdir_p(deep_dir)
          File.open(deep_dir + '/' + id + ".xml", "w") do |of|
            of.puts(node.inner_xml)
          end
          i=i+1
        end
        if node.name == "title" &&
            node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
          idmapf.puts(node.inner_xml + "\t" + id)
        end
      end # reader.each
    end
  end

  # Similar to above - but this works on the en-wiki file
  # which has not been passed thru wikiprep
  def make_pages2(fname, outdir)
    reader = Nokogiri::XML::Reader(File.open(fname)) # encoding?
    idmapf = File.open(outdir + '/idmap.txt', "w")

    i = 0
    page_id = nil
    page_text = nil
    page_title = nil
    reader.each do |node|
      if node.name == "page" &&
          node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        page_text = node.inner_xml
      end
      if node.name == "title" &&
          node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        page_title = node.inner_xml
      end
      if node.name == "id" &&
          node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        page_id = node.inner_xml if page_id == nil 
      end

      if node.name == "page" &&
          node.node_type == Nokogiri::XML::Reader::TYPE_END_ELEMENT
        print "##{i}: id=#{page_id}: title=#{page_title}\n"
        idmapf.puts(page_title + "\t" + page_id)
        (prefix1, prefix2) = make_path_prefix(page_id)
        deep_dir = outdir + "/" + prefix1 + "/" + prefix2
        FileUtils.mkdir_p(deep_dir)
        File.open(deep_dir + '/' + page_id + ".xml", "w") do |of|
          of.puts(page_text)
        end
        i=i+1
        page_id = nil
        page_text = nil
        page_title = nil
      end

    end # reader.each
  end

  # Create a string, return prefix of dirs
  #  Given 546793287, return (54, 67)
  #  Given 35, return (00, 35)
  def make_path_prefix(id_str)
    len = id_str.size
    raise Exception "id_str is zero length" if len == 0

    case len
    when 1
      s = "000" + id_str
    when 2
      s = "00" + id_str
    when 3
      s = "0" + id_str
    else
      s = id_str
    end
    
    return [s[0,2], s[2,2]]
  end

  # Get text from an article file
  def get_tags_n_text_from_article(article_id)
    s = resolve_redirects_n_read(article_id)
    return [[], nil] if s.nil?

    s = "<article>" + s + "</article>"
    reader = Nokogiri::XML::Reader(s)
    text = ""
    reader.each do |node|
      if node.name == "text" &&
          node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        text = node.inner_xml
      end
    end

    # Lets get only the stuff till the first subsection "=="
    #summary_text = text.gsub /^==.*/m, ''

    # Remove headings
    text.gsub! /\=\=\=\=.*?\=\=\=/, ''
    text.gsub! /\=\=\=.*?\=\=\=/, ''
    text.gsub! /\=\=.*?\=\=/, ''
    # Remove references
    text.gsub! /&lt;ref&gt;.*?&lt;\/ref&gt;/, ''
    text.gsub! /&lt;ref;.*?&gt;/, ''
    text.gsub! /&lt;ref.*?&gt;/, ''
    # Remove all Category links
    text.gsub! /\[\[Category:.*?\]\]/, ''
    # Remove everything between &lt; and &gt;
    text.gsub! /&lt;.*?&gt;/, ''
    # Remove this crappy nowrap markup
    text.gsub! /{{nowrap end}}}}/, ''
    # Remove everything in {{ }} - citation/references
    text.gsub! /{{.*?}}/, ''
    # Remove everything in  {{ ^}} - Infobox
    text.gsub! /{{Infobox.*?^}}/m, ''
    text.gsub! /{{Persondata.*?^}}/m, ''
    # Convert [[Alps|Alpine]] to [[Alpine]]
    text.gsub! /\[\[[^\[]*?\|(.*?)\]\]/, '[[\1]]'
    # Get tags - all stuff which is in [[ ]]
    link_tags = text.scan /\[\[(.*?)\]\]/
    # get the strings out of the arrays
    link_tags.map! { |e| e[0] }
    # Remove tags which have "|" or "[" or "]"
    link_tags.reject! { |e| e =~ /\||\[|\]/}
    # Convert all tags to lowercase
    link_tags.map! { |e| e.downcase }
    
    # Convert [[Alpine]] to Alpine
    text.gsub! /\[\[(.*?)\]\]/, '\1'
    # Remove '''  '''
    text.gsub! /\'\'\'(.*?)\'\'\'/, '\1'
    # Remove ''  ''
    text.gsub! /\'\'(.*?)\'\'/, '\1'
    # Remove " and *
    text.gsub! /"|\*/, ''
    # Remove ( )
    text.gsub! /\(|\)/, ''
    # Remove anything with [ ] - usually links etc
    text.gsub! /\[.*?\]/, ''
    # Remove any remaining }}
    text.gsub! /}}/, ''

    # Replace newlines with spaces
    text.gsub! /\n/, ' '

    return link_tags, text
    
    rescue Exception => e
    print "  !!! get_tags_n_text_from_article(): #{e}\n"
    return [[], nil]
  end

  # Given a article id, resolve redirects till an actual article file
  # return the contents of the resolved file
  def resolve_redirects_n_read(id)
    (prefix1, prefix2) = make_path_prefix(id)
    fname = @enwiki_dir + "/" + prefix1 + "/" + prefix2 + "/#{id}.xml"
    s = File.open(fname, "r:UTF-8").read
    if s =~ /#REDIRECT \[\[(.*?)\]\]/
      # If there is a "#" in the redirect title, remove stuff after it
      new_title = $1.gsub /#.*/, ''
      # Get article id for the new title
      new_id = get_article_id(new_title)
      return nil if new_id.nil?
      resolve_redirects_n_read(new_id)
    else
      return s
    end
  end

  # Return resolved id
  # level is the recursion level - to come out of cycles
  def resolve_redirects(id, level)
    return nil if level > 5
    
    (prefix1, prefix2) = make_path_prefix(id)
    fname = @enwiki_dir + "/" + prefix1 + "/" + prefix2 + "/#{id}.xml"
    s = File.open(fname, "r:UTF-8").read
    if s =~ /#REDIRECT \[\[(.*?)\]\]/
      # If there is a "#" in the redirect title, remove stuff after it
      new_title = $1.gsub /#.*/, ''
      # Get article id for the new title
      new_id = get_article_id(new_title)
      return nil if new_id.nil?
      return resolve_redirects(new_id, level+1)
    else
      return id
    end
  end

  # Use Stanford's Parser tool to get nouns from the txt
  # Assume that the Parser server is running on port 2020
  # java -mx300m -cp stanford-postagger-2012-07-09.jar edu.stanford.nlp.tagger.maxent.MaxentTaggerServer -model "models/wsj-0-18-left3words.tagger" -port 2020  -outputFormat tsv
  def get_parser_response(para)
    para.gsub! /\n/, '.' # Remove newlines
    para += "\n" # add one at the end
    socket = TCPSocket.open('localhost', 2020)
    socket.set_encoding("UTF-8")
    socket.print(para)
    return socket.read
  end

  # Return a list of tags by parsing the response
  # Also downcase all nouns
  def get_nouns_from_parser_response(s)
    nouns = []
    noun = ""
    s.each_line do |line|
      (word, pos) = line.split
      next if word =~ /\|/
      if pos =~ /NN/
        if noun == ""
          noun = word
        else
          noun += " " + word
        end
      else
        nouns.push(noun) unless noun == ""
        noun = ""
      end
    end
    nouns.map! { |n| n.downcase }
    # Remove the language versions of the title found in the wiki text page
    nouns.reject { |n| n =~ /\saf$|\sam$|\sar$|\sast$|\saz$|\sbn$|\sbe$|\sbg$|\sbs$|\sbr$|\sca$|\scs$|\scy$|\sda$|\sde$|\set$|\sel$|\ses$|\seo$|\seu$|\sfa$|\shif$|\sfo$|\sfr$|\sfy$|\sgl$|\sgu$|\sko$|\shi$|\shr$|\sio$|\sid$|\sia$|\sis$|\sit$|\shy$|\she$|\sjv$|\skn$|\ska$|\skk$|\ssw$|\sku$|\sky$|\sla$|\slv$|\slb$|\slt$|\shu$|\smk$|\sml$|\smr$|\sms$|\smn$|\smy$|\sml$|\sne$|\snew$|\sja$|\sno$|\snn$|\snl$|\soc$|\spnb$|\snds$|\spl$|\spt$|\sro$|\squ$|\sru$|\ssa$|\ssco$|\ssq$|\ssi$|\ssimple$|\ssk$|\ssl$|\ssr$|\ssh$|\sfi$|\ssv$|\stl$|\sta$|\ste$|\sth$|\str$|\suk$|\sur$|\svi$|\swar$|\syo$|\sbat$|\szh$/ }
  end

  #
  def get_nouns_from_article_txt(txt_file)
    all_nouns = []
    open(txt_file).each_line do |line|
      line.gsub! /\s\s/, ' - '
      response = get_parser_response(line)
      nouns = get_nouns_from_parser_response(response)
      all_nouns = all_nouns + nouns
    end
    return all_nouns

    rescue Exception => e
    print "  !!! get_nouns_from_article_txt(): #{e}\n"
    return nil
  end

  # ---- Category related -----

  # For a given article, extract the categories it belongs to
  # Return nil if article not found
  def extract_categories(title)
    # First find the article_id
    article_id = get_article_id(title)
    return nil if article_id.nil?
    
    (prefix1, prefix2) = make_path_prefix(article_id)
    fname = @enwiki_dir + "/" + prefix1 + "/" + prefix2 + "/#{article_id}.xml"
    catlist = []
    open(fname).each_line do |line|
      if line =~ /\[\[(Category:.*?)\]\]/
        # Remove stuff after "|" if any
        cat_title = $1.gsub /\|.*/, ''
        cat_article_id = get_article_id(cat_title)
        catlist.push(cat_article_id) if not cat_article_id.nil?
      end
    end
    return catlist
  end

  # Go thru idmap.txt and write a category graph file
  # by reading all category article files
  def make_catgraph()
    File.open(@catgraph_file, "w") do |catgraphf|
      i = 0
      @articles_map.keys.each do |title|
        print "Count = #{i}\n"
        if title =~ /Category:/
          cats = extract_categories(title)
          cats_str = ""
          cats.each { |c| cats_str += " #{c}" }
          catgraphf.puts("#{@articles_map[title]}: #{cats_str}")
        end
        i=i+1
      end
    end
  end

end
