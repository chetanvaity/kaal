# encoding: UTF-8
require 'open-uri'
require 'nokogiri'
require 'iconv'
require 'socket'
require 'singleton'

class Util
  include Singleton

  def initialize
    @babel_synsets_file = '/usr/local/share/mod-babel-synsets.txt'
    @babel_map = {}
    @babel_synsets = []
    init_babel(@babel_synsets_file)
  end
  
  # Fire a Google query on the first sentence of title and check if there is
  # a Wikipedia page in the first 10 results
  # Returns nil if no page found
  def get_relevant_wiki_link(query)
    q = query
    q.gsub! /[^[:alnum:]]/, ' '
    q.gsub! /\ /, '+'
    q = URI.encode(q)
  
    html = open("http://www.google.com/search?q=#{q}", "r:ISO-8859-1:UTF-8")

    # Read the html into a string
    html_str = html.read.encode("UTF-8")
    doc = Nokogiri::HTML(html_str)
    doc.encoding = 'utf-8'
    doc.css('h3.r a').each do |link|
      href = link['href']
      #p "href1 = #{href}"
      if href =~ /%25/ 
        href = URI.decode(href)
      end
      #p "href2 = #{href}"
      href =~ /(http:\/\/en.wikipedia.org.*?)[&>]/
      return $1 unless $1.nil? 
    end
    return nil
  end

  # Extract the first sentence from a given string
  def get_first_sentence(title)
    parts = title.split(/[\.\:;\(]/)
    parts[0]
  end

  # Get the wiki page and extract the first para (assumed to be summary)
  def get_wiki_para(link)
    page = Nokogiri::HTML(open(link))
    return nil if page.nil?
    para = page.css('div#mw-content-text p')[0] # First para in the content
    if para.nil?
      return nil
    else
      return para.inner_text
    end
  end

  # Use Stanford's NLP tool to get nouns from the para
  # Assume that the NLP server is running on port 1111
  # java -cp ./stanford-ner-2012-04-07.jar -mx1000m edu.stanford.nlp.ie.NERServer -loadClassifier classifiers/english.conll.4class.distsim.crf.ser.gz -port 1111
  def get_NLP_response(para)
    para.gsub! /\n/, '.' # Remove newlines
    para += "\n" # add one at the end
    socket = TCPSocket.open('localhost', 1111)
    socket.print(para)
    return socket.read
  end

  # Return a list of tags by parsing the NLP response
  def get_nouns_from_NLP_response(s)
    s = s.gsub /ORGANIZATION/, 'NOUN'
    s = s.gsub /LOCATION/, 'NOUN'
    s = s.gsub /PERSON/, 'NOUN'
    s = s.gsub /MISC/, 'NOUN'

    nouns = []
    noun = ""
    s.split.each do |term|
      if term =~ /(.*?)\/NOUN/
        if noun == ""
          noun = $1
        else
          noun += " " + $1
        end
      else
        nouns.push(noun) unless noun == ""
        noun = ""
      end
    end
    return nouns
  end

  #----- Babelnet related functions -----

  # Read the babelnet synset file and write a modified version
  # Remove non-english Babelnet entries
  # Convert all to lowercase and then remove duplicate terms
  # Also remove synsets with only one entry
  def mod_babelnet(fname, mod_fname)
    open(mod_fname, 'w') do |mf|
      open(fname).each_line do |line|
        en_tokens = line.split.select { |t| t =~ /^EN:/ }
        tokens = en_tokens.map { |t| t.gsub /^EN:/, '' }
        tokens.map! { |t| t.downcase }
        tokens.uniq!
        if tokens.length > 1
          mf.puts(tokens.join " ")
        end
      end
    end
  end
  
  # Read the modified babel synsets file
  # and initialise a Map and an Array
  #   Map: term -> synset number
  #   Array: synsets[]
  def init_babel(mod_fname)
    i = 0
    open(mod_fname).each_line do |line|
      terms = line.split
      @babel_synsets.push terms
      terms.each { |t| @babel_map[t] = i }
      i = i+1
    end
  end


  # Return the array of synonymous terms for a given term
  def get_synset(term)
    i = @babel_map[term.downcase]
    if i.nil?
      return [term]
    else
      return @babel_synsets[i]
    end
  end
 
  #----- End Babelnet related functions -----

  # Get tags for an event title
  def get_more_tags(title)
    print "  title = #{title}\n"
    title_nouns = get_nouns_from_NLP_response(get_NLP_response(title))

    link = get_relevant_wiki_link(get_first_sentence title)
    return title_nouns if link.nil?
    print "  link = #{link}\n"
    
    wiki_para = get_wiki_para(link)
    return title_nouns if wiki_para.nil?
    #print "  wiki_para = #{wiki_para}"
    nlp_response = get_NLP_response(wiki_para)
    #print "  NLP reponse = #{nlp_response}"
    nouns = get_nouns_from_NLP_response(nlp_response)
    nouns_u = nouns.map! { |n| n.gsub /\ /, '_' } # replace spaces with underscores
    expanded_nouns = []
    nouns_u.each do |n|
      ss = get_synset(n)
      expanded_nouns += ss unless ss.nil?
    end
    expanded_nouns.map! { |n| n.gsub /_/, ' ' }    
    final_nouns = expanded_nouns + title_nouns

    print "  final_nouns = #{final_nouns}\n"
    return final_nouns
    
    rescue Exception => e
    print "  !!! get_more_tags(): #{e}\n"
    return []
  end
  
end
