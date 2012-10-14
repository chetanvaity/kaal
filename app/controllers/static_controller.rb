class StaticController < ApplicationController
  caches_page :credits, :about_us, :faq

  def credits
    @local_page_title = "Credits"
  end
  
  def about_us
    @local_page_title = "About"
    respond_to do |format|
      format.html { render :layout => ! request.xhr? }
    end
  end
  
  def faq
    @local_page_title = "FAQ"
  end
  
end
