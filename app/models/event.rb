# encoding: UTF-8

class Event < ActiveRecord::Base
  has_many :tags, :dependent => :destroy
  # Look at http://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html
  accepts_nested_attributes_for :tags, :allow_destroy => true
end
