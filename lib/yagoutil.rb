# encoding: UTF-8
require 'logger'
require 'date'
require 'singleton'

# Look at http://www.mpi-inf.mpg.de/yago-naga/yago/
# This class provides some util functions to get events from the Yago files
class YagoUtil
  include Singleton

  def initialize
    @log = Logger.new('/home/chetanv/source/kaal/log/yago_util.log', 'monthly') 
    @log.level = Logger::DEBUG
    @log.info "initialize(): -----"

    # @yago_dir = '/home/chetanv/tmp/yago/yago2core_20120109_test'
    @yago_dir = '/home/chetanv/tmp/yago/yago2core_20120109'
    @pm_map = {} # Yago preferredMeaning map

    pm_file = @yago_dir + "/hasPreferredMeaning.tsv.utf8"
    open(pm_file).each_line do |line|
      terms = line.chomp.split("\t")
      @pm_map[terms[2]] = terms[1].gsub /"/, ''
    end
    @log.info "initialize(): done reading #{pm_file}"
  end
  
  # The Yago *Date* files contain lines like 
  #   #1979709        American_Civil_War      1861-04-12
  # Extract the title of the event and the date from this line.
  # As there are files for many relationships like "wasBornOn", "wasDestroyedOn",
  # its necessary to prefix or suffix the title with some other string.
  #
  # returns both title and date
  def get_title_date_from_line(line, prefix, suffix)
    (id, entity, date_str) = line.chomp.split
    title = get_title(entity)
    title = prefix + title unless prefix.nil?
    title = title + suffix unless suffix.nil?
    date = get_date(date_str)
    return [title, date]

    rescue Exception => e
    @log.error "  !!! get_title_date_from_line(): id=#{id}, entity=#{entity}, date_str=#{date_str}: #{e}\n"
    return [nil,nil]
  end

  # Query the DB for all events on given date.
  # Check for matching "nouns" in these events to decide duplicate.
  # returns true/false
  def event_exists?(date, title)
    elist = Event.find_all_by_date(date)
    return false if elist.empty?

    Util u = Util.instance
    nouns = u.get_nouns_from_NLP_response(u.get_NLP_response(title))
    elist.each do |e|
      enouns = u.get_nouns_from_NLP_response(u.get_NLP_response(e.title))
      if not (nouns & enouns).empty?
        return true
      end
    end
    return false
  end

  # Yago entity string to readable name
  # look up in hasPreferredMeaning file
  def get_title(e)
    pm = @pm_map[e]
    return pm.nil? ? e : pm
  end

  # Convert from Yago date string to ruby date
  # Special cases:
  #   149#-##-## -> 1490-01-01
  #   1813-##-## -> 1813-01-01 
  def get_date(date_str)
    date_str.gsub! /\#\#$/, '01' # day of month
    date_str.gsub! /-\#\#-/, '-01-' # month
    date_str.gsub! /\#/, '0' # remaining # will be in year
    return Date.strptime(date_str, '%Y-%m-%d')
    
    rescue Exception => e
    print "  !!! get_date(): date_str=#{date_str}: #{e}\n"
    raise e
  end

  # Convert an ASCII string with \uXXXX into a UTF-8 string
  #   Andr\u00e9_Weil -> André_Weil
  #   W\u0142adys\u0142aw_Reymont -> Władysław_Reymont
  def ascii2utf8(line)
    while true do
      line =~ /\\u(....)/
      return line if $1.nil?
      r = [$1.to_i(16)].pack('U*')
      line.sub! /\\u(....)/, r
    end
  end
end
