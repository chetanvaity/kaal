# encoding: UTF-8

require 'date'

class Event < ActiveRecord::Base
  has_many :tags, :dependent => :destroy
  # Look at http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html
  accepts_nested_attributes_for :tags, :allow_destroy => true

  validates :title, :length => {
    :maximum => 256,
    :minimum => 3
  }
  validates :title, :format => {
    :with => /[a-zA-Z]/,
    :message => "must contain some letters"
  }
  validates :title, :presence => true

  validates_associated :tags
  

  # Virtual attribute - date_str for user-friendly date display and entry
  # See http://railscasts.com/episodes/32-time-in-text-field?view=asciicast
  # Getter for date_str virtual attribute
  def date_str
    Date.jd(self.jd).strftime("%B %d, %Y")
  end

  # Setter for date_str virtual attribute
  def date_str=(s)
    self.jd = Date.parse(s).jd
  rescue ArgumentError
    @date_str_invalid = true
  end

  def validate
    errors.add(:jd, "is invalid") if @date_str_invalid
  end
end
