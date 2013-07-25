/* TableColumnHide - provide collapsing and expanding of HTML table columns

Author: David K Jackson <david.jackson@sanger.ac.uk>

Features:
  + columns hideable by clicking on symbol in first row of tHead
  + hidden columns revealable by clicking on symbols in neighbouring columns
  + compatible with Kryogenix's sorttable
Todo:
  + work practically for large (>500) row tables
  + check for Prototype
  + ensure compatible with tablesort
Revision:
  $Header: /repos/cvs/gene_trap/src/HTGT/root/javascript/tablecolumnhide.js,v 1.2 2007/09/28 10:35:12 dj3 Exp $
*/

TableColumnHide = {
  getAllRows: function(t){
    return $A([$A([t.tHead]),$A([t.tFoot]),$A(t.tBodies)]).flatten().compact().map(function(b){return $A(b.rows)}).compact().flatten().compact();
  },
  hideColumn: function(t,ci){//table,column index 
    var r  = t.tHead.rows[0].cells;
    if($A(r).select(function(th){return $(th).visible()}).length>1){
      //add controls to expand the column
      if(ci){
        $(t.tHead.rows[0].cells[ci-1]).appendChild($(document.createElement('a')).update('&#187;').addClassName('tablecolumnhiderexpander').observe('click',function(e){TableColumnHide.showColumn(t,ci);Event.stop(e);}.bindAsEventListener()));
      }
      if(ci<r.length-1){
        var c = $(document.createElement('a')).update('&#171;&nbsp;').addClassName('tablecolumnhidelexpander').observe('click',function(e){TableColumnHide.showColumn(t,ci);Event.stop(e);}.bindAsEventListener());
        var e = $(t.tHead.rows[0].cells[ci+1]);
        if(e.firstChild){
          e.insertBefore(c,e.firstChild);
        }else{
          e.appendChild(c);
        }
      }
      //actually hide the column
      TableColumnHide.getAllRows(t).each(function(r){$(r.cells[ci]).hide();});
    }
  },
  showColumn: function(t,ci){//table,column index 
    TableColumnHide.getAllRows(t).each(function(r){$(r.cells[ci]).show();});
    //remove controls to expand the column
    var r  = t.tHead.rows[0].cells;
    if(ci<r.length-1){$(t.tHead.rows[0].cells[ci+1]).getElementsByClassName('tablecolumnhidelexpander').invoke('remove');}
    if(ci){$(t.tHead.rows[0].cells[ci-1]).getElementsByClassName('tablecolumnhiderexpander').invoke('remove');}
  },
  addHideLinks: function(t){
    $A(t.tHead.rows[0].cells).each(function(c,i){ c.appendChild($(document.createElement('a')).update('&nbsp;&macr;').addClassName('tablecolumnhidehider').observe('click',function(e){TableColumnHide.hideColumn(t,i);Event.stop(e);}.bindAsEventListener()));});
  }
}

//look for suitable (with columnhide class) tables:
Event.observe(window, 'load', function() {$$('table[class~="columnhide"]').each(
  function(t){TableColumnHide.addHideLinks(t)}
);});
