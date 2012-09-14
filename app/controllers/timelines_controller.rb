# encoding: UTF-8
require 'util.rb'
require 'configvalues.rb'

class TimelinesController < ApplicationController

  # Constructor
  def initialize(*params)
    super(*params)
    @util = Util.instance
    @configvalues = Configvalues.instance
  end
    
  def index
    @timelines = Timeline.limit(10)
  end

  def show
    id = params[:id]
    init_core_tl_display_vars()
    get_timeline_data_for_display(id)
    @tl_container_page_path = timeline_path(@tlentry)
    if @fullscr == "true"
      render :template => "timelines/tl-fullscr", :formats => [:html], :handlers => :haml,
              :layout => "tl"
    end  
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
    #GEt id of default timeline from DB. HArdcoded to the Id=1 for timebeing.
    default_tl_id = @configvalues.get_value("default_tl_id")
    init_core_tl_display_vars()
    
    if !default_tl_id.nil?
      logger.debug("default timeline id is : " +  default_tl_id)
      get_timeline_data_for_display(default_tl_id)
    else
      logger.info("default timeline id is NIL.")
    end
    
    # Featured timelines
    @featuted_timelines = nil
    tlids_array = [] #empty array
    tl_ids_str = @configvalues.get_value("featured_tl_ids")
    if !tl_ids_str.nil?
      tlids_str_array = tl_ids_str.split(",")
      if tlids_str_array != nil
        tlids_str_array.each { |tlid|
          begin
            tlids_array.push(Integer(tlid))
          rescue
          end
          
        }
      end
    end
    
    if tlids_array.length() > 0
      @featuted_timelines = Timeline.find(tlids_array)
    end
    
    @tl_container_page_path = tlhome_path 
    
    if @fullscr == "false"        
      render :template => "timelines/tlhome", :formats => [:html], :handlers => :haml,
        :layout => "tl"
    else
      render :template => "timelines/tl-fullscr", :formats => [:html], :handlers => :haml,
                   :layout => "tl"
    end  
  end
  
  # ========================= private functions =================================
  private
    # Call this method in the beginning of every function which produces timeline data
    def init_core_tl_display_vars
      #cleanup of session vars ..if any
      if signed_in?
        if !current_user.nil?
          #session.delete(:qkey)
          #session.delete(:listviewurl)
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
      @tlentry = nil
    end
    
    
    def get_timeline_data_for_display(given_tl_id)
      
      #------------------
      # We'll default to 'tl' view if not found.
      @viewstyle = params[:view]
      if @viewstyle.nil? || @viewstyle.blank? 
        @viewstyle = "tl"
      end
      if @viewstyle != "tl" && @viewstyle != "list"
        @viewstyle = "tl"
      end
          
      # We'll default to 'no fullscreen' view if not found.
      @fullscr = params[:fullscr]
      if @fullscr.nil? || @fullscr.blank? 
        @fullscr = "false"
      end
      if @fullscr != "false" && @fullscr != "true"
        @fullscr = "false"
      end
          
      # We'll default to 'non-embedded' view if not found.
      @embeddedview = params[:embview]
      if @embeddedview.nil? || @embeddedview.blank? 
        @embeddedview = "false"
      end
      if @embeddedview != "false" && @embeddedview != "true"
        @embeddedview = "false"
      end
      if @embeddedview == "true"
        @viewstyle = "tl"
        @fullscr = "false"
      end
      #------------------
      @tlentry = Timeline.find(given_tl_id)
      @tlid = @tlentry.id
      
      event_id_str = @tlentry.events
      idstr_array = event_id_str.split(",")
      id_array = [] #empty array
      if idstr_array != nil
        idstr_array.each { |eventid|
          tmp_str = eventid.strip
          if !tmp_str.empty?
            begin
              id_array.push(Integer(tmp_str))
            rescue
            end
          end 
        }
        logger.debug("Length of Integer array of event ids: " + id_array.length().to_s)
        if id_array.length() > 0
          @fetchedevents = Event.find(id_array)
          @fetchedevents.each { |each_event| each_event.importance = 3 }
          @fetchedevents.sort!{ |a,b| a.jd <=> b.jd }
        end
        
        if !@fetchedevents.nil?
          @events_size = @fetchedevents.size
          logger.info("Number of fetched events: #{@fetchedevents.size}")
          query_key = @util.get_query_key(nil, nil, "#{given_tl_id}", "default")
          @json_resource_path = "/tmpjson/#{query_key}.json"
          
          if @viewstyle == "tl"
            #This is for timeline display
            json_fname = "#{Rails.root}/public/#{@json_resource_path}"
            @util.make_json(@fetchedevents, json_fname, given_tl_id, nil, nil)
          else
            #This is for tabular display
            # @fetchedevents should be used by the view for display purpose
            #logger.info("Size of @fetchedevents is #{@events_size}")
          end
        else
          logger.info("Could not fetch events from DB.")
        end
        
        
      end
      
    end
  
  

end
