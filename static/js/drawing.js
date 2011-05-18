
const DRAWING_REFRESH = 5000;
const DRAWING_COLOR_GRID = '#444';
const DRAWING_COLOR_GRID_BOUDARIES = '#888';
const DRAWING_URL_LIST = "/api/drawing/list";

function Drawing( session, canvas_id ){
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
     * compute real_canvas size (square) depending on screen size
     */
    this.create_grid = function() {
	var ctx;
	var canvas;
	
	self.grid_canvas = document.createElement('canvas');
	self.grid_canvas.width = self.real_canvas.width;
	self.grid_canvas.height = self.real_canvas.height;
	canvas = self.grid_canvas;
	ctx = canvas.getContext("2d");

	for (var w=0; w <= (2 * this.zone_width); w++){
	    var column = Math.floor( w * self.zone_px_width );
	    ctx.moveTo(column, 0);
	    ctx.lineTo(column, canvas.height);
	}
	for (var h=0; h <= (2 * this.zone_height); h++){
	    var line = Math.floor(h * self.zone_px_height);
	    ctx.moveTo(0, line);
	    ctx.lineTo(canvas.width, line);
	}
	ctx.lineWidth = 1;
	ctx.strokeStyle = DRAWING_COLOR_GRID;
	ctx.stroke();

	ctx.beginPath();
	var boundaries = {
	    x : Math.floor( self.zone_width * self.zone_px_width / 2 ),
	    y : Math.floor( self.zone_height * self.zone_px_height / 2 ),
	    w : Math.floor( self.zone_width * self.zone_px_width ),
	    h : Math.floor( self.zone_height * self.zone_px_height )
	};
	ctx.lineWidth = 1;
	ctx.strokeStyle = DRAWING_COLOR_GRID_BOUDARIES;
	ctx.strokeRect( boundaries.x, boundaries.y, boundaries.w, boundaries.h );
    };


    this.draw_grid = function() {
	// apply grid canvas on the real canvas
	if ( self.grid_canvas == null ) {
	    self.create_grid();
	}
	var ctx = self.context;
	ctx.drawImage( self.grid_canvas, 0, 0);
    }

    this.update_size = function() {
	var real_canvas = this.real_canvas;
	var win = { 
	    w: $(window).width(),
	    h : $(window).height()
	};

	real_canvas.style.position = 'absolute';
	if (win.w > win.h) {
	    real_canvas.width = win.h - 20;
	    real_canvas.height = win.h - 20;
	} else {
	    real_canvas.width = win.w - 20;
	    real_canvas.height = win.w - 20;
	}
	real_canvas.style.top = '10px';
	real_canvas.style.left = Math.floor((win.w - real_canvas.width) / 2) + 'px';

	console.log("window.width = " + [ $(window).width(), $(window).height() ] );

	self.zone_px_width = real_canvas.width / (self.zone_width * 2);
	self.zone_px_height = real_canvas.height / (self.zone_height * 2);

	self.grid_canvas = null;

	var ctx = real_canvas.getContext("2d");
	ctx.fillStyle = '#000';
	ctx.fillRect(0, 0, real_canvas.width, real_canvas.height);

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
	var canvas = self.real_canvas;
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
	var rect = {
	    x : Math.floor( pos.x * self.zone_px_width + 1),
	    y : Math.floor( pos.y * self.zone_px_height + 1),
	    w : Math.floor( self.zone_px_width - 2 ),
	    h: Math.floor( self.zone_px_height - 2 )
	};

	ctx.fillStyle = '#f00';
	ctx.fillRect( rect.x, rect.y, rect.w, rect.h );
    };

    var canvas_event = function( event_obj ) {
	var canvas = self.real_canvas;

	event_obj.mouseX = event_obj.pageX - canvas.offsetLeft;
	event_obj.mouseY = event_obj.pageY - canvas.offsetTop;

	var func = self[event_obj.type];
	if (func) { func( event_obj ); }
	//console.log("clicked at %s,%s", mouseX, mouseY );
    };


    this.draw_enable = false;
    this.session = session;
    this.zone_width = this.session.zone_width;
    this.zone_height = this.session.zone_height;

    this.real_canvas_id = canvas_id;
    this.real_canvas = document.getElementById(canvas_id);

    this.grid_canvas = null;

    // size of zone's big pixels
    this.zone_px_width = 1;
    this.zone_px_height = 1;

    this.timer = window.setInterval( this.pull_patches, DRAWING_REFRESH );
    this.context = this.real_canvas.getContext('2d');


    this.real_canvas.addEventListener('mousedown', canvas_event, false);
    this.real_canvas.addEventListener('mouseup', canvas_event, false);
    this.real_canvas.addEventListener('mousemove', canvas_event, false);

    this.update_size();
    console.log("drawing_id = " + this.canvas_id);
}

