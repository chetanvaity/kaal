class UsersController < ApplicationController
  def mycontent
    @events = Event.where("ownerid = ?", current_user.id).order("jd").page(params[:page]).per(20)
    @timelines = Timeline.where("owner_id = ?", current_user.id).order("created_at DESC").page(params[:page]).per(12)
  end  
end
