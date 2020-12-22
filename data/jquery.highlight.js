/*
 * jQuery Highlight plugin
 *
 * Based on highlight v3 by Johann Burkard
 * http://johannburkard.de/blog/programming/javascript/highlight-javascript-text-higlighting-jquery-plugin.html
 *
 * Code a little bit refactored and cleaned (in my humble opinion).
 * Most important changes:
 *  - has an option to highlight only entire words (wordsOnly - false by default),
 *  - has an option to be case sensitive (caseSensitive - false by default)
 *  - highlight element tag and class names can be specified in options
 *
 * Usage:
 *   // wrap every occurrance of text 'lorem' in content
 *   // with <span class='highlight'> (default options)
 *   $('#content').highlight('lorem');
 *
 *   // search for and highlight more terms at once
 *   // so you can save some time on traversing DOM
 *   $('#content').highlight(['lorem', 'ipsum']);
 *   $('#content').highlight('lorem ipsum');
 *
 *   // search only for entire word 'lorem'
 *   $('#content').highlight('lorem', { wordsOnly: true });
 *
 *   // don't ignore case during search of term 'lorem'
 *   $('#content').highlight('lorem', { caseSensitive: true });
 *
 *   // wrap every occurrance of term 'ipsum' in content
 *   // with <em class='important'>
 *   $('#content').highlight('ipsum', { element: 'em', className: 'important' });
 *
 *   // remove default highlight
 *   $('#content').unhighlight();
 *
 *   // remove custom highlight
 *   $('#content').unhighlight({ element: 'em', className: 'important' });
 *
 *
 * Copyright (c) 2009 Bartek Szopka
 *
 * Licensed under MIT license.
 *
 */

// find true start and length of section to highlight
// start and length of ASCII-folded strings might not be what they actually are
function locateMatch(str, falseStart, falseLength) {
     var trueStart = falseStart;
     var trueLength = falseLength;
     
     var s = 0, i;
     var foundStart = false;
     
     // loop over chars in string
     for (i = 0; i < str.length; ++ i) {
          var c = fixedCharCodeAt(str, i);
          
          if (!c) {
               continue;
          }
          
          // reached false start, so remember true start
          if (!foundStart && s == falseStart) {
               trueStart = i;
               foundStart = true;
               s = 0;
          }
          
          // reached false length, so break out of loop
          if (foundStart && s == falseLength) {
               break;
          }
          
          // does this character contribute to folded length
          s += (c < 128 && c != 45) ? 1 : replaceChar(c, false, '').length;
     }
     
     // broken out at falseLength or loop finished
     // either way, true length is final position minus true start
     trueLength = i - trueStart;

     return {'start': trueStart, 'length': trueLength };
}

jQuery.extend(
         {highlight: function (node, re, nodeName, className, foldable) {
              var r = 0;
              
              // text node
              if (node.nodeType === 3) {
                   var data = node.data;
                   var dataCopy = data;
                   
                   // ASCII-fold data?
                   if (foldable) {
                        data = fold(data);
                   }
                   
                   var match = data.match(re);
                   if (match) {
                        // create highlight span
                        var highlight = document.createElement(nodeName || 'span');
                        highlight.className = className || 'highlight';
                        
                        // locate true start and end of match
                        var locatedMatch = foldable ? 
                             locateMatch(node.data, match.index, match[0].length) : { 'start': match.index, 'length': match[0].length };
                        
                        // split node text at start and end of match
                        var wordNode = node.splitText(locatedMatch.start);
                        wordNode.splitText(locatedMatch.length);
                        
                        var wordClone = wordNode.cloneNode(true);
                        highlight.appendChild(wordClone);
                        wordNode.parentNode.replaceChild(highlight, wordNode);
                        
                        ++ r; //skip added node in parent
                   }
              }
              // element node
              else if ((node.nodeType === 1 && node.childNodes) && // only element nodes that have children
                         !/(script|style)/i.test(node.tagName) && // ignore script and style nodes
                         !(node.tagName === nodeName.toUpperCase() && node.className === className)) { // skip if already highlighted
                   for (var i = 0; i < node.childNodes.length; i++) {
                        i += jQuery.highlight(node.childNodes[i], re, nodeName, className, foldable);
                   }
              }
              
              return r;
         }
         });

jQuery.fn.unhighlight = function (options) {
    var settings = { className: 'highlight', element: 'span' };
    jQuery.extend(settings, options);

    return this.find(settings.element + "." + settings.className).each(function () {
        var parent = this.parentNode;
        parent.replaceChild(this.firstChild, this);
        parent.normalize();
    }).end();
};

// modified to expect a string with |s already there
jQuery.fn.highlight = function (words, options, foldable) {
     var settings = { className: 'highlight', element: 'span', caseSensitive: false, wordsOnly: true };
     jQuery.extend(settings, options);
     
     var flag = settings.caseSensitive ? "" : "i";
     
     // should ASCII-fold words before search
     if (foldable) {
          words = fold(words);
     }

     var pattern = '(' + words + ')';
     
     if (settings.wordsOnly) {
          pattern = "\\b" + pattern + "\\b";
     }
     
     var re = new RegExp(pattern, flag);
     
     return this.each(function () {
          jQuery.highlight(this, re, settings.element, settings.className, foldable);
     });
};
