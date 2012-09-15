// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require jquery.nested-fields
//= require bootstrap
//= require_tree .

$(document).ready(function(e) {

    $('FORM').nestedFields({
	       beforeInsert: function(item) {
	         tagtext = $('#newtag').val();
	         item.find(".tagtext").text(tagtext);
	         item.find(".tagname").val(tagtext);
	         item.find(".label").addClass("label-success");
	       },
	       afterRemove: function(item) {
	         console.log(item + ' was removed.');
	       }
    });
    
    
    /*
     * Reference : https://github.com/mathiasbynens/jquery-placeholder
     * IE has problem to render placeholders, hence this plugin is used to take care of it.
    */
    $('input,textarea').placeholder();
    

    $('#event_tags_str').tokenInput("/ac_search", {
	crossDomain: false,
	theme: "facebook",
	hintText: "Type in a tag"
    });
    
    $('#timeline_tags').tokenInput("/ac_search", {
	crossDomain: false,
	theme: "facebook",
	hintText: "Type in a tag"
    });
    
});
