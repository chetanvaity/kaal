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
      format.html { render :template => "events/index", :formats => [:html], :handlers => :haml }
      format.json  { render :json => @events }
    end
  end

  # Get events
  # Make JSON for use with Verite Timeline
  # and then render tl.html
  # Variables passed to view - @tags, @events_size, @json_resource_path
  def query2
    from = params[:from]
    to = params[:to]
    @tags = params[:tags]
    logger.info("query2() entry - from=#{from}, to=#{to}, tags=#{@tags}")
    
    from_jd = to_jd = nil
    from_jd = Date.parse(from).jd unless from.nil? or from.empty?
    to_jd = Date.parse(to).jd unless to.nil? or to.empty?

    @tags = "Katrina Kaif,Akshay Kumar" if @tags.nil? or @tags.empty?
    query_key = @util.get_query_key(from_jd, to_jd, @tags)
    @json_resource_path = "/tmpjson/#{query_key}.json"

    val = @@q_keys[query_key]
    if not val.nil?
      logger.info("Cache hit!")
      @events_size = val
    else
      # Get events and create the json
      tags_arr = @tags.split(',').map {|t| t.strip}
      norm_tags_arr = tags_arr.map {|tag_str| Tag.get_normalized_name(tag_str)}
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
  # TBD: JSON should be created using some JSON library to avoid escaping issues
  def make_json(events, json_fname, tags_arr)
    tags_str = tags_arr.map {|t| t.capitalize }.join(" and ")
    headline = tags_str.titlecase
    header_json = <<END
{"timeline":
  {
  "headline":"#{headline}",
  "type":"default",
  "startDate":"2011,9,1",
  "text":" ",
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
