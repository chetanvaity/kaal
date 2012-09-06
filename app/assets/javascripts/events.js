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

moveEvent = function(id) {
    eid = "#" + id;
    $(eid).appendTo("#gathered_events");
};
