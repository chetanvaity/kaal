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
    if @event.save
      flash[:notice] =
        "<strong>#{@event.title}</strong> was successfully created".html_safe
      redirect_to event_path(@event)
    else
      render :action => "new"
    end
  end

  def edit
    @event = Event.find params[:id]
  end

  def update
    @event = Event.find params[:id]
    if @event.update_attributes(params[:event])
      flash[:notice] =
        "<strong>#{@event.title}</strong> was successfully updated".html_safe
      redirect_to event_path(@event)
    else
      render :action => "edit"
    end
  end

  def destroy
    @event = Event.find params[:id]
    @event.destroy
    flash[:notice] = "<strong>#{@event.title}</strong> deleted".html_safe
    redirect_to events_path
  end

  def query
    logger.info("EventsController.query() started")
    @tags = params[:tags]
    tags_arr = @tags.split ','
    norm_tags_arr = tags_arr.map {|tag_str| Tag.get_normalized_name(tag_str)}
    @events = get_events(norm_tags_arr)

    respond_to do |format|
      format.html { render :template => "events/index", :formats => [:html],
        :handlers => :haml }
      format.json  { render :json => @events }
    end
  end

  # Get events
  # Make JSON for use with Verite Timeline
  # and then render tl.html
  # Variables passed to view - @tags, @events_size, @json_resource_path
  def query2
    @fromdate = params[:from]
    @todate = params[:to]
    @tags = params[:tags]
    @tlid = params[:tlid]
    @fetchedevents = nil
    @viewstyle = params[:view]
    if @viewstyle.nil?
      @viewstyle = "tl"
    end

    logger.info("query2() entry - from=#{@fromdate}, to=#{@todate}, tags=#{@tags}, tlid=#{@tlid}, viewstyle=#{@viewstyle}")
    
    begin
      (from_jd, to_jd) = get_jds_from_params(@fromdate, @todate)
    rescue ArgumentError => e
      flash.now[:warning] = e.to_s
      redirect_to root_url
      return
    end

    @tags = "Katrina Kaif,Akshay Kumar" if @tags.nil? or @tags.empty?
    query_key = @util.get_query_key(from_jd, to_jd, @tags)
    @json_resource_path = "/tmpjson/#{query_key}.json"

    val = @@q_keys[query_key]
    if (not val.nil?)  &&  (@viewstyle == "tl") 
      logger.info("Cache hit!")
      @events_size = val
    else
      # Get events and create the json
      tags_arr = @tags.split(',').map {|t| t.strip}
      norm_tags_arr = tags_arr.map {|tag_str| Tag.get_normalized_name(tag_str)}
      @fetchedevents = get_events(from_jd, to_jd, norm_tags_arr)
      @events_size = @fetchedevents.size
      
      if @viewstyle == "tl"
        #This is for timeline display
        json_fname = "#{Rails.root}/public/#{@json_resource_path}"
        make_json(@fetchedevents, json_fname, norm_tags_arr, from_jd, to_jd)
        @@q_keys.store(query_key, @events_size)
        logger.info("EventsController.query2() - json made: #{json_fname}")
      else
        #This is for tabular display
        # @fetchedevents should be used by the view for display purpose
        logger.info("Size of @fetchedevents is #{@events_size}")
      end
    end

    render :template => "events/tl", :formats => [:html], :handlers => :haml,
    :layout => "tl"
  end

  # ----- Util functions -----
  
  # Get events from DB
  # Either from_jd and to_jd should both be nil or they should both be valid
  def get_events(from_jd, to_jd, tags_arr)
    e_ids = []
    tags_arr.each do |norm_tag|
      tlist = Tag.find_all_by_name(norm_tag)
      if tlist.nil? || tlist.empty?
        add_link = "<a class=\"pull-right\" href=\"#{url_for(:new_event)}\">Add new event</a>"
        flash.now[:warning] =
          "Sorry! I don't know anything like '#{norm_tag}'. #{add_link}".html_safe
        break
      end
      e_ids_for_tag = tlist.map { |t| t.event_id } 
      if e_ids == []
        e_ids = e_ids_for_tag
      else
        e_ids = e_ids & e_ids_for_tag
      end
    end

    if from_jd.nil? or to_jd.nil?
      # Forget date bracketing
      return Event.where(:id => e_ids).order(:jd)
    else
      return Event.where(:id => e_ids, :jd => (from_jd..to_jd)).order(:jd)
    end
  end

  # Convert the date parsms into Date objects and then their JDs
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
  def make_json(events, json_fname, tags_arr, from_jd, to_jd)
    # Make nice looking main frame for the timeline
    headline = tags_arr.join(" & ").titlecase
    if (from_jd.nil? or to_jd.nil?)
      text = " "
    else
      text = "Events from " + Date.jd(from_jd).strftime("%d %b %Y") + " - " +
        Date.jd(to_jd).strftime("%d %b %Y")
    end

    header_json = <<END
{"timeline":
  {
  "headline":"#{headline}",
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
      if e.url.blank?
        e.title =~ /(Birth:|Death:|Created:|Ended:|Started:|End:) (.*)/
        t = $&.nil? ? e.title : $2
        wiki_t = t.gsub(/ /, '_')
        media_url = "http://en.wikipedia.org/wiki/#{wiki_t}"
        media_caption = "Excerpt from the Wikipedia article for #{t}"
      end
      
      date_json = <<END
        {
        "startDate":"#{d}",
        "headline":#{title},
        "text":#{text},
        "id":"#{e.id}",
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


end
