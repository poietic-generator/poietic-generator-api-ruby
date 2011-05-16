
const DRAWING_REFRESH = 5000;
const DRAWING_URL_LIST = "/api/drawing/list";

function Drawing( session_obj, canvas_id ){

    this.load_remote = function(){
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
    this.update_grid = function() {
	var ctx = this.context;
	var canvas = this.canvas_obj;

	ctx.fillStyle = '#000';
	ctx.fillRect(0, 0, canvas.width, canvas.height);
	var wshift = canvas.width / this.zone_width;
	var hshift = canvas.height / this.zone_height;
	console.log("wshift : "+wshift);
	for (var w=0; w <= this.zone_width; w++){
	    ctx.moveTo(w * wshift, 0);
	    ctx.lineTo(w * wshift, canvas.height);
	}
	for (var h=0; h <= this.zone_height; h++){
	    ctx.moveTo(0, h * hshift);
	    ctx.lineTo(canvas.width, h * hshift);
	}
	ctx.strokeStyle = '#444';
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
	this.update_grid();
    };


    this.mouseup = function( event_obj ) {
	this_drawing.draw_enable = false;

    };

    this.mousedown = function( event_obj ) {
	this_drawing.draw_enable = true;

    };

    this.mousemove = function( event_obj ) {
	var ctx = this_drawing.context;
	if (this_drawing.draw_enable) {
	    ctx.strokeStyle = '#f00';
	    ctx.strokeRect( event_obj.mouseX - 5, event_obj.mouseY - 5, 10, 10 );
	}
    };

    this.draw_enable = false;
    this.session_obj = session_obj;
    this.zone_width = this.session_obj.zone_width;
    this.zone_height = this.session_obj.zone_height;
    this.canvas_id = canvas_id;
    this.canvas_obj = document.getElementById(canvas_id);
    this.timer = window.setInterval( this.load_remote, DRAWING_REFRESH );
    this.context = this.canvas_obj.getContext('2d');

    var this_drawing = this;

    var canvas_event = function( event_obj ) {
	var canvas = this_drawing.canvas_obj;

	event_obj.mouseX = event_obj.pageX - canvas.offsetLeft;
	event_obj.mouseY = event_obj.pageY - canvas.offsetTop;

	var func = this_drawing[event_obj.type];
	if (func) { func( event_obj ); }
	//console.log("clicked at %s,%s", mouseX, mouseY );
    };

    this.canvas_obj.addEventListener('mousedown', canvas_event, false);
    this.canvas_obj.addEventListener('mouseup', canvas_event, false);
    this.canvas_obj.addEventListener('mousemove', canvas_event, false);

    this.update_size();
    console.log("drawing_id = " + this.canvas_id);
}

