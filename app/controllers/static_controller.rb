class StaticController < ApplicationController
  caches_page :credits, :about_us, :faq

  def credits
  end
  
  def about_us
    respond_to do |format|
      format.html { render :layout => ! request.xhr? }
    end
  end
  
  def faq
  end
  
end
