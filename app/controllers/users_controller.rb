class UsersController < ApplicationController
  before_filter :signing_is_must, only: [:mycontent]
  
  def mycontent
    @local_page_title = "My content"
    @local_page_desc = "Display all timelines and events owned by the logged in user"
        
    @events = Event.where("ownerid = ?", current_user.id).order("jd").page(params[:page]).per(20)
    @timelines = Timeline.where("owner_id = ?", current_user.id).order("created_at DESC").page(params[:page]).per(12)
  end  
end
