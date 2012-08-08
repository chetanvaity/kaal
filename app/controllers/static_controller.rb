class StaticController < ApplicationController
  caches_page :home

  def credits
  end
  
  def about_us
    respond_to do |format|
      format.html { render :layout => ! request.xhr? }
    end
  end
  
  def contact_us
    
  end

end
