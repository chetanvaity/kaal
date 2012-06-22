# Self Join
# See http://guides.rubyonrails.org/association_basics.html (Section 2.10)
class Babel < ActiveRecord::Base
  belongs_to :norm_term, :class_name => "Babel"
end
