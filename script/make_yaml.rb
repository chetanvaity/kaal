#!/usr/bin/env ruby

#
# Generate events which llike this:
#
#  #e-wiki-1968-0
#  - title: Birth - Davor Suker, Croatian soccer footballer 
#    date: 1968-01-01
#    tags: Davor Suker
#
#  #e-wiki-1968-1
#  - title: Birth - Cuba Gooding Jr., American actor 
#    date: 1968-01-02
#    tags: Cuba Gooding Jr.
#

require 'optparse'
require 'date'

# Get date from a string like:
# "* January 3 &ndash; Apple Computer Inc. is incorporated. <<Tags=[[Apple Computer]]>>" -> Jan 1
# "* January &ndash; The world's first personal all-in-one computer" -> Jan 1
# "** Mount Nyiragongo erupts in eastern Zaire " -> nil
# "* January 18" -> Jan 18
def get_date_title_tags(str, year)
  months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
  arr = str.split
  return nil if !months.include? arr[1]
  
  if arr[2] =~ /\d+/
    day_of_month = $&
  else
    day_of_month = 1
  end

  s = "#{arr[1]} #{day_of_month} #{year}"
  d = Date.strptime(s, '%B %e %Y') # See http://snippets.dzone.com/posts/show/2255

  # Now get the title
  if str =~ /&amp;ndash; (.*?)<<Tags/
    title = $1
  elsif str =~ /&ndash; (.*?)<<Tags/
    title = $1
  elsif str =~ /\*\* (.*)<<Tags/
    title = $1
  else
    title = nil
  end

  # Now the tags
  if str =~ /<<Tags=(.*?)>>/
    tags_str = $1
    tags = tags_str.gsub(/\]\]\[\[/, ',').gsub(/\[\[/, '').gsub(/\]\]/, '')
  else
    tags = nil
  end

  return [d, title, tags]
end

options = {}
 
optparse = OptionParser.new do |opts|
  opts.banner = <<-EOS
Given a cleaned up wikipedia year page dump file, create a YAML file of events
This script should be run after seperate_sections.rb and clean_markup.rb have been run.
  
Usage: make_yaml.rb -f FILE
  EOS
  options[:filename] = nil
  opts.on( '-f', '--filename FILE', 'File to be processed' ) do |f|
    options[:filename] = f
  end
  opts.on( '-h', '--help', 'Display this message' ) do
    puts opts
    exit
  end
end

optparse.parse!

abort "ERROR: file to be processes not specified" if options[:filename] == nil

# Get the year from the filename
if options[:filename] =~ /wiki-(\d+)/
  year = $1
else
  abort "ERROR: file must be named \"wiki-YYYY.blah\""
end

# Check if its a birth or death file
if options[:filename] =~ /births/
  title_prefix = "Birth - "
elsif options[:filename] =~ /deaths/
  title_prefix = "Death - "
else
  title_prefix = ""
end

count = 0
curr_date = nil
File.open(options[:filename]).each_line do |line|
  (d, title, tags) = get_date_title_tags(line, year)
  curr_date = d if d
  if curr_date && title
    puts "e-wiki-#{year}-#{count}"
    puts "  title: #{title_prefix}#{title}"
    puts "  date: #{curr_date}"
    puts "  tags: #{tags}"
    puts
    count = count + 1
  end
end
