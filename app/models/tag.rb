# encoding: UTF-8

class Tag < ActiveRecord::Base
  validates :name, :presence => true
  validates :name, :length => {
    :maximum => 80,
    :minimum => 2
  }

  # Don't normalize tags!
  # before_save :normalize_tag_name

  protected
  def normalize_tag_name
    self.name = Babel.get_normalized_names(self.name)[0]
  end

end
