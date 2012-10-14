# encoding: UTF-8
require 'util.rb'
require 'configcache.rb'

class TimelinesController < ApplicationController
  
  before_filter :signing_is_must, only: [:new, :edit, :update]
  before_filter :require_admin, only: [:timelines_quickview]

  # Constructor
  def initialize(*params)
    super(*params)
    @util = Util.instance
    @configcache = ConfigCache.instance
  end
    
  def index
    @timelines = Timeline.limit(10)
  end

  # Display the timeline in its glory
  def show
    id = params[:id]
    init_core_tl_display_vars()
    get_timeline_data_for_display(id)
    @local_page_title = @tlentry.title
    @complete_page_url = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
    logger.debug("Complete page path: " + @complete_page_url)
    
    @tl_container_page_path = timeline_path(@tlentry)
    if @fullscr == "true"
      render :template => "timelines/tl-fullscr", :formats => [:html], :handlers => :haml,
              :layout => "tl"
    end  
  end

  # Show new timeline page
  def new
    @timeline = Timeline.new
    @timeline_tags_json = "[]"
    render :template => "timelines/new", :formats => [:html], :handlers => :haml
  end

  # Save a new timeline
  def create
    @timeline = Timeline.new(params[:timeline])
    
    if signed_in? and !current_user.nil?
      @timeline.owner_id = current_user.id
    end

    # If no image, put one of the default images randomly
    if @timeline.imgurl.nil? or @timeline.imgurl == ""
      offset = rand(TlImage.count)
      rand_image = TlImage.first(:offset => offset)
      @timeline.imgurl = "/uploads/#{rand_image.fname}"
    end

    if @timeline.save
      record_activity("t=#{@timeline.title}")
      flash[:notice] =
        "<strong>#{@timeline.title}</strong> was successfully created".html_safe
      redirect_to timeline_path(@timeline)
    else
      setup_vars_for_edit(@timeline)
      render :template => "timelines/new", :formats => [:html], :handlers => :haml
    end
  end

  # Show edit timeline page
  def edit
    @timeline = Timeline.find(params[:id])
    setup_vars_for_edit(@timeline)
    render :template => "timelines/edit", :formats => [:html], :handlers => :haml
  end

  # Save the edited timeline
  def update
    @timeline = Timeline.find(params[:id])
    if @timeline.update_attributes(params[:timeline])
      record_activity("t=#{@timeline.title}")
      flash[:notice] =
        "<strong>#{@timeline.title}</strong> was successfully updated".html_safe
      redirect_to timeline_path(@timeline)
    else
      setup_vars_for_edit(@timeline)
      render :template => "timelines/edit", :formats => [:html], :handlers => :haml
    end
  end

  # Delete the timeline
  def destroy
    @timeline = Timeline.find(params[:id])
    @timeline.destroy
    record_activity("t=#{@timeline.title}")
    flash[:notice] =
      "<strong>#{@timeline.title}</strong> was deleted".html_safe
    redirect_to(:root)
  end

  def search
    @tlquery = params[:tlquery]
    logger.debug("Search got fired for tlquery=#{@tlquery}")
    
    @search = Timeline.search() do |q|
      q.keywords @tlquery, :fields => [:title, :tags, :desc]
      q.paginate :page => params[:page], :per_page => NUM_OF_TIMELINES_PER_PAGE
    end
    
    #if @search.total == 0
    #  flash.now[:warning] =
    #   "Sorry! we don't know anything like '#{query_str}'."
    #end
    
    @tlsearch_results = []
    @search.each_hit_with_result do |hit, tl_entry|
      @tlsearch_results.push(tl_entry)
    end
    logger.debug("Number of search results: " + @tlsearch_results.length().to_s + " page-num=" + params[:page].to_s)
    @tlsearch_results_length = @tlsearch_results.length()

    #if @tlsearch_results.length() == 0
    #  flash.now[:warning] =
    #   "Sorry! we don't know anything like ."
    #end
 
    render :template => "timelines/searchresults", :formats => [:html], :handlers => :haml
  end
  
  # Show some example timelines
  def showcase
    @example_rows = []
    # We currently entertain max 4 values ...if present in DB
    for i in 1..4
      #
      # each example row value in db will be in form title,id1.id2,id2   etc.
      #
      example_row_values_str = @configcache.get_value("example_row_#{i}")
      if !example_row_values_str.nil?
        row_values_str_array = example_row_values_str.split(",")
        if row_values_str_array != nil
          rowhash = Hash.new
          tlids_array = [] #empty array
            
          for index in 0..4 # One title and max 4 timelines-ids
            if(index == 0)
              title = row_values_str_array[index]
              rowhash[:title] = title
            end
            
            begin
              tlids_array.push(Integer(row_values_str_array[index]))
            rescue
            end
          end #end for
          
          if tlids_array.length() > 0
            selected_timelines = Timeline.find(tlids_array)
            rowhash[:tl_entries] = selected_timelines
          end
          
          @example_rows.push(rowhash)
        end #end if
      end
    end #end for    
    @local_page_title = "Showcase"
  end
  
  def newhomepage
    # Featured timelines
    @featuted_timelines = nil
    tlids_array = [] #empty array
    tl_ids_str = @configcache.get_value("featured_tl_ids")
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
            
    render :template => "timelines/newtlhome", :formats => [:html], :handlers => :haml
      
  end
  
  def timelines_quickview
    @total_timelines = Timeline.count()
    @timelines_authors_summary = Timeline.select("owner_id as his_id, count(*) as his_count").group("owner_id").order("his_count DESC")
    @authors_details = Hash.new
    
    @timelines_authors_summary.each do |each_author_summary|
      user_entry = nil
      begin
        user_entry = User.find(each_author_summary.his_id)
      rescue
      end
      @authors_details[each_author_summary.his_id] = user_entry
    end
    
    render :template => "timelines/timelines_quickview", :formats => [:html], :handlers => :haml 
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
            @util.make_json(@fetchedevents, json_fname, @tlentry.title, nil, nil)
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
  
    # Setup variables needed for editing timeline in the view
    # Used in create(), edit() and update() above
    def setup_vars_for_edit(tl)
      event_ids = tl.events.split(",").map { |s| s.to_i }
      @events = event_ids.map { |id| Event.find(id) }
      @timeline_tags_json = "[" +
        tl.tags.split(",").map {|t| "{id: 1, name: \"#{t.strip}\" }" }.join(",") +
        "]"   
    end

end
