# encoding: UTF-8

require 'util.rb'
require 'wikipreputil.rb'

class EventsController < ApplicationController
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
    @event.update_attributes!(params[:event])
    flash[:notice] = "#{@event.title} was successfully updated."
    redirect_to event_path(@event)
  end

  def destroy
    @event = Event.find params[:id]
    @event.destroy
    flash[:notice] = "#{@event.title} deleted"
    redirect_to events_path
  end

  def query
    logger.info("EventsController.query() started")
    @events = get_events(params)

    respond_to do |format|
      format.html  { render 'index.html' }
      format.json  { render :json => @events }
    end
  end

  # Get events
  # Make JSON for use with Verite Timeline
  # and then render tl.html
  def query2
    logger.info("EventsController.query2() started")
    tags = params[:tags]
    tags_arr = tags.split ','
    norm_tags_arr = get_norm_tags(tags_arr)

    @events = get_events(norm_tags_arr)
    query_key = @util.get_query_key(params)
    @json_resource_path = "/tmpjson/#{query_key}.json"
    json_fname = "#{Rails.root}/public/#{@json_resource_path}" 
    make_json(@events, json_fname, norm_tags_arr)
    logger.info("EventsController.query2() - json made: #{json_fname}")

    respond_to do |format|
      format.html { render 'tl.html' }
    end
  end

  # ----- Util functions -----

  def get_norm_tags(tags_arr)
    norm_tags_arr = []
    tags_arr.each do |tag_str|
      # Get the normalized version of the tags
      tag_str.downcase!
      tag_str.gsub!(/ /, '_')
      norm_tag = @util.get_synset(tag_str)[0]
      norm_tag.gsub!(/_/, ' ')
      norm_tags_arr.push(norm_tag)
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
  "text":"Blah Blah about these tags/query",
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
        "text":"Something more about #{e.title}. Blah Blah Blah",
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

end
