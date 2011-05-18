
const DRAWING_REFRESH = 5000;
const DRAWING_COLOR_GRID = '#444';
const DRAWING_COLOR_GRID_BOUDARIES = '#844';
const DRAWING_URL_LIST = "/api/drawing/list";

function Drawing( session_obj, canvas_id ){
    var self = this;

    this.pull_patches = function(){
		$.ajax({
		    // FIXME: request with previous user_id
		    url: DRAWING_URL_LIST,
		    dataType: "json",
		    type: 'GET',
		    context: this,
		    success: function( response ){
			// FIXME: set cookie with user_id for next time
			console.log('drawing/list response : ' + JSON.stringify(response) );

			callback( this );
		    }
		});
    }

    /*
     * compute canvas_obj size (square) depending on screen size
     */
    this.draw_grid = function() {
	var ctx = self.context;
	var canvas = self.canvas_obj;

	ctx.fillStyle = '#000';
	ctx.fillRect(0, 0, canvas.width, canvas.height);
	for (var w=0; w <= (2 * this.zone_width); w++){
	    ctx.moveTo(w * self.zone_px_width, 0);
	    ctx.lineTo(w * self.zone_px_width, canvas.height);
	}
	for (var h=0; h <= (2 * this.zone_height); h++){
	    ctx.moveTo(0, h * self.zone_px_height);
	    ctx.lineTo(canvas.width, h * self.zone_px_height);
	}
	ctx.strokeStyle = DRAWING_COLOR_GRID;
	ctx.stroke();

	ctx.beginPath();
	boundaries = {
	    x : self.zone_width * self.zone_px_width / 2,
	    y : self.zone_height * self.zone_px_height / 2,
	    w : self.zone_width * self.zone_px_width,
	    h : self.zone_height * self.zone_px_height
	};
	ctx.lineWidth = 5;
	ctx.strokeRect( boundaries.x, boundaries.y, boundaries.w, boundaries.h );
	ctx.strokeStyle = DRAWING_COLOR_GRID_BOUDARIES;
	ctx.stroke();
    };

    this.update_size = function() {
	var canvas = this.canvas_obj;
	var win = { 
	    w: $(window).width(),
	    h : $(window).height()
	};

	canvas.style.position = 'absolute';
	if (win.w > win.h) {
	    canvas.width = win.h - 20;
	    canvas.height = win.h - 20;
	} else {
	    canvas.width = win.w - 20;
	    canvas.height = win.w - 20;
	}
	canvas.style.top = '10px';
	canvas.style.left = Math.floor((win.w - canvas.width) / 2) + 'px';

	console.log("window.width = " + [ $(window).width(), $(window).height() ] );

	self.zone_px_width = canvas.width / (self.zone_width * 2);
	self.zone_px_height = canvas.height / (self.zone_height * 2);

	this.draw_grid();
    };


    this.mouseup = function( event_obj ) {
	self.draw_enable = false;

    };

    this.mousedown = function( event_obj ) {
	self.draw_enable = true;


	self.mousemove( event_obj );
    };

    this.mousemove = function( event_obj ) {
	var ctx = self.context;
	var canvas = self.canvas_obj;
	if (self.draw_enable) {
		var zonecoord = {
			x : Math.floor(event_obj.mouseX / self.zone_px_width ) ,
			y : Math.floor(event_obj.mouseY / self.zone_px_height )
		};

		console.log( "zonecoord : %s %s", zonecoord.x, zonecoord.y );
		// FIXME: write coordinate conversion functions
		// FIXME: write coodinates & boundaries verification functions
		if ( ( zonecoord.x >= ( self.zone_width / 2) ) 
			&& ( zonecoord.x < (( self.zone_width / 2 ) + self.zone_width ) )
			&& ( zonecoord.y >= ( self.zone_height / 2) ) 
			&& ( zonecoord.y < (( self.zone_height / 2 ) + self.zone_height ) ) )
		  {
		    self.set_pixel( zonecoord );
		} else {
		    self.get_pixel( zonecoord );
		}

		//ctx.strokeStyle = '#0f0';
		//ctx.strokeRect( event_obj.mouseX - 1, event_obj.mouseY - 1, 1, 1 );
	}
    };

    this.get_pixel = function( pos ) {
    }

    this.set_pixel = function( pos ) {
	var ctx = self.context;
	var xmin = pos.x * self.zone_px_width;
	var ymin = pos.y * self.zone_px_height;

	ctx.fillStyle = '#f00';
	ctx.fillRect( xmin, ymin, self.zone_px_width, self.zone_px_height );
    };

    var canvas_event = function( event_obj ) {
	var canvas = self.canvas_obj;

	event_obj.mouseX = event_obj.pageX - canvas.offsetLeft;
	event_obj.mouseY = event_obj.pageY - canvas.offsetTop;

	var func = self[event_obj.type];
	if (func) { func( event_obj ); }
	//console.log("clicked at %s,%s", mouseX, mouseY );
    };


    this.draw_enable = false;
    this.session_obj = session_obj;
    this.zone_width = this.session_obj.zone_width;
    this.zone_height = this.session_obj.zone_height;
    this.canvas_id = canvas_id;
    this.canvas_obj = document.getElementById(canvas_id);

    // size of zone's big pixels
    this.zone_px_width = 1;
    this.zone_px_height = 1;

    this.timer = window.setInterval( this.pull_patches, DRAWING_REFRESH );
    this.context = this.canvas_obj.getContext('2d');


    this.canvas_obj.addEventListener('mousedown', canvas_event, false);
    this.canvas_obj.addEventListener('mouseup', canvas_event, false);
    this.canvas_obj.addEventListener('mousemove', canvas_event, false);

    this.update_size();
    console.log("drawing_id = " + this.canvas_id);
}

