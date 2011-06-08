
// vim: set ts=4 sw=4 et:
"use strict";

var EDITOR_GRID_COLOR = '#444';
var EDITOR_GRID_WIDTH = 0.5;
var EDITOR_BOUNDARIES_COLOR = '#888';
var EDITOR_BOUNDARIES_WIDTH = 2;

var POSITION_TYPE_DRAWING = 0;
var POSITION_TYPE_ZONE = 0;

function Editor( p_session, p_board, p_canvas_id ){
    //var console = { log: function() {} };

    var self = this;

    var _session;
    var _enqueue_timer;
    var _board;
    var _zone;
    var _color;
    var _pencil_move;
    var _real_canvas;
    var _grid_canvas;
    var _column_size;
    var _line_size;

    this.column_count = null;
    this.line_count = null;
    this.border_column_count = null;
    this.border_line_count = null;

    this.column_size = null;
    this.line_size = null;

    this.context = null;


    /**
     * Constructor
     */
    this.initialize = function( p_session, p_board, p_canvas_id ) {
        _zone = new Zone( p_session.zone_column_count, p_session.zone_line_count );
        _color = '#f00';

        _pencil_move = {
            enable : false
        }

        _session = p_session;
        _session.register( self );

        self.column_count = p_session.zone_column_count;
        self.line_count = p_session.zone_line_count;
        self.border_column_count = p_session.zone_column_count / 4;
        self.border_line_count = p_session.zone_column_count / 4;

        _real_canvas = document.getElementById( p_canvas_id );
        _grid_canvas = null;

        // size of editor's big pixels
        self.column_size = 1;
        self.line_size = 1;

        _enqueue_timer = window.setInterval( _zone.patch_enqueue, PATCH_LIFESPAN );

        self.context = _real_canvas.getContext('2d');

        // plug some event handlers
        _real_canvas.addEventListener( 'mousedown', canvas_event, false );
        _real_canvas.addEventListener( 'touchstart', canvas_event, false );

        _real_canvas.addEventListener( 'mouseup', canvas_event, false );
        _real_canvas.addEventListener( 'touchstop', canvas_event, false );

        _real_canvas.addEventListener( 'mousemove', canvas_event, false );
        _real_canvas.addEventListener( 'touchmove', canvas_event, false );

        $(window).resize(function() {
            self.update_size();
            self.update_paint();
        });

        self.update_size();
        self.update_paint();
    }




    /**
     * Convert local grid to canvas position
     */
    function local_to_canvas_position( local_position ) {
        return {
            x: Math.floor( local_position.x * _column_size ),
            y: Math.floor( local_position.y * _line_size )
        };
    }


    /**
     * Convert canvas to local position
     */
    function canvas_to_local_position( canvas_position ){
        return {
            x: Math.floor( canvas_position.x / _column_size ),
            y: Math.floor( canvas_position.y / _line_size )
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
            self.grid_canvas.width = _real_canvas.width;
            self.grid_canvas.height = _real_canvas.height;
            canvas = self.grid_canvas;
            grid_ctx = canvas.getContext("2d");

            //console.log("editor/draw_grid: before lines");

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
            grid_ctx.lineWidth = EDITOR_GRID_WIDTH;
            grid_ctx.strokeStyle = EDITOR_GRID_COLOR;
            grid_ctx.stroke();

            grid_ctx.beginPath();
            var local_tl = {
                x : self.border_column_count,
                y : self.border_line_count
            };
            var canvas_tl =  local_to_canvas_position( local_tl );
            canvas_tl.w = Math.floor( self.column_count * _column_size );
            canvas_tl.h = Math.floor( self.line_count * _line_size );

            grid_ctx.lineWidth = EDITOR_BOUNDARIES_WIDTH;
            grid_ctx.strokeStyle = EDITOR_BOUNDARIES_COLOR;
            grid_ctx.strokeRect( canvas_tl.x, canvas_tl.y, canvas_tl.w, canvas_tl.h );
        }
        ctx.drawImage( self.grid_canvas, 0, 0);
    }


    /**
     * Repaint zone drawing
     */
    this.update_paint = function() {

        for (var x = 0 ; x < self.column_count ; x++ ){
            for (var y = 0; y < self.line_count ; y++ ) {
                var zone_pos = { 'x': x, 'y': y };
                var color = _zone.pixel_get( zone_pos );
                var local_pos = zone_to_local_position( zone_pos );
                //console.log("editor/update_paint: zone_pos =", JSON.stringify( zone_pos ) );
                self.pixel_draw( local_pos, color );
            }
        }

    }


    /**
     *
     */
    this.update_size = function() {
        var real_canvas = _real_canvas;
        var win = {
            w: $(window).width(),
            h : $(window).height()
        };

        real_canvas.style.position = 'absolute';
        if (win.w > win.h) {
            real_canvas.width = win.h - 2;
            real_canvas.height = win.h - 2;
        } else {
            real_canvas.width = win.w - 2;
            real_canvas.height = win.w - 2;
        }
        real_canvas.style.top = '50px';
        real_canvas.style.left = Math.floor((win.w - real_canvas.width) / 2) + 'px';

        // console.log("editor/update_size: window.width = " + [ $(window).width(), $(window).height() ] );

        // console.log("editor/update_size: real_canvas.width = " + real_canvas.width);
        _column_size = real_canvas.width / (self.column_count + (self.border_column_count * 2));
        _line_size = real_canvas.height / (self.line_count + (self.border_line_count * 2));

        // console.log("editor/update_size: column_size = " + _column_size);

        self.grid_canvas = null;

        var ctx = real_canvas.getContext("2d");
        ctx.fillStyle = '#000';
        ctx.fillRect(0, 0, real_canvas.width, real_canvas.height);

        self.draw_grid();
    };

    /**
     * Handle mouse event
     */
    this.mouseup = function( event_obj ) { self.pencil_up( event_obj ); }
    this.touchstop = function( event_obj ) {
        event_obj.mouseX = event_obj.touches[0].pageX;
        event_obj.mouseY = event_obj.touches[0].pageY;
        self.pencil_up( event_obj );
        event_obj.preventDefault();
    }

    this.pencil_up = function( event_obj ) {
        _pencil_move.enable = false;
    };


    /**
     * Handle mouse event
     */
    this.mousedown = function( event_obj ) { self.pencil_down( event_obj ); }
    this.touchstart = function( event_obj ) {
        event_obj.mouseX = event_obj.touches[0].pageX;
        event_obj.mouseY = event_obj.touches[0].pageY;
        self.pencil_down( event_obj );
        event_obj.preventDefault();
    }

    this.pencil_down = function( event_obj ) {
        _pencil_move.enable = true;
        self.mousemove( event_obj );
    };



    /**
     * Handle mouse event
     */
    this.mousemove = function( event_obj ) { self.pencil_move( event_obj ); }
    this.touchmove = function( event_obj ) {
        event_obj.mouseX = event_obj.touches[0].pageX;
        event_obj.mouseY = event_obj.touches[0].pageY;
        self.pencil_move( event_obj );
        event_obj.preventDefault();
    }

    this.pencil_move = function( event_obj ) {
        var ctx = self.context;
        var canvas = _real_canvas;

        if (_pencil_move.enable) {
            var canvas_pos = { x: event_obj.mouseX, y: event_obj.mouseY };
            var local_pos = canvas_to_local_position( canvas_pos );
            var zone_pos = local_to_zone_position( local_pos );
            // console.log( "editor/mousemove: canvas pos : %s", canvas_pos.to_json() );
            // console.log( "editor/mousemove:local pos : %s", local_pos.to_json() );
            // console.log( "editor/mousemove:zone pos : %s", zone_pos.to_json() );

            // FIXME: detect target zone
            // target_zone = local_to_target_ f( zone_pos )
            var bound = _zone.is_bound( zone_pos );
            // console.log( "editor/mousemove: zone.is_bound = ", bound );

            if ( bound ) {
                self.pixel_set( local_pos, _color );
            } else {
                //FIXME: _color = _zone.pixel_get( zone_pos );
            }

        }
    };


    /**
     * change pixel at given position, on canvas only
     */
    this.pixel_draw = function( local_pos, color ) {
        var ctx = self.context;
        //console.log("editor/pixel_draw local_pos = %s", local_pos.to_json() );
        var canvas_pos = local_to_canvas_position( local_pos );
        var rect = {
            x : canvas_pos.x + (0.1 * _column_size),
            y : canvas_pos.y + (0.1 * _column_size),
            w : _column_size - ( 0.2 * _column_size ),
            h : _line_size - ( 0.2 * _column_size )
        };
        //console.log("editor/pixel_draw rect = %s", rect.to_json() );

        ctx.fillStyle = ZONE_BACKGROUND_COLOR;
        ctx.fillRect( rect.x, rect.y, rect.w, rect.h );

        ctx.fillStyle = color;
        ctx.fillRect( rect.x, rect.y, rect.w, rect.h );
    }


    /*
     * Set pixel at given position to given color
     */
    this.pixel_set = function( local_pos, color ) {
        var zone_pos;

        zone_pos = local_to_zone_position( local_pos );
        //console.log( "editor/pixel_set: zone_pos = %s", zone_pos.to_json() );
        // record to zone
        _zone.pixel_set( zone_pos, color );
        // add to patch structure
        _zone.patch_record( zone_pos, color );
        // draw localy
        self.pixel_draw( local_pos, color );
    };

    /**
     * Pick color of pixel
     */
    this.pixel_get = function( local_pos ) {
        //FIXME: detect bound zone...
        //_return zone.pixel_get( pos );
    }



    /**
      * Change color
      */

    this.color_set = function( hexcolor ) {
        _color = hexcolor;
        // FIXME:
        console.log("editor/color_set: requestion patch enqueue")
        _zone.patch_enqueue();
    }


    /**
      * Handle all types on canvas events and dispatch
      */
    var canvas_event = function( event_obj ) {
        var canvas = _real_canvas;

        // FIXME verify the same formula is used with touchscreens
        event_obj.mouseX = event_obj.pageX - canvas.offsetLeft;
        event_obj.mouseY = event_obj.pageY - canvas.offsetTop;

        var func = self[event_obj.type];
        if (func) { func( event_obj ); }
        // console.log("clicked at %s,%s", event_obj.mouseX, event_obj.mouseY );
    };


    /**
     *
     */
    this.handle_stroke = function( stk ) {
        console.log("editor/handle_stroke : %s", JSON.stringify( stk ));
    }


    /**
     *
     */
    this.handle_message = function( msg ) {
        console.log("editor/handle_message : %s", JSON.stringify( msg ));
    }


    /**
     *
     */
    this.handle_event = function( ev ) {
        console.log("editor/handle_event : %s", JSON.stringify( ev ));
    }


    /**
     * Get patches generated by the drawing
     */
    this.get_strokes = function() {
        var strokes = _zone.patches_get()
        console.log("editor/get_strokes: strokes = %s", JSON.stringify(strokes) );
        return strokes;
    }

    // call constructor
    this.initialize(p_session, p_board, p_canvas_id);
}

