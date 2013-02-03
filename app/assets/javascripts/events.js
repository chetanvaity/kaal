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


// A global variable to note if event list of the timeline has been modified by the user
// We will mark it dirty when an event is added or removed from the gathered event list
// We will mark it clean after we have successfully saved the gathered event list to DB
var tl_eventlist_dirty = false;

// Copy div with given id to gathered_events div
// Change the id of the new div to "gdiv_" + id
// Remove the hide class - so that the "close" button becomes visible
// Also add the event_id to the gathered_event_ids hidden field
copyEventDiv = function(id) {
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

    tl_eventlist_dirty = true;
    $("#save_msg").addClass("hide");
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

    tl_eventlist_dirty = true;
    $("#save_msg").addClass("hide");
};

// Remove all the divs with id = "gdiv_*"
// Empty the value of the gathered_event_ids hidden field
removeAllEventDivs = function() {
    $('div[id^="gdiv_"]').remove();
    g_ev_ids.attr("value", "");

    tl_eventlist_dirty = true;
    $("#save_msg").addClass("hide");
};

// Clear a token-input box
clearTags = function(id) {
    $("#" + id).tokenInput("clear");
};
