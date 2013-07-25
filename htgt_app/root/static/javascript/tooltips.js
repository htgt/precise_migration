// Tooltips Class
// A superclass to work with simple CSS selectors
var Tooltips = Class.create();
Tooltips.prototype = {
    initialize: function(selector, options) {
        var tooltips = $$(selector);
        tooltips.each( function(tooltip) {
            new Tooltip(tooltip, options);
        });
    }
};
// Tooltip Class
var Tooltip = Class.create();
Tooltip.prototype = {
    initialize: function(el, options) {
        this.el = $(el);
        this.initialized = false;
        this.tooltip_hover = false;
        this.setOptions(options);
        
        // Event handlers, we also create some later for the tooltip
        this.showEvent = this.show.bindAsEventListener(this);
        this.hideEvent = this.hide.bindAsEventListener(this);
        this.updateEvent = this.update.bindAsEventListener(this);
        Event.observe(this.el, "mouseover", this.showEvent );
        Event.observe(this.el, "mouseout", this.hideEvent );
        
        // Content for Tooltip is either given through 
        // 'content' option or 'title' attribute of the trigger element. If 'content' is present, then 'title' attribute is ignored.
        // 'content' is an element or the id of an element from which the innerHTML is taken as content of the tooltip
        if (options && options['content']) {
            this.content = $(options['content']).innerHTML;
        } else {
            this.content = this.el.title.stripScripts().strip();
        }
        // Removing title from DOM element to avoid showing it
        this.content = this.el.title.stripScripts().strip();
        this.el.title = "";

        // If descendant elements has 'alt' attribute defined, clear it
        this.el.descendants().each(function(el){
            if(Element.readAttribute(el, 'alt'))
                el.alt = "";
        });
    },
    setOptions: function(options) {
        this.options = {
            backgroundColor: '#E5F6FE', // Default background color
            borderColor: '#ADD9ED', // Default border color
            textColor: '#5E99BD', // Default text color (use CSS value)
            textShadowColor: '', // Default text shadow color (use CSS value)
            maxWidth: 350,  // Default tooltip width
            align: "left", // Default align
            delay: 50, // Default delay before tooltip appears in ms
            hideDelay: 800,
            mouseFollow: false, // Tooltips follows the mouse moving
            opacity: 1.0, // Default tooltips opacity
            appearDuration: .25, // Default appear duration in sec
            hideDuration: .25 // Default disappear duration in sec
        };
        Object.extend(this.options, options || {});
    },
    show: function(e) {
        this.xCord = Event.pointerX(e);
        this.yCord = Event.pointerY(e);
        if(!this.initialized)
            this.timeout = window.setTimeout(this.appear.bind(this), this.options.delay);
        else
          this._clearTimeout(this.timeout);
    },
    hide: function(e) {
        //wait before we go disappearing
        this._clearTimeout(this.timeout); //just in case
        this.timeout = window.setTimeout(this._hide.bind(this), this.options.hideDelay);
    },
    _hide: function(e) {
        //if we're on the hover then don't hide just yet.
        
        if(this.tooltip_hover) {
            return;
        }

        if(this.initialized) {
            this.appearingFX.cancel();
            if(this.options.mouseFollow)
                Event.stopObserving(this.el, "mousemove", this.updateEvent);
            new Effect.Fade(this.tooltip, {duration: this.options.hideDuration, afterFinish: function() { if(this.tooltip.parentNode != null) Element.remove(this.tooltip) }.bind(this) });
        }
        
        this._clearTimeout(this.timeout); //just in case
        
        this.initialized = false;
    },
    update: function(e){
        this.xCord = Event.pointerX(e);
        this.yCord = Event.pointerY(e);
        this.setup();
    },
    appear: function() {
        //here we basically create a new element each time which is pretty silly as all our tips are static
        //We really should just hide/show after creating, but such is the throwaway society we live in

        // Building tooltip container, do all CSS inline
        this.tooltip = new Element("div", { 
                                                className: "tooltip", 
                                                style: "display: none;" +
                                                       "position: absolute!important;" +
                                                       "overflow: hidden;" +
                                                       "font-size: 12px;" +
                                                       "z-index: 10000!important;" 
                                          });
        
        var content = new Element("div", { 
                                                className: "xboxcontent", 
                                                style: "background-color:" + this.options.backgroundColor + ";" +
                                                       "border-color:" + this.options.borderColor + ";" +
                                                       "padding: 10px;" +
                                                       "font-family: Arial,Helvetica,Sans-serif;"
                                         }).update(this.content);
            
        // Building and injecting tooltip into DOM
        //this.tooltip.insert(arrow).insert(top).insert(content).insert(bottom);
        this.tooltip.insert(content);
        $(document.body).insert({'top':this.tooltip});

        //hack to allow mouse over on tooltip to remain visible
        //we must bind so they have access to _clearTimeout and stuff
        this.tipShowEvent = this.tooltipHover.bindAsEventListener(this);
        this.tipHideEvent = this.tooltipHoverOut.bindAsEventListener(this);
        Event.observe(this.tooltip, "mouseenter", this.tipShowEvent);
        Event.observe(this.tooltip, "mouseleave", this.tipHideEvent);
        
        Element.extend(this.tooltip); // IE needs element to be manually extended
        this.options.width = this.tooltip.getWidth() + 1; // Quick fix for Firefox 3
        this.tooltip.style.width = this.options.width + 'px'; // IE7 needs width to be defined
        
        this.setup();
        
        if(this.options.mouseFollow)
            Event.observe(this.el, "mousemove", this.updateEvent);
            
        this.initialized = true;
        this.appearingFX = new Effect.Appear(this.tooltip, {duration: this.options.appearDuration, to: this.options.opacity });
    },
    setup: function(){
        // If content width is more then allowed max width, set width to max
        if(this.options.width > this.options.maxWidth) {
            this.options.width = this.options.maxWidth;
            this.tooltip.style.width = this.options.width + 'px';
        }
            
        // Tooltip doesn't fit the current document dimensions
        if(this.xCord + this.options.width >= Element.getWidth(document.body)) {
            this.options.align = "right";
            this.xCord = this.xCord - this.options.width + 20;
        } else {
            this.options.align = "left";
        }
        
        this.tooltip.style.left = this.xCord - 7 + "px";
        this.tooltip.style.top = this.yCord + 12 + "px";
    },
    tooltipHover: function(e) {
        //this function stops the tooltip from hiding if we mouse into it
        this.tooltip_hover = true;
        //we've hovered over so cancel any scheduled hide calls.
        //this._clearTimeout(this.timeout); 
    },
    tooltipHoverOut: function(e) {
        //this will do a delayed hide of the tooltip
        this.tooltip_hover = false;
        this.hide();
    },
    _clearTimeout: function(timer) {
        //cancel any pending timeout actions
        clearTimeout(timer);
        clearInterval(timer);
        return null;
    }
};