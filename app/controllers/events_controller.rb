class EventsController < ApplicationController
  def index
    @events = Event.all
  end

  def show
    id = params[:id]
    @event = Event.find(id)
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

  # TBD: Handle tag upper/lower case
  def query
    tags = params[:tags]
    tags_arr = tags.split ','

    e_ids = []
    tags_arr.each do |tag_str|
      t = Tag.find_by_name tag_str
      if t.nil?
        flash[:notice] = "No such tag: '#{tag_str}'"
        break
      end
      e_ids_for_tag = Tagmap.select(:event_id).where(:tag_id => t.id).map { |o| o.event_id }
      if e_ids == []
        e_ids = e_ids_for_tag
      else
        e_ids = e_ids & e_ids_for_tag
      end
    end

    @events = Event.where(:id => e_ids)
    render 'index.html'
  end

end
