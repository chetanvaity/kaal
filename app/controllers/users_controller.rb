class UsersController < ApplicationController
  before_filter :signing_is_must, only: [:mycontent, :myevents]

  #get my timelines    
  def mycontent
    @local_page_title = "My timelines"
    @local_page_desc = "Display all timelines owned by the logged in user"
    tl_page_num = params[:tl_paginate_param]
    @timelines = Timeline.where("owner_id = ?", current_user.id).order("created_at DESC").page(tl_page_num).per(12)
    
  end

  #get my events  
  def myevents
    @local_page_title = "My events"
    @local_page_desc = "Display all events owned by the logged in user"

    event_page_num = params[:event_paginate_param]
    @events = Event.where("ownerid = ?", current_user.id).order("jd").page(event_page_num).per(12)
  end  
  
end
