# encoding: UTF-8

class TimelinesController < ApplicationController

  def index
    @timelines = Timeline.limit(10)
  end

  def new
    @timeline = Timeline.new
    render :template => "timelines/new", :formats => [:html], :handlers => :haml
  end

  # Save a timeline
  def create
    @timeline = Timeline.new(params[:timeline])
    
    if signed_in? and !current_user.nil?
      @timeline.owner_id = current_user.id
    end

    if @timeline.save
      record_activity("t=#{@timeline.title}")
    end
    render :template => "timelines/create", :formats => [:js], :handlers => :haml
  end

end
