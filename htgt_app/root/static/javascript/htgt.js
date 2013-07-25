/*
* New TableKit sortable type for Oracle date fields
*/

TableKit.Sortable.addSortType(
    new TableKit.Sortable.Type( 'date-oracle', {
        pattern: /\d{2}-\w{3}-\d{2}/i, // i.e. 12-SEP-07
        normal: function(v) {
            if ( v == '-' ) { return 0; }
			if(!this.pattern.test(v)) {return 0;}

            var r = v.match(/(\d{2})-(\w{3})-(\d{2})/);
            var day_num = parseInt(r[1]);
            var month_str = r[2].toUpperCase();
            var month_num = "";

            switch(month_str) {
                case "JAN": month_num = "00"; break;
                case "FEB": month_num = "01"; break;
                case "MAR": month_num = "02"; break;
                case "APR": month_num = "03"; break;
                case "MAY": month_num = "04"; break;
                case "JUN": month_num = "05"; break;
                case "JUL": month_num = "06"; break;
                case "AUG": month_num = "07"; break;
                case "SEP": month_num = "08"; break;
                case "OCT": month_num = "09"; break;
                case "NOV": month_num = "10"; break;
                case "DEC": month_num = "11"; break;
            }

            var year_num = r[3];
            if (parseInt(year_num) < 50) { year_num = '20' + year_num; }
            else                         { year_num = '19' + year_num; }

            return new Date(year_num, month_num, day_num).valueOf();
        }
    })
);

/*
* More TableKit Options
*/

TableKit.options.sortableSelector = 'tksort';
TableKit.Sortable.detectors = $w('date-oracle date-iso date date-eu date-au time currency datasize number casesensitivetext text');

/*
* Sort by column function for Well Tables (using TableKit)
*/

function sortByCol(tktable,wellcol) {
  //sort the underlying data
  var rows = TableKit.getBodyRows(tktable);
  rows.sort(
    function(a,b) {
      var ap=PlateTable.Int.parseWell(TableKit.getCellText(a.cells[wellcol]));
      var bp=PlateTable.Int.parseWell(TableKit.getCellText(b.cells[wellcol]));
      var r = ap.col-bp.col;
      if ( r != 0 ) {return r;}
      else if (ap.row>bp.row) {return 1;}
      else if (ap.row<bp.row) {return -1;}
      else if (ap.plate>bp.plate) {return 1;}
      else if (ap.plate<bp.plate) {return -1;}
      return 0;
    }
  );

  //display the sorted data
  tktable=$(tktable);
  var tb = tktable.tBodies[0];
  var op = TableKit.option('noSortClass descendingClass ascendingClass', tktable.id);
  var tkr = TableKit.Rows;
  rows.each(
    function(r,i) {
      tb.appendChild(r);
      tkr.addStripeClass(tktable,r,i);
    }
  );

  //clean out any classes indicating previous sort
  var hcells = TableKit.getHeaderCells(tktable);
  $A(hcells).each(
      function(c,i) {
          c = $(c);
          c.removeClassName(op.ascendingClass);
          c.removeClassName(op.descendingClass);
      }
  );
}

/*
 * Function to allow us to put text in input boxes 
 * (i.e. user prompts) that dissapears on activation...
 */

var active_color = '#000'; // Colour of user provided text
var inactive_color = '#999'; // Colour of default text

document.observe("dom:loaded", function() {
    var default_values = new Array();
    $$("input.default-value").each( function (s) {
        $(s).setStyle({ color: inactive_color });
        if(s.title && ! s.value){s.value=s.title}
        $(s).observe( 'focus', function () {
            if (!default_values[s.id]) {
                default_values[s.id] = s.value;
            }
            if (s.value == default_values[s.id]) {
                s.value = '';
                $(s).setStyle({ color: active_color });
            }
            $(s).observe( 'blur', function () {
                if (s.value == '') {
                    $(s).setStyle({ color: inactive_color });
                    s.value = default_values[s.id];
                }
            });
        });
    });
});

/*
 * Function to allow us to make fieldsets hideable...
 */

document.observe("dom:loaded", function() { loadToggleable(); });

function loadToggleable() {
    // Fieldsets...
    $$('fieldset.toggleable').each( function (s) {
        var toggle = $(s).select('legend')[0];
        var element = $(s).select('div')[0];
        
        if( $(element).visible() ) {
            //"dom:loaded" seems to be firing twice - try here to avoid adding multiple observers
            //console.log(element.id+" NOT hidden - attaching observer\n");
            $(element).hide();
            $(toggle).setAttribute("class", "option_hidden");
            $(toggle).setAttribute("className", "option_hidden");
            $(toggle).setAttribute("title", "Click to open");
            
            $(toggle).observe('click', function() {
                if ( ! $(element).visible() ) {
                    new Effect.BlindDown(element, { duration: .3 });
                    $(toggle).setAttribute("class", "option_show");
                    $(toggle).setAttribute("className", "option_show");
                    $(toggle).setAttribute("title", "Click to hide");
                } else {
                    new Effect.BlindUp(element, { duration: .3 });
                    $(toggle).setAttribute("class", "option_hidden");
                    $(toggle).setAttribute("className", "option_hidden");
                    $(toggle).setAttribute("title", "Click to open");
                }
            });
        } else {
            //console.log(element.id+" already hidden - not attaching observer\n");
        }
    });
    
    // Divs...
    $$('div.toggleable').each( function (s) {
        var toggle = $(s).select('.toggle-control')[0];
        var element = $(s).select('.toggle-content')[0];
        
        if ( toggle && element ) {
            
            //console.log( toggle.innerHTML + " - attaching observer...\n" );
            
            if ( ! $(s).hasClassName('default-open') ) {
                $(element).hide();
                $(toggle).setAttribute("class", "option_hidden");
                $(toggle).setAttribute("className", "option_hidden");
                $(toggle).setAttribute("title", "Click to open");
            } else {
                $(toggle).setAttribute("class", "option_show");
                $(toggle).setAttribute("className", "option_show");
                $(toggle).setAttribute("title", "Click to hide");
            }
            
            $(toggle).observe('click', function() {
                if ( ! $(element).visible() ) {
                    new Effect.BlindDown(element, { duration: .3 });
                    $(toggle).setAttribute("class", "option_show");
                    $(toggle).setAttribute("className", "option_show");
                    $(toggle).setAttribute("title", "Click to hide");
                } else {
                    new Effect.BlindUp(element, { duration: .3 });
                    $(toggle).setAttribute("class", "option_hidden");
                    $(toggle).setAttribute("className", "option_hidden");
                    $(toggle).setAttribute("title", "Click to open");
                }
            });
        }
    });
}
