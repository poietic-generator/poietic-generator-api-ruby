
// vim: set ts=4 sw=4 et:
"use strict";

const DRAWING_REFRESH = 5000;
const DRAWING_GRID_COLOR = '#444';
const DRAWING_GRID_WIDTH = 0.5;
const DRAWING_BOUNDARIES_COLOR = '#888';
const DRAWING_BOUNDARIES_WIDTH = 2;
const DRAWING_URL_LIST = "/api/drawing/list";

const POSITION_TYPE_DRAWING = 0;
const POSITION_TYPE_ZONE = 0;

function Drawing( p_session, p_canvas_id ){
    var self = this;

    this.pull_patches = function(){
        $.ajax({
            // FIXME: request with previous user_id
            url: DRAWING_URL_LIST,
            dataType: "json",
            type: 'GET',
            context: self,
            success: function( response ){
                // FIXME: set cookie with user_id for next time
                console.log('drawing/list response : ' + JSON.stringify(response) );

                callback( self );
            }
        });
    }

    /** 
     * Convert local grid to canvas position
     */
    function local_to_canvas_position( local_position ) {
        return {
            x: Math.floor( local_position.x * self.column_size ),
            y: Math.floor( local_position.y * self.line_size )
        };
    }

    /**
     * Convert canvas to local position
     */
    function canvas_to_local_position( canvas_position ){
        return {
            x: Math.floor( canvas_position.x / self.column_size ),
            y: Math.floor( canvas_position.y / self.line_size )
        };
    }

    /** 
     * Convert local grid to zone position
     */
    function local_to_zone_position( local_position ){
        return { 
            x: local_position.x - self.border_column_count, 
            y: local_position.y - self.border_line_count 
        };
    }

    /** 
     * Convert zone to local grid position
     */
    function zone_to_local_position( zone_position ) {
        return { 
            x: zone_position.x + self.border_column_count, 
            y: zone_position.y + self.border_line_count 
        };
    }

    /**
     * Get relative zone position
     */
    function relative_position( zone_position, zone ) {
        // FIXME: implement relative zone position
        return { x: 0, y: 0 };
    }

    /*
     * draw zone grid
     */
    this.draw_grid = function() {
        // apply grid canvas on the real canvas
        var grid_ctx;
        var canvas;
        var ctx = self.context;

        // create grid if none exist
        if ( self.grid_canvas == null ) {
            self.grid_canvas = document.createElement('canvas');
            self.grid_canvas.width = self.real_canvas.width;
            self.grid_canvas.height = self.real_canvas.height;
            canvas = self.grid_canvas;
            grid_ctx = canvas.getContext("2d");

            console.log("drawing/draw_grid: before lines");

            var w_max = self.column_count + (2 * self.border_column_count);
            for (var w=0; w <= w_max; w++){
                var local_pos = { 'x': w, 'y': 0 };
                var canvas_pos = local_to_canvas_position( local_pos );
                grid_ctx.moveTo(canvas_pos.x, 0);
                grid_ctx.lineTo(canvas_pos.x, canvas.height);
            }
            var h_max = self.line_count + (2 * self.border_line_count);
            for (var h=0; h <= h_max; h++){
                var local_pos = { 'x': 0, 'y': h };
                var canvas_pos = local_to_canvas_position( local_pos );
                grid_ctx.moveTo(0, canvas_pos.y);
                grid_ctx.lineTo(canvas.width, canvas_pos.y);
            }
            grid_ctx.lineWidth = DRAWING_GRID_WIDTH;
            grid_ctx.strokeStyle = DRAWING_GRID_COLOR;
            grid_ctx.stroke();

            grid_ctx.beginPath();
            var local_tl = {
                x : self.border_column_count,
                y : self.border_line_count
            };
            var canvas_tl =  local_to_canvas_position( local_tl );
            canvas_tl.w = Math.floor( self.column_count * self.column_size );
            canvas_tl.h = Math.floor( self.line_count * self.line_size );

            grid_ctx.lineWidth = DRAWING_BOUNDARIES_WIDTH;
            grid_ctx.strokeStyle = DRAWING_BOUNDARIES_COLOR;
            grid_ctx.strokeRect( canvas_tl.x, canvas_tl.y, canvas_tl.w, canvas_tl.h );
        } 
        ctx.drawImage( self.grid_canvas, 0, 0);
    }

    this.update_paint = function() {
        // FIXME: use zone & repaint current 
        // FIXME: fix zone coordinate translation
        /*
        for (var x = 0 ; x < self.column_count ; x++ ){
            for (var y = 0; y < self.line_count ; y++ ) {
                var pos = { 'x': x, 'y': y };
                var color = zone.pixel_get( pos );
                self.pixel_draw( pos, color );
            }
        }
        */
    }

    this.update_size = function() {
        var real_canvas = self.real_canvas;
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

        console.log("real_canvas.width = " + real_canvas.width);
        self.column_size = real_canvas.width / (self.column_count + (self.border_column_count * 2));
        self.line_size = real_canvas.height / (self.line_count + (self.border_line_count * 2));

        console.log("column_size = " + self.column_size);

        self.grid_canvas = null;

        var ctx = real_canvas.getContext("2d");
        ctx.fillStyle = '#000';
        ctx.fillRect(0, 0, real_canvas.width, real_canvas.height);

        self.draw_grid();
    };


    /** 
     * Handle mouse event
     */
    this.mouseup = function( event_obj ) {
        self.move.enable = false;
    };

    /** 
     * Handle mouse event
     */
    this.mousedown = function( event_obj ) {
        self.move.enable = true;
        self.mousemove( event_obj );
    };



    /** 
     * Handle mouse event
     */
    this.mousemove = function( event_obj ) {
        var ctx = self.context;
        var canvas = self.real_canvas;

        if (self.move.enable) {
            var canvas_pos = { x: event_obj.mouseX, y: event_obj.mouseY };
            var local_pos = canvas_to_local_position( canvas_pos );
            var zone_pos = local_to_zone_position( local_pos );
            console.log( "canvas pos : %s", JSON.stringify( canvas_pos ) );
            console.log( "local pos : %s", JSON.stringify( local_pos ) );
            console.log( "zone pos : %s", JSON.stringify( zone_pos ) );

            // FIXME: detect target zone
            // target_zone = local_to_target_ f( zone_pos )
            var bound = zone.is_bound( zone_pos );
            console.log( "zone bound : %s", bound );

            if ( bound ) {
                self.pixel_set( local_pos, _color );
            } else {
                //FIXME: _color = zone.pixel_get( zone_pos );
            }

        }
    };

    // change pixel at given position, on canvas only
    this.pixel_draw = function( local_pos, color ) {
        var ctx = self.context;
        console.log("drawing/pixel_draw local_pos = %s", JSON.stringify(local_pos) );
        var canvas_pos = local_to_canvas_position( local_pos );
        var rect = {
            x : canvas_pos.x + 1,
            y : canvas_pos.y + 1,
            w : self.column_size - 2,
            h : self.line_size - 2
        };
        console.log("drawing/pixel_draw rect = %s", JSON.stringify(rect) );

        ctx.fillStyle = color;
        ctx.fillRect( rect.x, rect.y, rect.w, rect.h );
    }

    /*
     * Set pixel at given position to given color
     */
    this.pixel_set = function( local_pos, color ) {
        var zone_pos;

        zone_pos = local_to_zone_position( local_pos );
        console.log( "session/pixel_set: zone_pos = %s", zone_pos );
        zone.pixel_set( zone_pos, color );
        self.pixel_draw( local_pos, color );

        // add to patch structure
        //self.patch_create();
        //self.patch.append( pos );
    };

    /**
     * Pick color of pixel
     */
    this.pixel_get = function( local_pos ) {
        //FIXME: detect bound zone...
        //_return zone.pixel_get( pos );
    }


    this.patch_create = function() {
        if ( self.patch == null ) {
            self.patch = new Patch();
            window.setTimeout( self.patch_enqueue, PATCH_LIFESPAN );
        }
    }

    // push the patch appart, in the send queue
    this.patch_enqueue = function() {
        // FIXME: enqueue patch
        console.log( "patch enqueued !" );

        self.patch = null;
    }

    var canvas_event = function( event_obj ) {
        var canvas = self.real_canvas;

        event_obj.mouseX = event_obj.pageX - canvas.offsetLeft;
        event_obj.mouseY = event_obj.pageY - canvas.offsetTop;

        var func = self[event_obj.type];
        if (func) { func( event_obj ); }
        // console.log("clicked at %s,%s", mouseX, mouseY );
    };

    this.to_s = function() { JSON.stringify(this); };

    var zone = new Zone( p_session.zone_column_count, p_session.zone_line_count );
    var _color = '#f00';

    this.patch = null;
    this.move = { 
        enable : false
    }
    this.session = p_session;
    this.column_count = p_session.zone_column_count;
    this.line_count = p_session.zone_line_count;
    this.border_column_count = p_session.zone_column_count / 2;
    this.border_line_count = p_session.zone_column_count / 2;

    this.real_canvas = document.getElementById( p_canvas_id );

    this.grid_canvas = null;

    // size of zone's big pixels
    this.column_size = 1;
    this.line_size = 1;

    this.timer = window.setInterval( this.pull_patches, DRAWING_REFRESH );
    this.context = this.real_canvas.getContext('2d');

    // plug some event handlers
    this.real_canvas.addEventListener( 'mousedown', canvas_event, false );
    this.real_canvas.addEventListener( 'mouseup', canvas_event, false );
    this.real_canvas.addEventListener( 'mousemove', canvas_event, false );
    $(window).resize(function() {
        self.update_size();
        self.update_paint();
    });

    this.update_size();
    this.update_paint();
    console.log("drawing_id = " + p_canvas_id);
}

