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
    self.jd = Date.parse(s).jd
  rescue ArgumentError
    @date_str_invalid = true
    @bad_date_str = s
  end

  def date_str_validate
    errors.add(:date_str, "^Date (" + @bad_date_str + ") is invalid") if @date_str_invalid
  end
  ### end virtual attribute - date_str



end
