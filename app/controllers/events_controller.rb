# encoding: UTF-8

require 'util.rb'

class EventsController < ApplicationController
  # Constructor
  def initialize
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
    tags = params[:tags]
    tags_arr = tags.split ','

    e_ids = []
    tags_arr.each do |tag_str|
      # Get the normalized version of the tags
      tag_str.downcase!
      tag_str.gsub!(/ /, '_')
      norm_tag = @util.get_synset(tag_str)[0]
      norm_tag.gsub!(/_/, ' ')

      tlist = Tag.find_all_by_name(norm_tag)
      if tlist.nil? || tlist.empty?
        flash[:notice] = "No such tag: '#{tag_str}'"
        break
      end
      e_ids_for_tag = tlist.map { |t| t.event_id } 
      if e_ids == []
        e_ids = e_ids_for_tag
      else
        e_ids = e_ids & e_ids_for_tag
      end
    end

    @events = Event.where(:id => e_ids).order(:jd)

    respond_to do |format|
      format.html  { render 'index.html' }
      format.json  { render :json => @events }
    end
  end

end
