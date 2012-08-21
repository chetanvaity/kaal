# encoding: UTF-8

require 'date'

class Event < ActiveRecord::Base
    
  has_many :tags, :dependent => :destroy
  # Look at http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html
  accepts_nested_attributes_for :tags, :allow_destroy => true

  # Validation for title
  validates :title, :presence => true
  validates :title, :length => {
    :maximum => 256,
    :minimum => 3
  }
  validates :title, :format => {
    :with => /[a-zA-Z]/,
    :message => "must contain some letters"
  }

  # Validation for date
  validate :date_str_validate

  # Validation for desc
  validates :desc, :length => {
    :maximum => 2048
  }

  # Validation for url
  validates :url, :format => {
    :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix,
    :message => '^URL (%{value}) is invalid'
  }, :allow_blank => true

  # Validation for tags
  validates_associated :tags
    
  ### Virtual attribute - date_str for user-friendly date display and entry
  # See http://railscasts.com/episodes/32-time-in-text-field?view=asciicast
  # Getter for date_str virtual attribute
  def date_str
    if self.jd.nil?
      return ""
    else
      Date.jd(self.jd).strftime("%B %d, %Y")
    end
  end

  def date_str=(s)
    self.jd = Event.parse_date(s).jd
  rescue ArgumentError
    @date_str_invalid = true
    @bad_date_str = s
  end

  def date_str_validate
    errors.add(:date_str, "^Date (" + @bad_date_str + ") is invalid") if @date_str_invalid
  end
  ### end virtual attribute - date_str

  ### virtual attributes - score, importance (used when treating event as a search result)
  # score is as returned by Solr
  # importance is 1 or 2 or 3 - depending on the relative importance in the search results
  attr_accessor :score
  attr_accessor :importance
  ### end virtual attribute - score, importance

  # A class method to parse a string into a date
  # Raises exception if we cannot convert the given string
  def self.parse_date(s)
    dateformats = ['%d*%b*%Y', # 15 Aug 1947
                   '%d*%B*%Y', # 15 August 1947
                   '%b*%d*%Y', # Aug 15 1947
                   '%B*%d*%Y', # August 15 1947
                   '%b*%Y',    # Dec 1755
                   '%B*%Y'     # December 1755
                  ]
    year_df = '%Y'     # Just the year (used in AD/BC handling below)

    s.strip!
    s.downcase!
    # If its just a number, append "ad" at the end
    s += " ad" if s =~ /^[0-9]+$/
 
    s.gsub!(/[\s,;:]+/, "*") # replace space,comma, etc with "*" to avoid confusion in strptime
    zero_date = Date.jd(0)

    date = zero_date
    dateformats.each do |f| 
      begin
        date = Date.strptime(s, f)
        break
      rescue ArgumentError => e
        next
      end
    end

    # Check if its a AD/BC date
    begin
      last2 = s[-2..-1]
      date = Date.strptime(s[0..-3], year_df) if last2 == "ad" or last2 == "ce"
      date = Date.strptime("-" + s[0..-3], year_df) if last2 == "bc"
      last3 = s[-3..-1]
      date = Date.strptime("-" + s[0..-4], year_df) if last3 == "bce"
    rescue
      raise ArgumentError, "Invalid year date: #{s}" if date == zero_date
    end

    # We could not convert using any of the formats
    raise ArgumentError, "Invalid date: #{s}" if date == zero_date

    return date
  end

  # A class method to assign "importance" to events in a search result
  # We note the high score and low score
  # Give importance=1 for events with score in top 20% of the (high-low) score range
  # Give importance=2 for events with score in 20%-50% of the (high-low) score range
  #
  #   |-------------------------------|
  #   ^     ^        ^                ^ 
  #  high  r1       r2               low
  def self.populate_importance(events)
    return events if events.size == 0
    high = events.max_by { |e| e.score }.score
    low = events.min_by { |e| e.score }.score
    range = high - low
    r1 = high - (range * 0.2)
    r2 = high - (range * 0.5)
    return events.each do |e|
      if e.score >= r1
        e.importance = 1
      elsif e.score >= r2
        e.importance = 2
      else
        e.importance = 3
      end
    end
  end

  #
  # search integration
  #
  searchable do
    text :title, :default_boost => 2
    text :extra_words
    text :tags, :boost => 1.5 do
      tags.map {|tag| tag.name}.join(" ")
    end
  end

end
