# Self Join
# See http://guides.rubyonrails.org/association_basics.html (Section 2.10)
class Babel < ActiveRecord::Base
  belongs_to :norm_term, :class_name => "Babel"

  # Use memoization to keep filling this up
  # TBD: Use Hashery to make this limited size LRU cache
  @@babels_map = {}

  # A class method which returns array of normalized names
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
  # Consider all possible subsequences [w1, w1 w2, w1 w2 w3, w2, w2 w3, w3]
  # and try to find normalized names for all
  # Once found, replace in original query_str
  def self.get_normalized_query(query_str)
    normalized_query = query_str

    arr = query_str.split
    subsequences = (0 ... arr.length).map do |i|
      (i ... arr.length).map do |j|
        arr[i..j]
      end
    end.flatten(1)

    subsequences.each do |subsequence|
      phrase = subsequence.join(" ")
      norm_phrase = Babel.get_normalized_names(phrase)[0]
      normalized_query.gsub!(/#{phrase}/, norm_phrase)
    end

    return normalized_query
  end

end
