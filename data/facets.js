// NOT USED ANYMROE

// array of selectors, events and functions
var jqFunctions = 
     [
      ['.show_following', 'click', showFollowing],
     ];

// show list items following event target
function showFollowing(event) { //{{{
     var li = jQuery(event.target).parent('li');
     jQuery(li).nextAll('li').show();
     jQuery(li).hide();
}
//}}}

// register functions
jQuery(document).on('ready', function() { //{{{
     // register event functions
     var l = jqFunctions.length;
     for (var i = 0; i < l; ++ i) {
          var f = jqFunctions[i];
          jQuery(f[0]).unbind();
          jQuery(f[0]).on(f[1], f[2]);
     }
});