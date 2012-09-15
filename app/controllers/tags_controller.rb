# encoding: UTF-8

class TagsController < ApplicationController

  # For autocomplete in tags entry
  # Should return tags beginning with "q"
  def ac_search()
    query = params[:q]
    if query.nil?
      return
    end

    @tags = Tag.where("name like ?", "%#{query}%").limit(10).uniq { |t| t.name }
    @tags << Tag.new(:name => "#{query}", :id => "")

    render :template => "tags/ac_search", :formats => [:json],
           :handlers => :haml
  end

end
