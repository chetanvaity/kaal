# encoding: UTF-8

require 'hashery'
require 'util.rb'

class EventsController < ApplicationController
  @@q_keys = Hashery::LRUHash.new(100)

  # Constructor
  def initialize(*params)
    super(*params)
    @util = Util.instance
  end
  
  def index
    @events = Event.limit(10)
  end

  def show
    id = params[:id]
    @event = Event.find(id)
    @taglist = Tag.find_all_by_event_id(id).map {|t| t.name}
  end

  def new
    @event = Event.new
    render :template => "events/new", :formats => [:html], :handlers => :haml
  end

  # The <strong> markup in flash message is breaking strict MVC
  def create
    @event = Event.new(params[:event])
    
    #Assign ownerid  
    if signed_in?
      if !current_user.nil?
        @event.ownerid = current_user.id
      end
    end
    
    if @event.save
      flash.now[:notice] =
        "<strong>#{@event.title}</strong> was successfully created".html_safe
      redirect_to event_path(@event)
    else
      render :action => "new"
    end
  end

  def edit
    @event = Event.find params[:id]
    
    respond_to do |format|
      format.html { render :layout => ! request.xhr? }
    end
  end

  def update
    @event = Event.find params[:id]
    #This parameter will be available on this form only when edit has attempted from listview.
    @editfromlistview = params[:editfromlistview]
      
    if @event.update_attributes(params[:event])
      if (!@editfromlistview.nil?) && (@editfromlistview == 'true')
        #This is edit from list view. 
        #Let's show success notification and let's show the refreshed listview page
        flash[:notice] =
                  "<strong>#{@event.title}</strong> was successfully updated".html_safe
        #cache update
        remove_from_cache(session[:qkey])
          
        #To refresh the listview page
        redirect_to(:back)
      else
        #Normal edit success case
        flash[:notice] =
          "<strong>#{@event.title}</strong> was successfully updated".html_safe
        redirect_to event_path(@event)
      end
    else
      if (!@editfromlistview.nil?) && (@editfromlistview == 'true')
        #Show error message with refreshed listview page
        flash[:warning] =   "<strong>#{@event.title}</strong> could not be updated".html_safe
        redirect_to(:back)  
      else
        #Normal edit error case  
        render :action => "edit"
      end
    end
  end

  def destroy
    del_from_listview = params[:fromlistview]
    @event = Event.find params[:id]
    @event.destroy
    flash[:notice] = "<strong>#{@event.title}</strong> deleted".html_safe
    if (!del_from_listview.nil?) && (del_from_listview == 'true')
      
      #cache update
      remove_from_cache(session[:qkey])
                
      # refresh the listview page
      redirect_to (:back)
    else
      # delete from normal page
      redirect_to root_path
    end
  end

  
  def query
    logger.info("EventsController.query() started")
    @tags = params[:tags]
    tags_arr = @tags.split ','
    norm_tags_arr = []
    tags_arr.map {|tag_str| norm_tags_arr += Tag.get_normalized_names(tag_str)}
    @events = get_events(norm_tags_arr)[1]

    respond_to do |format|
      format.html { render :template => "events/index", :formats => [:html],
        :handlers => :haml }
      format.json  { render :json => @events }
    end
  end

  #
  # To remove cached entry and delete any relevant jason file present
  # TBD: IS this threadsafe?? AMOL
  #
  def remove_from_cache(qkey)
    if qkey.nil?
      return
    end
    
    #Remove from cache  
    @@q_keys.delete(qkey)
    
    #remove json file too
    json_fname = "#{Rails.root}/public/tmpjson/#{qkey}.json"
    File.delete(json_fname)
  end
  
  # Get events
  # Make JSON for use with Verite Timeline
  # and then render tl.html
  # Variables passed to view - @query, @events_size, @json_resource_path
  def query2
        
    @fromdate = params[:from]
    @todate = params[:to]
    @query = params[:q]
    @fetchedevents = nil
    @viewstyle = params[:view]
    if @viewstyle.nil?
      @viewstyle = "tl"
    end
    
    @fullscr = params[:fullscr]
    if @fullscr.nil?
      @fullscr = "false"
    end
    if @fullscr != "false" && @fullscr != "true"
      @fullscr = "false"
    end
    
    @embeddedview = params[:embview]
    if @embeddedview.nil?
      @embeddedview = "false"
    end
    if @embeddedview == "true"
      @viewstyle = "tl"
      @fullscr = "false"
    end
    
    @events_on_a_page = params[:pgevts] # Allowed values are 'default' and 'more'
    if ( @events_on_a_page.nil? ) ||
       ( (@events_on_a_page != "default") && (@events_on_a_page != "more"))
      @events_on_a_page = "default"
    end
    #local var
    numevents_on_a_page = DEFAULT_NUM_OF_EVENTS_TOBE_DISPLAYED
    if(@events_on_a_page == "more")
      numevents_on_a_page= MORE_NUM_OF_EVENTS_TOBE_DISPLAYED
    end
    
    #local var
    #cache_refresh = false;
    #tmp_cache_refresh = params[:cacherefresh]
    #if(!tmp_cache_refresh.nil? && tmp_cache_refresh == "true")
    #  cache_refresh = true;
    #end

    logger.info("query2() entry - from=#{@fromdate}, to=#{@todate}, q=#{@query}, viewstyle=#{@viewstyle}, embeddedview=#{@embeddedview}")
    
    begin
      (from_jd, to_jd) = get_jds_from_params(@fromdate, @todate)
    rescue ArgumentError => e
      flash.now[:warning] = e.to_s
      redirect_to root_url
      return
    end

    @query = "Katrina Kaif Akshay Kumar" if @query.nil? or @query.empty?
    query_key = @util.get_query_key(from_jd, to_jd, @query, @events_on_a_page)
    @json_resource_path = "/tmpjson/#{query_key}.json"

    val = @@q_keys[query_key]
    if (not val.nil?)  &&  (@viewstyle == "tl") 
      logger.info("Cache hit!")
      @events_size = val[0]
      @total_search_size = val[1]
    else
      # Get events and create the json
      res_arr = get_events(from_jd, to_jd, @query, numevents_on_a_page)
      @fetchedevents = res_arr[1]
      @total_search_size = res_arr[0]
      @events_size = @fetchedevents.size
      
      if @viewstyle == "tl"
        #This is for timeline display
        json_fname = "#{Rails.root}/public/#{@json_resource_path}"
        make_json(@fetchedevents, json_fname, @query, from_jd, to_jd)
        @@q_keys.store(query_key, [@events_size,@total_search_size])
        logger.info("EventsController.query2() - json made: #{json_fname}")
      else
        #This is for tabular display
        # @fetchedevents should be used by the view for display purpose
        logger.info("Size of @fetchedevents is #{@events_size}")
      end
    end
    
    if @total_search_size <= DEFAULT_NUM_OF_EVENTS_TOBE_DISPLAYED
      @total_search_size = -1 # no more data
    end
    
    # remember query key in session. We'll need if user edits/delets event
    if signed_in?
      if !current_user.nil?
        session[:qkey] = query_key
      end
    end
    
    if @fullscr == "false"
      render :template => "events/tl", :formats => [:html], :handlers => :haml,
       :layout => "tl"
    else
      render :template => "events/tl-fullscr", :formats => [:html], :handlers => :haml,
             :layout => "tl"
    end
    
  end

  # ----- Util functions -----
  
  # Get events from the Solr index
  # Either from_jd and to_jd should both be nil or they should both be valid
  def get_events(from_jd, to_jd, query_str,numevents_on_a_page)
    logger.info("get_events(): query_str=#{query_str}")
    norm_query_str = Babel.get_normalized_query(query_str)
    logger.info("get_events(): norm_query_str=#{norm_query_str}")

    search = Event.search() do
      keywords norm_query_str, :fields => [:title, :tags, :extra_words]
      paginate :page => 1, :per_page => numevents_on_a_page
    end

    if search.total == 0
      flash.now[:warning] =
        "Sorry! we don't know anything like '#{query_str}'."
    end

    event_results = []
    search.each_hit_with_result do |hit, event|
      event.score = hit.score
      if from_jd.nil? or to_jd.nil?
        event_results.push(event)
      else
        if event.jd >= from_jd and event.jd <= to_jd
          event_results.push(event)
        end
      end
    end

    # Put importance(1/2/3) in each event
    event_results = Event.populate_importance(event_results)
    
    # sort it on event date in ascending order, needed for list-view display.
    event_results.sort!{ |a,b| a.jd <=> b.jd }

    return [search.total, event_results] 
  end

  # Convert the date params into Date objects and then their JDs
  # If both are nil, return nils
  # If from is nil, return JD = 0
  # If to is nil, return current date JD
  def get_jds_from_params(from, to)
    if (from.nil? or from.empty?)
      if (to.nil? or to.empty?)
        from_jd = to_jd = nil
      else
        from_jd = 0
        to_jd = Event.parse_date(to).jd
      end
    else
      if (to.nil? or to.empty?)
        from_jd = Event.parse_date(from).jd
        to_jd = Date.today.jd
      else
        from_jd = Event.parse_date(from).jd
        to_jd = Event.parse_date(to).jd
      end
    end
    return [from_jd, to_jd]
  end
  

  # Make JSON file as needed by Verite Timeline
  # TBD: JSON should be created using some JSON library to avoid escaping issues
  def make_json(events, json_fname, query_str, from_jd, to_jd)
    # Make nice looking main frame for the timeline
    headline = ActiveSupport::JSON.encode(query_str.titlecase)
    if (from_jd.nil? or to_jd.nil?)
      text = " "
    else
      text = "Events from " + Date.jd(from_jd).strftime("%d %b %Y") + " - " +
        Date.jd(to_jd).strftime("%d %b %Y")
    end

    header_json = <<END
{"timeline":
  {
  "headline":#{headline},
  "type":"default",
  "startDate":"2011,9,1",
  "text":"#{text}",
  "date": [
END

    date_json_array = []
    events.each do |e|
      d = Date.jd(e.jd).strftime("%Y,%m,%d")
      text = e.desc.blank? ? " " : e.desc
      text = ActiveSupport::JSON.encode(text)
      title = ActiveSupport::JSON.encode(e.title)
      media_url = e.url
      media_caption = e.url

      date_json = <<END
        {
        "startDate":"#{d}",
        "headline":#{title},
        "text":#{text},
        "id":"#{e.id}",
        "importance":"#{e.importance}",
        "asset":
          {
          "media":"#{media_url}",
          "credit":"",
          "caption":"#{media_caption}"
          }
        }
END
      date_json_array.push(date_json)
    end
    all_date_json = date_json_array.join(",\n")
    
    footer_json = <<END
        ]
    }
}
END
    
    File.open(json_fname, "w") do |f|
      f.puts(header_json)
      f.puts(all_date_json)
      f.puts(footer_json)
    end
  end
  
  #===================================================
  # New home page function added by Amol ...test purpose for timebeing
  # Get events
  # Make JSON for use with Verite Timeline
  # and then render tl.html
  def myhome
    logger.info("EventsController.myhome() started")
    render :template => "events/myhome", :formats => [:html], :handlers => :haml
  end

  def search
    searchkey = params[:searchkey]
    if searchkey.nil?
      return
    end
    
    @search = Event.search() do
      keywords searchkey, :fields => [:title, :extra_words]
      paginate :page => 1, :per_page => 1200
    end
    render :template => "events/search", :formats => [:html], :handlers => :haml
  end

end
