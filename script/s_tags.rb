#!/usr/bin/env ruby
# encoding: UTF-8

ARGV.each do|a|
  puts "Argument: #{a}"
end

File.open(ARGV[1], "w:UTF-8:UTF-8") do |outf|
  open(ARGV[0], "r:UTF-8:UTF-8").each_line do |line|
    arr = line.chomp.split(/:/)
    event_id = arr[0]
    tags_str = arr[1]
    next if tags_str.nil?
    tags = tags_str.split(/,/).reject {|t| t.length == 0}
    tags.each do |t|
      t.gsub!(/,/, " ")
      outf.puts "#{event_id},#{t}"
    end
  end
end

