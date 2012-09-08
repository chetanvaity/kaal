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
      flash.now[:notice] =
        "<strong>#{@timeline.title}</strong> was successfully created".html_safe
      record_activity("t=#{@timeline.title}")
      redirect_to root_path
    else
      render :action => "new"
    end                             
  end

end
