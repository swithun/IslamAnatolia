// http://jquery-howto.blogspot.co.uk/2009/09/get-url-parameters-values-with-jquery.html  
function getUrlVars(url) { //{{{
		 var vars = [], hash;
		 var start = url.indexOf('?') + 1;
		 
		 url = url.substring(start);

		 var end = url.indexOf('#');
		 if (-1 != end) {
					url = url.substring(0, end);
		 }
		 
		 var hashes = url.split('&');
		 
		 for (var i = 0; i < hashes.length; i++) {
					hash = hashes[i].split('=');
					vars.push(hash[0]);
					vars[hash[0]] = hash[1];
		 }
		 
		 return vars;
}
//}}}

// array of selectors, events and functions
var jqFunctions = 
		 [
			['.auth_dt', 'click', authorityNames],
			['.reset', 'click', resetForm],
			['.show_following', 'click', showFollowing],
			['.show_next', 'click', showNext],
			['.add_field', 'click', addField],
			['.remove_field', 'click', removeField]
		 ];

// show list items following event target
function showFollowing(event) { //{{{
		 var li = jQuery(event.target).parent('li');
		 
		 var text = jQuery(event.target).html();
		 
		 if (jQuery(li).nextAll('li').css('display') == 'none') {
					jQuery(li).nextAll('li').show();
					jQuery(event.target).html(text.replace('Show', 'Hide'));
		 }
		 else {
					jQuery(li).nextAll('li').hide();
					jQuery(event.target).html(text.replace('Hide', 'Show'));
		 }
		 
		 return false;
}
//}}}

// show first item following event target
function showNext(event) { //{{{
		 var dd = jQuery(event.target).parent('dd');
		 
		 var text = jQuery(event.target).html();
		 
		 if (jQuery(dd).next('dd').css('display') == 'none') {
					jQuery(dd).next('dd').show();
					jQuery(event.target).html(text.replace('Show', 'Hide'));
		 }
		 else {
					jQuery(dd).next('dd').hide();
					jQuery(event.target).html(text.replace('Hide', 'Show'));
		 }
		 
		 return false;
}
//}}}

// reset search form
function resetForm(event) { //{{{
		 var url = $('form').attr('action');
		 window.location = url;
}
//}}}

// names from authority files
function authorityNames(event) { //{{{
		 var ddClass = 'dd.' + jQuery(event.target).attr('id');
		 
		 var text = jQuery(event.target).html();
		 
		 if (jQuery(ddClass).css('display') == 'none') {
					jQuery(ddClass).show();
					jQuery(event.target).html(text.replace('Show', 'Hide'));
		 } 
		 else {
					jQuery(ddClass).hide();
					jQuery(event.target).html(text.replace('Hide', 'Show'));
		 }
		 
		 return false;
}
//}}}

function myDecode(s) { //{{{
		 try {
					s = decodeURI(s);
		 } catch (err) {
					//
		 }
		 
		 return s;
}
//}}}

// add another search field to form
function addField(event) { //{{{
		 var $ = jQuery;
		 
		 // get surrounding DIV and clone it
		 var div1 = $(event.target).closest('div');
		 var div2 = div1.clone(true, true);
		 // clear input box
		 div2.find('input[type=text]').val('');
		 // add clone after cloned DIV
		 div2.insertAfter(div1);
}
//}}}

//// remove current field from search
function removeField(event) { //{{{
		 var $ = jQuery;
		 
		 var div = $(event.target).closest('div');
		 div.remove();
}
//}}}

// register functions
jQuery(document).on('ready', function() { //{{{
		 // highlighting of ASCII-foldable strings
		 var hl = getUrlVars(window.location.href)['hl'];
		 if (hl) {
					jQuery('div.list_container dd').highlight(myDecode(hl), {}, true);
		 }
		 
		 // highlighting of non-ASCII-foldable strings
		 var hlu = getUrlVars(window.location.href)['hlu'];
		 if (hlu) {
					jQuery('div.list_container dd').highlight(myDecode(hlu), {}, false);
		 }
		 
		 // accordion
		 var index = 0;
		 if ($('dt.accordion_selected').length) {
					index = ($('dt.accordion_selected').index()) / 2 ;
		 }
		 
		 jQuery('#accordion').accordion({ header: "dt.accordion_header", collapsible: true, active: index, heightStyle: 'content' });
		 

		 // register event functions
		 var l = jqFunctions.length;
		 for (var i = 0; i < l; ++ i) {
					var f = jqFunctions[i];
					jQuery(f[0]).unbind();
					jQuery(f[0]).on(f[1], f[2]);
		 }
});
//}}}

