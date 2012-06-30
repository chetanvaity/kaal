# encoding: UTF-8

require 'hashery'
require 'util.rb'

class EventsController < ApplicationController
  @@q_keys = Hashery::LRUHash.new(100)

  # Constructor
  def initialize(*params)
    super(*params)
    logger.info("EventsController.initialize() started")
    @util = Util.instance
    logger.info("EventsController.initialize() done")
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
  end

  def create
    @event = Event.create!(params[:event])
    flash[:notice] = "#{@event.title} was successfully created"
    redirect_to events_path
  end

  def edit
    @event = Event.find params[:id]
  end

  def update
    @event = Event.find params[:id]
    if @event.update_attributes(params[:event])
      redirect_to event_path(@event)
    else
      render :action => "edit"
    end
  end

  def destroy
    @event = Event.find params[:id]
    @event.destroy
    flash[:notice] = "#{@event.title} deleted"
    redirect_to events_path
  end

  def query
    logger.info("EventsController.query() started")
    @tags = params[:tags]
    tags_arr = @tags.split ','
    norm_tags_arr = get_norm_tags(tags_arr)
    @events = get_events(norm_tags_arr)

    respond_to do |format|
      format.html { render :template => "events/index", :formats => [:html], :handlers => :haml }
      format.json  { render :json => @events }
    end
  end

  # Get events
  # Make JSON for use with Verite Timeline
  # and then render tl.html
  # Variables passed to view - @tags, @events_size, @json_resource_path
  def query2
    logger.info("EventsController.query2() started")
    @tags = params[:tags]
    @tags = "Katrina Kaif,Akshay Kumar" if @tags.nil? or @tags.empty?
    query_key = @util.get_query_key(@tags)
    @json_resource_path = "/tmpjson/#{query_key}.json"

    val = @@q_keys[query_key]
    if not val.nil?
      logger.info("Cache hit!")
      @events_size = val
    else
      # Get events and create the json
      tags_arr = @tags.split ','
      norm_tags_arr = get_norm_tags(tags_arr)
      events = get_events(norm_tags_arr)
      @events_size = events.size
      json_fname = "#{Rails.root}/public/#{@json_resource_path}" 
      make_json(events, json_fname, norm_tags_arr)
      @@q_keys.store(query_key, @events_size)
      logger.info("EventsController.query2() - json made: #{json_fname}")
    end

    render :template => "events/tl", :formats => [:html], :handlers => :haml, :layout => "tl"
  end

  # ----- Util functions -----

  def get_norm_tags(tags_arr)
    norm_tags_arr = []
    tags_arr.each do |tag_str|
      # Get the normalized version of the tags
      tag_str.downcase!
      term = Babel.find_by_term(tag_str)
      if term.nil?
        norm_tags_arr.push(tag_str)
      else
        norm_tags_arr.push(term.norm_term.term)
      end
    end
    return norm_tags_arr
  end

  def get_events(tags_arr)
    e_ids = []
    tags_arr.each do |norm_tag|
      tlist = Tag.find_all_by_name(norm_tag)
      if tlist.nil? || tlist.empty?
        flash[:notice] = "No such tag: '#{norm_tag}'"
        break
      end
      e_ids_for_tag = tlist.map { |t| t.event_id } 
      if e_ids == []
        e_ids = e_ids_for_tag
      else
        e_ids = e_ids & e_ids_for_tag
      end
    end
    
    return Event.where(:id => e_ids).order(:jd)
  end

  # Make JSON file as needed by Verite Timeline
  def make_json(events, json_fname, tags_arr)
    tags_str = tags_arr.map {|t| t.capitalize }.join(" and ")
    header_json = <<END
{"timeline":
  {
  "headline":"Events related to #{tags_str}",
  "type":"default",
  "startDate":"2011,9,1",
  "text":" ",
  "date": [
END

    date_json_array = []
    events.each do |e|
      d = Date.jd(e.jd).strftime("%Y,%m,%d")
      e.title =~ /(Birth:|Death:|Created:|Ended:|Started:|End:) (.*)/
      t = $&.nil? ? e.title : $2
      wiki_t = t.gsub(/ /, '_')
      wiki_link = "http://en.wikipedia.org/wiki/#{wiki_t}"
      date_json = <<END
        {
        "startDate":"#{d}",
        "headline":"#{e.title}",
        "text":" ",
        "id":"#{e.id}",
        "asset":
          {
          "media":"#{wiki_link}",
          "credit":"",
          "caption":"Excerpt from the Wikipedia article for #{t}"
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
