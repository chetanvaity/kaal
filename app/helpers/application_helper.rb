module ApplicationHelper
  
  
  # Quick helper for timeline view url
  def generate_timeline_view_url(given_tags, # search words
                                      given_timeline_id, # IF it is direct search by giving timeline-id ..future
                                      given_from_date, given_to_date, # date conditions
                                      is_fullscreen, # is it fullscreen display? 'true' means yes.
                                      events_on_page, # Expected values 'default' or 'more'
                                      tl_container_path)
    generate_list_or_tl_view_url(true,given_tags,given_timeline_id,given_from_date, given_to_date,is_fullscreen,events_on_page,tl_container_path)
  end
  
  
  # Quick helper for list view url
  def generate_list_view_url(given_tags, # search words
                                        given_timeline_id, # IF it is direct search by giving timeline-id ..future
                                        given_from_date, given_to_date, # date conditions
                                        is_fullscreen, # is it fullscreen display? 'true' means yes.
                                        events_on_page, # Expected values 'default' or 'more'
                                        tl_container_path)
      generate_list_or_tl_view_url(false,given_tags,given_timeline_id,given_from_date, given_to_date,is_fullscreen,events_on_page,tl_container_path)
  end
  
  
  #
  # This funhction will generate partial url which will be used on tab-click, button-click, etc.
  #
  def generate_list_or_tl_view_url(is_tl_view,  # IS this timeline view or listview? 'true' means timeline view. 
                                    given_tags, # search words
                                    given_timeline_id, # IF it is direct search by giving timeline-id ..future
                                    given_from_date, given_to_date, # date conditions
                                    is_fullscreen, # is it fullscreen display? 'true' means yes.
                                    events_on_page, # Expected values 'default' or 'more'
                                    tl_container_path) # The page which holds this timeline at present 
                                    
    
    #base_search_url = "#{tlsearch_path}?"
    base_search_url = "#{tl_container_path}?"
        
    url_to_return = base_search_url 
    
    # fullscreen param
    if (!is_fullscreen.nil? && is_fullscreen == true)
      url_to_return += "fullscr=true"
    else
      #We already have default handling for this case. So let's not provide this in url.
      #url_to_return += "fullscr=false"
    end
    
    # timeline or list view??
    if (!is_tl_view.nil? && is_tl_view == true)
      #We already have default handling for this case. So let's not provide this in url.
      #url_to_return += "&view=tl"
    else
      url_to_return += "&view=list"
    end
    
    #tags
    if !given_tags.nil?
      url_to_return += "&q=" + given_tags.to_s
    end
    
    
    #timeline id
    if !given_timeline_id.nil?
      url_to_return += "&tlid=" + given_timeline_id.to_s
    end
    
    
    #from-to dates
    if !given_from_date.nil? &&  !given_from_date.blank?
      url_to_return += "&from=" + given_from_date.to_s
    end
    if !given_to_date.nil? && !given_to_date.blank?
      url_to_return += "&to=" + given_to_date.to_s 
    end
    
    
    #events on page
    if (!events_on_page.nil? && events_on_page == "more")
      url_to_return += "&pgevts=more"
    else
      #We already have default handling for this case. So let's not provide this in url.
      #url_to_return += "&pgevts=default"
    end
    
    return url_to_return
  end
  
  
  #
  # To get complete url for default timeline view
  #
  def generate_complete_default_url_for_timeline_view(given_tags, given_timeline_id,
                                                      given_from_date, given_to_date)
    
    target_page_path = nil
    if !given_timeline_id.nil?
      target_page_path = timeline_path(given_timeline_id)
      return "#{request.protocol}#{request.host_with_port}#{target_page_path}"
    else
      target_page_path = tlsearch_path
    end                                                  
    partail_timeline_view_url = generate_timeline_view_url(given_tags, given_timeline_id, 
                               given_from_date, given_to_date,
                               false, 
                               "??",
                               target_page_path)
    return "#{request.protocol}#{request.host_with_port}#{partail_timeline_view_url}"
  end
  
  
  
  
  def generate_complete_embedview_url(given_tags, given_timeline_id,
                                      given_from_date, given_to_date)
    
    target_page_path = nil
    if !given_timeline_id.nil?
      target_page_path = timeline_path(given_timeline_id)
    else
      target_page_path = tlsearch_path
    end    
        
    protocol_host_port = "#{request.protocol}#{request.host_with_port}"
    main_url = "#{protocol_host_port}#{target_page_path}?embview=true"
        
    #tags
    if !given_tags.nil?
      main_url += "&q=" + given_tags.to_s
    end
        
        
    #timeline id
    #if !given_timeline_id.nil?
    #  main_url += "&tlid=" + given_timeline_id.to_s
    #end
    
    #from-to dates
    if !given_from_date.nil? && !given_from_date.blank?
      main_url += "&from=" + given_from_date.to_s
    end
    if !given_to_date.nil?  &&  !given_to_date.blank?
      main_url += "&to=" + given_to_date.to_s 
    end
            
    url_to_return = '<iframe src="'
    url_to_return += URI::encode(main_url) + '" frameborder="yes" scrolling="no" width="84%" height="500">Test</iframe>'
        
    return url_to_return
    
  end
  
end
