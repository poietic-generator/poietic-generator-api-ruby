
// vim: set ts=4 sw=4 et:
"use strict";

const DRAWING_REFRESH = 5000;
const DRAWING_GRID_COLOR = '#444';
const DRAWING_GRID_WIDTH = 0.5;
const DRAWING_BOUNDARIES_COLOR = '#888';
const DRAWING_BOUNDARIES_WIDTH = 2;
const DRAWING_URL_LIST = "/api/drawing/list";


function Drawing( p_session, p_canvas_id ){
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

        for (var w=0; w <= (2 * this.px_width); w++){
            var column = Math.floor( w * self.division_width );
            ctx.moveTo(column, 0);
            ctx.lineTo(column, canvas.height);
        }
        for (var h=0; h <= (2 * this.px_height); h++){
            var line = Math.floor(h * self.division_height);
            ctx.moveTo(0, line);
            ctx.lineTo(canvas.width, line);
        }
        ctx.lineWidth = DRAWING_GRID_WIDTH;
        ctx.strokeStyle = DRAWING_GRID_COLOR;
        ctx.stroke();

        ctx.beginPath();
        var boundaries = {
            x : Math.floor( self.px_width * self.division_width / 2 ),
            y : Math.floor( self.px_height * self.division_height / 2 ),
            w : Math.floor( self.px_width * self.division_width ),
            h : Math.floor( self.px_height * self.division_height )
        };
        ctx.lineWidth = DRAWING_BOUNDARIES_WIDTH;
        ctx.strokeStyle = DRAWING_BOUNDARIES_COLOR;
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

        self.division_width = real_canvas.width / (self.px_width * 2);
        self.division_height = real_canvas.height / (self.px_height * 2);

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
                x : Math.floor(event_obj.mouseX / self.division_width ) ,
                y : Math.floor(event_obj.mouseY / self.division_height )
            };

            console.log( "zonecoord : %s %s", zonecoord.x, zonecoord.y );
            // FIXME: write coordinate conversion functions
            // FIXME: write coodinates & boundaries verification functions
            if ( ( zonecoord.x >= ( self.px_width / 2) ) 
                    && ( zonecoord.x < (( self.px_width / 2 ) + self.px_width ) )
                    && ( zonecoord.y >= ( self.px_height / 2) ) 
                    && ( zonecoord.y < (( self.px_height / 2 ) + self.px_height ) ) )
            {
                self.pixel_set( zonecoord );
            } else {
                self.pixel_get( zonecoord );
            }
        }
    };

    this.pixel_get = function( pos ) {
        return matrix.pixel_get( pos );
    }

    this.pixel_set = function( pos ) {
        matrix.pixel_set( pos, color );
        var ctx = self.context;
        var rect = {
            x : Math.floor( pos.x * self.division_width + 1),
            y : Math.floor( pos.y * self.division_height + 1),
            w : Math.floor( self.division_width - 2 ),
            h: Math.floor( self.division_height - 2 )
        };

        ctx.fillStyle = self.color;
        ctx.fillRect( rect.x, rect.y, rect.w, rect.h );

        // add to patch structure
        self.patch_create();
        self.patch.append( pos );
    };

    this.patch_create = function() {
        if ( self.patch == null ) {
            self.patch = new Patch();
            window.setTimeout( self.patch_enqueue, PATCH_LIFESPAN );
        }
    }

    // push the patch appart, in the send queue
    this.patch_enqueue = function() {
        console.log( "patch enqueued !" );

        self.patch = null;
    }

    var canvas_event = function( event_obj ) {
        var canvas = self.real_canvas;

        event_obj.mouseX = event_obj.pageX - canvas.offsetLeft;
        event_obj.mouseY = event_obj.pageY - canvas.offsetTop;

        var func = self[event_obj.type];
        if (func) { func( event_obj ); }
        //console.log("clicked at %s,%s", mouseX, mouseY );
    };

    var matrix = new ColorMatrix( p_session.division_width, p_session.division_height );

    this.color = '#f00';
    this.patch = null;
    this.draw_enable = false;
    this.session = p_session;
    this.px_width = p_session.px_width;
    this.px_height = p_session.px_height;

    this.real_canvas = document.getElementById( p_canvas_id );

    this.grid_canvas = null;

    // size of zone's big pixels
    this.division_width = 1;
    this.division_height = 1;

    this.timer = window.setInterval( this.pull_patches, DRAWING_REFRESH );
    this.context = this.real_canvas.getContext('2d');

    this.real_canvas.addEventListener( 'mousedown', canvas_event, false );
    this.real_canvas.addEventListener( 'mouseup', canvas_event, false );
    this.real_canvas.addEventListener( 'mousemove', canvas_event, false );

    this.update_size();
    console.log("drawing_id = " + p_canvas_id);
}

