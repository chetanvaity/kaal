#!/usr/bin/env ruby

#
# Generate something like:
# Event.create(title: 'Chetan born', date: '03/08/1977', tags: 'personal, chetanv')
#

require 'optparse'
require 'date'
require 'yaml'

options = {}
 
optparse = OptionParser.new do |opts|
  opts.banner = <<-EOS
Given a YAML file with events, outputs a seeds.rb file.
Designed to run on the output of make_yaml.rb.
  
Usage: make_seeds.rb -f FILE
  EOS
  options[:filename] = nil
  opts.on('-f', '--filename FILE', 'YAML file to be processed' ) do |f|
    options[:filename] = f
  end
  opts.on('-h', '--help', 'Display this message' ) do
    puts opts
    exit
  end
end

optparse.parse!

abort "ERROR: file to be processed not specified" if options[:filename] == nil

yaml_obj = YAML::parse_file(options[:filename])
eventlist = yaml_obj.to_ruby

eventlist.each do |e|
  title = e['title'].gsub /:/, '-'
  puts "Event.create(title: %|#{title}|, date: %|#{e['date']}|, tags: %|#{e['tags']}|)"
end
