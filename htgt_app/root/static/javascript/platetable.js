/* PlateTable - javascript to present plate data

Data provided in a normal HTML table concerning (96/384 well, etc) plates where one column contains a well identifier, typically of the format [alphabetical character][two digits] e.g. A11, P20, is parsed and a new table created with a grid layout representing the grid of the physical plate.

Author: David K Jackson <david.jackson@sanger.ac.uk>

Features:
  + toggle between showing orginal data table, plate layout and both
  + parse well/clone column for row, column, and potentially plate
    - cope with  96format_{1..4} 384 format. Note {5..8} indicating second plate
  + toggle between data column to display in plate layout
  + autodetect plate size from wellcol
  + finds all "platetable" tables
  + compatible with sorttable 

Todo develop:
  + check for Prototype
  + auto detect multiple entries for a well/ mutliple plates
  + cope with second (multiple) plate - put in second tbody?
  + potential for tables marked for this, also automatically find them and suitable well column
  + cope with multiple body data tables
  + ensure sorting by row or columns possible using tablekit,
  + padding for missing wells
  + show multiple column data in plate layout cells at same time 
    - function for list presentation done
  + cope with more than text in plate layout cells, particularly form fields?
  + colour by option - over data column range - e.g. by id, well id, counts, passes....

Revision:
  $Header$
*/

var PlateTable = Class.create();

PlateTable.prototype = {
  initialize : function (elm,options) {
    this.dataTable = $(elm);
    if(this.dataTable.tagName !== 'TABLE'){return;}
    //figure out if this table contains plate data and what size it is - or just use the options?
    this.nrow=0; this.ncol=0; this.wellcol=0;
    if(options && options.wellcol){
      this.wellcol=options.wellcol;
    }else{
      var wc=$A(this.dataTable.tHead.rows[0].cells).map(function(c){return c.hasClassName('wellcol')}).indexOf(true);
      if(wc>=0){this.wellcol=wc;}
    }
    if(options && options.type){
      switch(options.type){
        case '96well': this.nrow=8; this.ncol=12; break;
        case '384well': this.nrow=16; this.ncol=24; break;
        case '5by5': this.nrow=5; this.ncol=5; break;
      }
    }else{
      var h = PlateTable.Int.hashParseWell(this.dataTable,this.wellcol);
      this.nrow=h.nrow;
      this.ncol=h.ncol;
    }

    //create a wrapper div round the original table and add a new layout table in another div, put both in an outer div
    var wrapper = $(document.createElement('div'));
    this.dataTable.parentNode.replaceChild(wrapper,this.dataTable);
    var dtwrapper = $(document.createElement('div'));
    dtwrapper.appendChild(document.createElement('a').addClassName('button').update("toggle data view ").observe('click',this.toggleVisibility.bind(this)));
    dtwrapper.appendChild(this.dataTable);
    //new Insertion.After(this.dataTable,"<br><a href='javascript:$(\""+this.dataTable.id+"\").parentNode.toggleVisibility()'>toggle data view</a><br>");// only works in KHTML (and that iff wrapper extended below)
    this.layoutTable = $(document.createElement('table'));
    this.layoutTable.addClassName('platelayout');//unused
    var ltwrapper = $(document.createElement('div'));
    var sel = $(document.createElement('select'));
    sel.update($A(this.dataTable.tHead.rows[0].cells).map(function(c,i){return "<option>"+c.innerHTML+"</option>"})).observe('change',this.changeLayoutContentListener.bindAsEventListener(this));
    //this.layoutTable.tHead.rows[0].cells[0].appendChild(sel);
    ltwrapper.appendChild(sel);
    ltwrapper.appendChild(this.layoutTable);
    ltwrapper.appendChild(document.createElement('a').addClassName('button').update("toggle data view ").observe('click',this.toggleVisibility.bind(this)));
    ltwrapper.hide();
    PlateTable.Int.initialisePlateLayout(this.layoutTable,this.nrow,this.ncol);
    PlateTable.Int.refillPlateLayoutByWell(this.dataTable,this.wellcol,0,this.layoutTable);
    wrapper.appendChild(dtwrapper);
    wrapper.appendChild(document.createElement('a').addClassName('button').update("toggle data view ").observe('click',this.toggleVisibility.bind(this)));
    wrapper.appendChild(ltwrapper);
    wrapper.addClassName('PlateTable'); 
    //Object.extend(wrapper,this);//only works in KHTML?
  },
  toggleVisibility : function(){
    if(this.dataTable.parentNode.visible()){
      if(this.layoutTable.parentNode.visible()){
        this.layoutTable.parentNode.hide();
      }else{
        this.layoutTable.parentNode.show();
        this.dataTable.parentNode.hide();
      }
    }else{
      this.dataTable.parentNode.show();
    }
  },
  changeLayoutContentListener : function(event){
    PlateTable.Int.refillPlateLayoutByWell(this.dataTable,this.wellcol,event.currentTarget.selectedIndex,this.layoutTable);
  }
};

PlateTable.Int = {
  initialisePlateHeaderFooter: function (layoutTable,ncol){
	layoutTable.appendChild(document.createElement("tHead"));
	layoutTable.appendChild(document.createElement("tFoot"));
	layoutTable.tHead.appendChild(document.createElement("tr"));
	layoutTable.tFoot.appendChild(document.createElement("tr"));
	for(var ic=0; ic<ncol+2; ic++){
		var lh=document.createElement("th");
		var lf=document.createElement("th");
		if(ic>0 && ic<=ncol){
			lh.appendChild(document.createTextNode(ic));
			lf.appendChild(document.createTextNode(ic));
		}
		layoutTable.tHead.rows[0].appendChild(lh);
		layoutTable.tFoot.rows[0].appendChild(lf);
	}
  },
  iToLetter: ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P"],
  initialisePlateBody: function (layoutBody,nrow,ncol){
	for(var ir=0; ir<nrow; ir++){
		layoutBody.appendChild(document.createElement("tr"));
		for(var ic=0; ic<ncol+2; ic++){
			var l;
			if(ic>0 && ic<=ncol){
				l=document.createElement("td");
				l.appendChild(document.createTextNode(""));
			}else{
				l=document.createElement("th");
				l.appendChild(document.createTextNode(PlateTable.Int.iToLetter[ir]));
			}
			layoutBody.rows[ir].appendChild(l);
		}
	}
  },
  initialisePlateLayout: function (layoutTable,nrow,ncol){
	PlateTable.Int.initialisePlateHeaderFooter(layoutTable,ncol);
	layoutTable.appendChild(document.createElement("tBody"));
	PlateTable.Int.initialisePlateBody(layoutTable.tBodies[0],nrow,ncol);
  },
  parseWell: function (wellText){
    var wellRE=/((?:\S*[^A-Z])?)([A-P])(?:0)?(\d\d?)(?!\d)(_\d\d?)?\b/i; //plate, row, column, 96 to 384 convertor
    var t=wellRE.exec(wellText);
    if(t){
	var r = new Object();
	r.plate = t[1];
	r.row = t[2];
	r.col = t[3];
	if(t[4] && t[4].length>0){ //96 based 384 well nomenclature
		var i=t[4].substr(1)-1;//skip initial understore
		r.plate = r.plate+"("+(Math.floor(i/4)+1)+")";//how to int better?
		i=i%4;
		r.col = 1+(r.col-1)*2+i%2;
		r.row = PlateTable.Int.iToLetter[PlateTable.Int.letterToI[r.row]*2+Math.floor(i/2)];
	}
        r.well=r.row+r.col;
	return r;
   }
   return undefined;
  },
  hashParseWell: function (dataTable,wellCol){//iterate through cell in well column in table bodies and find all values for plate, row, col and well:
    var h = $H({plate:$H({}),col:$H({}),row:$H({}),well:$H({})});
    $A(dataTable.tBodies).map(
      function(b){return $A(b.rows);}
    ).flatten().map(
      function(r){return $A(r.cells)[wellCol];}
    ).compact().map(
      function(w){return PlateTable.Int.parseWell(w.innerHTML);}
    ).compact().each(
      function(w){$A(["plate","row","col","well"]).each(function(t){
        var wt= w[t];
        var v= h[t][wt];
        if(v){
          h[t][wt]++;
        }else{
          h[t][wt]=1;
        }
      })}
    );
    h.ncol=h.col.keys().compact().max(function(i){return i*1});
    h.nrow=1+h.row.keys().compact().max(function(r){return PlateTable.Int.letterToI[r]});
    return h;
  },
  letterToI: {A:0,B:1,C:2,D:3,E:4,F:5,G:6,H:7,I:8,J:9,K:10,L:11,M:12,N:13,O:14,P:15,a:0,b:1,c:2,d:3,e:4,f:5,g:6,h:7,i:8,j:9,k:10,l:11,m:12,n:13,o:14,p:15},
  refillPlateLayoutByWell: function (dataTable,wellCol,dataCol,layoutTable){
   for(var ir=0; ir<dataTable.tBodies[0].rows.length; ir++){
	var row = dataTable.tBodies[0].rows[ir].cells;
        var w = PlateTable.Int.parseWell(row[wellCol].innerHTML);
        if (w && w.row){
          var jr = PlateTable.Int.letterToI[w.row];
          var jc = w.col;
          $(layoutTable.tBodies[0].rows[jr].cells[jc]).update(row[dataCol].innerHTML);
	}
   }
  },
  refillPlateLayoutAllByWell: function (dataTable,wellCol,layoutTable){
   for(var ir=0; ir<dataTable.tBodies[0].rows.length; ir++){
	var row = $A(dataTable.tBodies[0].rows[ir].cells);
        var w = PlateTable.Int.parseWell(row[wellCol].innerHTML);
	if (w && w.row){
		var jr = PlateTable.Int.letterToI[w.row];
		var jc = w.col;
		$(layoutTable.tBodies[0].rows[jr].cells[jc]).update('<ul>' + row.map(function(c,i){return '<li class="col_' + i + '">'+c.innerHTML+'</li>'}).join("") + '</ul>');
	}
   }
  },
  refillPlateLayout: function (dataTable,rowCol,colCol,dataCol,layoutTable){
   for(var ir=0; ir<dataTable.tBodies[0].rows.length; ir++){
	var row = dataTable.tBodies[0].rows[ir].cells;
	var jr = PlateTable.Int.letterToI[row[rowCol].childNodes[0].nodeValue];
	var jc = row[colCol].childNodes[0].nodeValue * 1;
	//moves nodes! layoutTable.tBodies[0].rows[jr].cells[jc].appendChild(row[0].childNodes[0]);
	$(layoutTable.tBodies[0].rows[jr].cells[jc]).update(row[dataCol].innerHTML);
   }
  }
};
//end of PlateTable.Int


//look for suitable (with columnhide class) tables:
Event.observe(window, 'load', function() {$$('table[class~="platetable"]').each(
  function(t){new PlateTable(t)}
);});
