#!/usr/bin/env ruby
# encoding: UTF-8

require 'd'

# Convert the date to Julian day number (days since Jan 1, 4713 BCE)
#
# 1       Birth - Friedrich Spanheim, Dutch theologian (d. 1649)  1600-01-01 00:00:00.000000      wiki-year
#
File.open(ARGV[1], "w:UTF-8:UTF-8") do |outf|
  open(ARGV[0], "r:UTF-8:UTF-8").each_line do |line|
    arr = line.chomp.split(/\t/)
    next if arr.length != 4
    date_str = arr[2]
    next if date_str.nil?
    p "Converting #{date_str}"
    d = Date.strptime(date_str, "%Y-%m-%d")
    outf.puts "#{arr[0]}\t#{arr[1]}\t#{d.jd}\t#{arr[3]}"
  end
end
