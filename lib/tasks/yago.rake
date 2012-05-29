# encoding: UTF-8

require 'util.rb'
require 'yagoutil.rb'

namespace :yago do
  desc "Add events from YAGO file from given line#"
  task :add_events, [:yago_file, :start_line] => :environment do |t, args|
    yf = args.yago_file
    sl = args.start_line.to_i
    
    yu = YagoUtil.instance
    i=0
    open(yf).each_line do |line|
      i=i+1
      if i < sl
        next
      end
      (title, date) = yu.get_title_date_from_line(line, nil, nil)
      next if title.nil?
      p "num=#{i}: title=#{title}, date=#{date}"
      begin
        # Event.create!(:title => title, :date => date) if not yu.event_exists?(date, title)
        Event.create!(:title => title, :date => date)
      rescue Exception => e
        p "ERROR adding event: num=#{i}: title=#{title}, date=#{date}: #{e}"
      end
    end
  end

  desc "Convert YAGO ASCII file to UTF-8"
  task :convert2utf, [:yago_file] do |t, args|
    yu = YagoUtil.instance

    yfname = args.yago_file
    utf8fname = yfname + ".utf8"
    open(utf8fname, "w:UTF-8:UTF-8") do |utf8f|
      open(yfname).each_line do |line|
        utf8f.puts(yu.ascii2utf8(line))
      end
    end
  end

end # namespace :yago
