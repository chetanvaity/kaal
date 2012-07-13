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
    self.name = Tag.get_normalized_names(self.name)[0]
  end

  # A class method which returns array of normalized tag names
  # Else returns the same string that was passed
  def self.get_normalized_names(name_str)
    name_str.downcase!
    terms = Babel.find_all_by_term(name_str)
    if terms.nil? or terms.empty?
      return [name_str]
    else
      norm_names = []
      terms.each do |term|
        if (term.norm_term.nil?) || (term.norm_term.term.nil?) 
          norm_names.push(name_str)
        else
          norm_names.push(term.norm_term.term)
        end
      end
    end
    return norm_names.uniq
  end

end
