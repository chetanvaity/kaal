#!/usr/bin/env ruby

require 'optparse'

def is_only_date?(str)
  months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
  s = str.gsub /[\s\[\]\d\*]/, ''
  if months.include? s
    true
  else
    false
  end
end


options = {}
 
optparse = OptionParser.new do |opts|
  opts.banner = <<-EOS
Given a wikipedia year page dump file, remove "[[]]" markup and write "tags" at end of each line
This script should be run after seperate_sections.rb has been run.
  
Usage: clean_markup.rb -f FILE
  EOS
  options[:filename] = nil
  opts.on( '-f', '--filename FILE', 'File to be cleaned up' ) do |f|
    options[:filename] = f
  end
  opts.on( '-h', '--help', 'Display this message' ) do
    puts opts
    exit
  end
end

optparse.parse!

abort "ERROR: file to be cleaned not specified" if options[:filename] == nil

# Go thru each line and cleanup all [[]] markup, remember stuff inside those brackets 
# and write them as tags at the end of the line

File.open(options[:filename]).each_line do |line|
  next if line[0] != "*"
  if is_only_date? line
    puts line.gsub /\[\[(.*?)\]\]/, '\1'
    next
  end

  # Remove everything between &lt; and &gt; with greedy match
  cline1 = line.gsub /&lt;.*&gt;/, ''

  # Remove everything between {{ and }} with greedy match
  cline2 = cline1.gsub /{{.*}}/, ''

  # Convert [[Alps|Alpine]] to [[Alpine]]
  cline3 = cline2.gsub /\[\[[^\[]*?\|(.*?)\]\]/, '[[\1]]'
  
  # Convert [[Alpine]] to Alpine
  cline4 = cline3.gsub /\[\[(.*?)\]\]/, '\1'
  
  # Get tags - all stuff which were in [[ ]]
  arr = cline3.scan /\[\[.*?\]\]/
  tags_str = " <<Tags="
  arr.drop_while {|t| is_only_date? t } .each { |t|  tags_str = tags_str + t }
  tags_str = tags_str + ">>"
  cline5 = cline4.chomp + tags_str

  puts cline5
end

