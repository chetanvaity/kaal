# encoding: UTF-8
require 'open-uri'
require 'nokogiri'
require 'iconv'
require 'socket'
require 'singleton'
require 'digest'

#Added by amol
require 'uri'
require 'net/http'
require 'rexml/document'
require 'digest/md5'
#

class Util
  include Singleton

  def initialize
  end
  
  # Get image url for a given wiki page url
  def get_wikipage_image_url(wiki_page_url)
    if wiki_page_url.blank?
      return nil
    end
    
    begin
      #get the last part of the wiki page url. That is typically title of the page
      str_arr = wiki_page_url.split('/')
      page_title = str_arr[str_arr.length - 1]
      imgurl = get_wiki_infobox_image_url(page_title)
      return imgurl
    rescue
      return nil
    end
  end
  
  #
  # This 'valid_title' is string without any spaces.
  #
  def get_wiki_infobox_image_url(valid_title)
    res_datastr = nil
    infobox_str = nil
    logoline = nil
    filename_str = nil
    logourl = nil
  
    begin
      searchurl_str = 'http://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvprop=content&format=xml&rvsection=0&titles='
      url = URI.parse(searchurl_str + valid_title + '&redirects')
      res_datastr = Net::HTTP.get(url)
    rescue
      return nil
    end
  
    begin
      doc = REXML::Document.new(res_datastr)
      doc.elements.each('api/query/pages/page/revisions/rev') do |rev|
         infobox_str = rev.text
         break
      end
    rescue
      return nil
    end
  
    infobox_str.each_line {|s| 
      #puts s
      if s.start_with?("| logo") || s.start_with?("| image")
        logoline = s
        break;
      end
    }
  
    if logoline.nil?
      return nil
    end
  
  
    begin
      if logoline.start_with?("| logo")
        str_array = logoline.split("File:")
        filename_str = str_array[1].split("|")[0].strip
      elsif
        #str_array = logoline.split("image = ")
        str_array = logoline.split("=")
        filename_str = str_array[1].strip
      end
  
      filename1 = filename_str.gsub(' ', '_')
      digest = Digest::MD5.hexdigest(filename1)
      folder = digest[0] + "/" + digest[0] + digest[1] + "/" + URI::encode(filename1);
      logourl = 'http://upload.wikimedia.org/wikipedia/commons/' + folder;
    rescue
      return nil
    end
  
    #puts "Infobox filename: " + filename_str
    return logourl
  end
  
  # IF yoiu have a valid filename, use it
  def helper_get_wiki_infobox_image_url(valid_filename, commons_flag)
    begin
      filename1 = valid_filename.gsub(' ', '_')
      digest = Digest::MD5.hexdigest(filename1)
      folder = digest[0] + "/" + digest[0] + digest[1] + "/" + URI::encode(filename1);
      if commons_flag == true
        return 'http://upload.wikimedia.org/wikipedia/commons/' + folder;
      else
        return 'http://upload.wikimedia.org/wikipedia/en/' + folder;
      end
    rescue
      return nil
    end
  end
  
  def remote_imagefile_exists?(url)
    url = URI.parse(url)
    Net::HTTP.start(url.host, url.port) do |http|
      return http.head(url.request_uri)['Content-Type'].start_with? 'image'
    end
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
    socket.set_encoding("UTF-8")
    socket.print(para)
    return socket.read
  end

  # Return a list of tags by parsing the NLP response
  # Also downcase all nouns
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
    return nouns.map! { |n| n.downcase }
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
    nouns_u = nouns.map! { |n| n.gsub /\ /, '_' } # replace spaces with "_"
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

  # Get a unique key string from the array of parameters
  # This array is the params which includes tags and from, to etc.
  # The query_key is used to create a unique JSON file
  # Also used for cacheing query results
  def get_query_key(from_jd, to_jd, tags, events_on_a_page)
    f_jd_str = from_jd.nil? ? "nil" : from_jd.to_s
    t_jd_str = to_jd.nil? ? "nil" : to_jd.to_s
    return Digest::MD5.hexdigest("#{f_jd_str}-#{t_jd_str}-#{tags}-#{events_on_a_page}")
  end
  
  #
  # USing given set of events and filename, create ouput jason
  #
  def make_json(events, json_fname, query_str, from_jd, to_jd, cover_img_url)
    # Make nice looking main frame for the timeline
    # Drop the tokens begining with '@'
    headline_str = query_str.split.delete_if {|t| t[0] == '@'}.join(' ')
    headline = ActiveSupport::JSON.encode(headline_str.titlecase)
    if (from_jd.nil? or to_jd.nil?)
      text = " "
    else
      text = "Events from " + Date.jd(from_jd).strftime("%d %b %Y") + " - " +
        Date.jd(to_jd).strftime("%d %b %Y")
    end
    
    title_img_url = nil;
    if !cover_img_url.nil? && !cover_img_url.blank?
      title_img_url = URI::encode(cover_img_url)
    end

    header_json = <<END
{"timeline":
  {
  "headline":#{headline},
  "headImgUrl":"#{title_img_url}",
  "type":"default",
  "startDate":"2011,9,1",
  "text":"#{text}",
  "date": [
END

    date_json_array = []
    events.each do |e|
      d = Date.jd(e.jd).strftime("%m/%d/%Y")
      text = e.desc.blank? ? " " : e.desc
      text = ActiveSupport::JSON.encode(text)
      title = ActiveSupport::JSON.encode(e.title)
      media_url = e.url
      media_caption = e.url
      cur_imgurl = nil
      if !e.imgurl.nil?  &&  !e.imgurl.blank?
        cur_imgurl = URI::encode(e.imgurl)
      end

      date_json = <<END
        {
        "startDate":"#{d}",
        "headline":#{title},
        "text":#{text},
        "id":"#{e.id}",
        "importance":"#{e.importance}",
        "imgurl":"#{cur_imgurl}",
        "asset":
          {
          "media":"#{media_url}",
          "credit":"",
          "caption":"#{media_caption}"
          }
        }
END
      date_json_array.push(date_json)
    end
    all_date_json = date_json_array.join(",\n")
    
    footer_json = <<END
        ]
    }
}
END
    
    File.open(json_fname, "w") do |f|
      f.puts(header_json)
      f.puts(all_date_json)
      f.puts(footer_json)
    end
  end
  

end
