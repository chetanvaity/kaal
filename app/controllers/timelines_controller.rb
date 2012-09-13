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
  
  
  def homepage
    init_core_tl_display_vars()
    render :template => "timelines/tlhome", :formats => [:html], :handlers => :haml,
        :layout => "tl"
  end
  
  # ========================= private functions =================================
  private
    # Call this method in the beginning of every function which produces timeline data
    def init_core_tl_display_vars
      #cleanup of session vars ..if any
      if signed_in?
        if !current_user.nil?
          session.delete(:qkey)
          session.delete(:listviewurl)
        end
      end
          
      @query = nil # temporay needed
      @tlid = nil
      @fetchedevents = nil
      @viewstyle = "tl"
      @fullscr = "false"
      @embeddedview = "false"
      @events_on_a_page = "default"
      @total_search_size = 0
      @events_size = 0
      @json_resource_path = nil
    end
  
  

end
