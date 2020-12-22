// http://jquery-howto.blogspot.co.uk/2009/09/get-url-parameters-values-with-jquery.html  

function getUrlVars(url) { //{{{                                                                                                                                                                                                                                                                                               
      var vars = [], hash;
      var hashes = url.slice(url.indexOf('?') + 1).split('&');
      for(var i = 0; i < hashes.length; i++) {
           hash = hashes[i].split('=');
           vars.push(hash[0]);
           vars[hash[0]] = hash[1];
      }
      return vars;
 }
//}}}

// name of class
var exp = 'expanded';
// message for empty lists
var empty = '<dt>Empty</dt>';

// selectors for DTs in first and second level lists
var d1 = 'dl.dl1 > dt';
var d2 = 'dl.dl2 > dt';

// array of selectors, events and functions
var jqFunctions = 
     [
      [d1 + ' > span', 'click', expandOne],
      [d2 + ' > span', 'click', expandTwo],
      ['.auth_dt', 'click', authorityNames],
      ['.reset', 'click', resetForm]
     ];

// width of DT (em)
var width1 = 10;
var width2 = 8;

// reset search form
function resetForm(event) { //{{{
     var url = $('form').attr('action');
     window.location = url;
}
//}}}

function highlight(hl) { //{{{
     if (hl) {
          // do highlighting
          jQuery('dl.dl1 dd').highlight(hl.split('|'), { wordsOnly: true });
          
          // locate DTs that would be clicked on to get to first highlight
          var d2dt = jQuery('dl.dl2 > dd:has( .highlight )').first().prev('dt');
          var d1dt = jQuery(d2dt).parents('dd').prev('dt');
          
          // send click events to SPANs in these DTs
          jQuery(d1dt).children('span').trigger('click');
          jQuery(d2dt).children('span').trigger('click');
     }
}
//}}}

// expand first level list item
function expandOne(event) { //{{{
     // get parent DT
     var dt = jQuery(event.target).parent();
     
     // mark all level 1 DTs as un-expanded
     jQuery(d1).removeClass(exp);
     // mark as expanded
     jQuery(dt).addClass(exp);
     
     // get following DD from parent DT
     var list = jQuery(dt).next('dd');
     // reset all DTs in second level lists
     jQuery(d2).css('position', 'static');
     // make DTs in selected second level list absolute
     jQuery(d2, list).css('position', 'absolute');
     
     loadFragment(event);
}
//}}}

// expand second level list item
function expandTwo(event) { //{{{
     // get parent DT
     var dt = jQuery(event.target).parent();
     
     // get following DD from parent DT
     var dd = jQuery(dt).next('dd');
     
     // if DD has empty list inside then mark as empty
     if (!jQuery(dd).has('dl dt').length) {
          jQuery(dd).html('This section is empty');
     }
     
     // mark all level 2 DTs in this list un-expanded
     jQuery(d2, dt.parent().parent()).removeClass(exp);
     // mark this DT as expanded
     jQuery(dt).addClass(exp);
     
     loadFragment(event);
}
//}}}

// load fragment without it adding to browser history
function loadFragment(event) {
     var fragment = jQuery(event.target).attr('id').replace('a', '#');
     location.replace(fragment);
}

// names from authority files
function authorityNames(event) { //{{{
     var ddClass = 'dd.' + jQuery(event.target).attr('id');
     if (jQuery(ddClass).css('display') == 'none') {
          jQuery(ddClass).slideDown();
     } else {
          jQuery(ddClass).slideUp();
     }
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
     
     // set horizontal positions of DTs in level 1 list and mark first item as selected
     jQuery(d1).first().addClass(exp);
     jQuery(d1).each(function(i) {
          // set position
          jQuery(this).css('left', (i * width1) + 'em');
          // mark first child as selected
          jQuery(d2, jQuery(this).next('dd')).first().addClass(exp);
          // set horizontal positions of DTs in list below DD following current DT
          jQuery(d2, jQuery(this).next('dd')).each(function(j) {
               jQuery(this).css('left', (j * width2) + 'em');
          });
     });
     
     // line numbers for PRE
     jQuery('pre').each(function(i) {
          jQuery(this).html('<span class="line-number"></span>' + jQuery(this).html() + '<span class="cl"></span>');
          jQuery('span:first', jQuery(this)).html(jQuery.map(jQuery(this).html().split(/\n/), function(s, j) {
               return '<span>' + (j + 1) + '</span>';
          }).join(''));
     });
     
     // TEI overlay
     jQuery('a[rel]').overlay();
     
     // highlighting
     var hl = getUrlVars(window.location.href)['hl'];
     if (hl) {
          highlight(hl);
     }
     
     // hide authority file names
     jQuery('dd.auth_dd').hide();
     
     // targetting titles/authors in arabic/ottoman mlw2 http://stackoverflow.com/questions/15364298/make-jquerys-contains-select-only-exact-string there is a much more elegant way of doing this, I know. Is quick fix
     
     /*jQuery("dt").filter(function() { 
    return $(this).text() === "Title in Arabic" ;
     }).next().css("font-size", "2em");
      jQuery("dt").filter(function() { 
    return $(this).text() === "Title in Ottoman" ;
     }).next().css("font-size", "2em");
      jQuery("dt").filter(function() { 
    return $(this).text() === "Author in Arabic" ;
     }).next().css("font-size", "2em");
      jQuery("dt").filter(function() { 
    return $(this).text() === "Author in Ottoman" ;
     }).next().css("font-size", "2em");*/

});

//}}}
