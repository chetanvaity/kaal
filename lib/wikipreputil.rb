# encoding: UTF-8
require 'nokogiri'
require 'fileutils'
require 'singleton'

class WikiprepUtil
  include Singleton

  def initialize
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
end
