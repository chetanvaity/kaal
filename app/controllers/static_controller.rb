class StaticController < ApplicationController

  def credits
    @local_page_title = "Credits"
    @local_page_desc = "We acknowledge various open source tools and platforms we have used to build " + PRODUCT_DISPLAY_NAME + " timelines"
  end
  
  def about_us
    @local_page_title = "About"
    @local_page_desc = "Know about the motivation and the team behind " + PRODUCT_DISPLAY_NAME + " timelines"
    respond_to do |format|
      format.html { render :layout => ! request.xhr? }
    end
  end
  
  def faq
    @local_page_title = "FAQ"
    @local_page_desc = "Get frequently asked questions answered on this page to understand the basic usage of " + PRODUCT_DISPLAY_NAME + " services which enable very easy creation of timelines"
  end
  
  def terms
    @local_page_title = "Terms of use"
    @local_page_desc = "Our terms of use which expect fair usage of " + PRODUCT_DISPLAY_NAME + " timelines"
  end
  
  # generate robot.txt
  def robot_txt
    @sitemap_url = "#{request.protocol}#{request.host_with_port}#{sitemap_xml_path}"
    render :template => "static/robot", :formats => [:txt], :handlers => :haml
  end
end
