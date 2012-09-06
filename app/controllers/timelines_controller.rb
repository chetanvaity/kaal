# encoding: UTF-8

class TimelinesController < ApplicationController

  def index
    @timelines = Timeline.limit(10)
  end

  def new
    @timeline = Timeline.new
    render :template => "timelines/new", :formats => [:html], :handlers => :haml
  end

end
