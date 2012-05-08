#!/usr/bin/env ruby

require 'optparse'

options = {}
 
optparse = OptionParser.new do |opts|
  opts.banner = <<-EOS
Given a wikipedia year page dump file, generate 3 files with events, births and deaths.
The wikipedia dump page can be obtained like this:
  wget -O wiki-1977.dump "http://en.wikipedia.org/w/api.php?format=xml&action=query&titles=1977&prop=revisions&rvprop=content"

Usage: seperate_sections.rb -f FILE
  EOS
  options[:filename] = nil
  opts.on( '-f', '--filename FILE', 'File to be parsed' ) do |f|
    options[:filename] = f
  end
  opts.on( '-h', '--help', 'Display this message' ) do
    puts opts
    exit
  end
end

optparse.parse!

abort "ERROR: file to be parsed not specified" if options[:filename] == nil

event_lines = []
birth_lines = []
death_lines = []

section = nil
File.open(options[:filename]).each_line do |line|
  line = line.strip
  if line[0..12] == '== Events =='
    section = :events
  elsif line[0..12] == '== Births =='
    section = :births
  elsif line[0..12] == '== Deaths =='
    section = :deaths
  end
    
  if section == :events
    event_lines.push line
  end
  if section == :births
    birth_lines.push line
  end
  if section == :deaths
    death_lines.push line
  end    
end

# Now that we have all arrays, write them to seperate files
events_file = "#{options[:filename]}.events"
births_file = "#{options[:filename]}.births"
deaths_file = "#{options[:filename]}.deaths"

open events_file, 'w' do |f|
  event_lines.each do |el|
    f.puts el
  end
end

open births_file, 'w' do |f|
  birth_lines.each do |bl|
    f.puts bl
  end
end

open deaths_file, 'w' do |f|
  death_lines.each do |dl|
    f.puts dl
  end
end

