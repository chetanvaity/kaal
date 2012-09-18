jQuery(function($) {

  // Here we want to receive the response to the ajax request sent by clicking on
  // 'edit' link from list-view page. Received response is in HTML form.
	$('.event a[data-type=html]').on('ajax:success', function(event, data, status, xhr) {
        $('#modal-editEvent').find('.modal-body').html(data);
        $('#modal-editEvent').modal({show: true , backdrop : true , keyboard: true});
    });
    
    
  // 
  // Show 'about us' form in popup if clicked on product tagline
  //
  //$('.pg a[data-type=html]').on('ajax:success', function(event, data, status, xhr) {
  //      $('#modal-about').find('.modal-body').html(data);
  //      $('#modal-about').modal({show: true , backdrop : true , keyboard: true});
  //});
  //
      
  
});

// Copy div with given id to gathered_events div
// Change the id of the new div to "gdiv_" + id
// Remove the hide class - so that the "close" button becomes visible
// Also add the event_id to the gathered_event_ids hidden field
copyEventDiv = function(id) {
    // Lets clear the tags from the form
    clearTags("event_tags_str");

    newdiv = $("#" + id).clone();
    newdiv_id = "gdiv_" + id;
    newdiv.attr("id", newdiv_id);
    newdiv.css("opacity", 0.25);
    newdiv.appendTo("#gathered_events");

    btn = $("#" + newdiv_id).children("button:first");
    btn.removeClass("hide");

    g_ev_ids = $("#gathered_event_ids");
    old_value = g_ev_ids.attr("value");
    new_value = old_value + id + ",";
    g_ev_ids.attr("value", new_value);

    newdiv.removeClass("hide");

    newdiv.animate({
	opacity: 1.0,
    }, 1000, function() {
	// Animation complete.
    });
};

// Remove div with id = "gdiv_" + id
// Also remove event_id from gathered_event_ids hidden field
removeEventDiv = function(id) {
    eid = "#gdiv_" + id;
    $(eid).remove();

    g_ev_ids = $("#gathered_event_ids");
    old_value = g_ev_ids.attr("value");
    new_value = old_value.replace(id + ",", "");
    g_ev_ids.attr("value", new_value);
};

// Remove all the divs with id = "gdiv_*"
// Empty the value of the gathered_event_ids hidden field
removeAllEventDivs = function() {
    $('div[id^="gdiv_"]').remove();
    g_ev_ids.attr("value", "");
};

// Clear a token-input box
clearTags = function(id) {
    $("#" + id).tokenInput("clear");
};
