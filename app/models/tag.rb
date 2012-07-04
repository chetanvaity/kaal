# encoding: UTF-8

class Tag < ActiveRecord::Base
  validates :name, :presence => true
  validates :name, :length => {
    :maximum => 80,
    :minimum => 2
  }

  before_save :normalize_tag_name

  protected
  def normalize_tag_name
    self.name = Tag.get_normalized_name(self.name)
  end

  # A class method which returns normalized tag name if it exists
  # Else returns the same string that was passed
  def self.get_normalized_name(name_str)
    name_str.downcase!
    term = Babel.find_by_term(name_str)
    if term.nil?
      return name_str
    else
      return term.norm_term.term
    end
  end

end
