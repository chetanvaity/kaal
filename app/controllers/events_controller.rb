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

end
