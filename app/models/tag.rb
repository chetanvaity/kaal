# encoding: UTF-8

class Tag < ActiveRecord::Base
  validates :name, :presence => true
  validates :name, :length => {
    :maximum => 80,
    :minimum => 2
  }

  before_save :normalize_tag_name

  # Use memoization to keep filling this up
  @@babels_map = {}

  protected
  def normalize_tag_name
    self.name = Tag.get_normalized_names(self.name)[0]
  end

  # A class method which returns array of normalized tag names
  # Else returns the same string that was passed
  def self.get_normalized_names(name_str)
    name_str.downcase!
    
    norm_names_from_map = @@babels_map[name_str]
    if not norm_names_from_map.nil?
      return norm_names_from_map
    end

    # Cache miss
    terms = Babel.find_all_by_term(name_str)
    if terms.nil? or terms.empty?
      return [name_str]
    else
      norm_names = []
      terms.each do |term|
        n_term = term.norm_term
        if (n_term.nil?) 
          norm_names.push(name_str)
        else
          norm_names.push(n_term.term)
        end
      end
    end
    norm_names.uniq!
    @@babels_map[name_str] = norm_names
    return norm_names
  end

  # Given a query "w1 w2 w3",
  # First look for normalized name for "w1". If found, replace.
  # If not found, look for normalized name for "w1 w2"
  # and so on
  def self.get_normalized_query(query_str)
    normalized_query = ""
    curr_phrase = ""
    query_str.split.each do |w|
      curr_phrase = (curr_phrase == "") ? w : (curr_phrase + " " + w)
      norm_phrase = Tag.get_normalized_names(curr_phrase)[0]
      if norm_phrase == curr_phrase
        next
      else
        normalized_query += norm_phrase + " "
        curr_phrase = ""
      end
    end
    if curr_phrase != ""
      normalized_query += curr_phrase
    end
    return normalized_query
  end

end
