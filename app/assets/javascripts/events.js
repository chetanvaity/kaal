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
copyEventDiv = function(id) {
    newdiv = $("#" + id).clone();
    newdiv_id = "gdiv_" + id;
    newdiv.attr("id", newdiv_id);
    newdiv.appendTo("#gathered_events");

    btn = $("#" + newdiv_id).children("button:first");
    btn.removeClass("hide");
};

// Remove div with id = "gdiv_" + id
removeEventDiv = function(id) {
    eid = "#gdiv_" + id;
    $(eid).remove();
};

