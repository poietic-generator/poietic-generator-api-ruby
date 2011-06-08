
// vim: set ts=4 sw=4 et:
"use strict";

var POSITION_TYPE_DRAWING = 0;
var POSITION_TYPE_ZONE = 0;

function Viewer( p_session, p_board, p_canvas_id ){
    //var console = { log: function() {} };

    var self = this;

    var _session;
    var _board;
    var _real_canvas;
    var _column_size;
    var _line_size;

    var _current_zone;
    var _boundaries;

    this.name = "Viewer";
    this.column_count = null;
    this.line_count = null;

    this.column_size = null;
    this.line_size = null;

    this.context = null;


    /**
     * Constructor
     */
    this.initialize = function( p_session, p_board, p_canvas_id ) {
        _boundaries = {
            xmin: 0,
            xmax: 0,
            ymin: 0,
            ymax: 0
        }

        _current_zone =  p_session.user_zone.index;
        console.log("editor/initialize : _current_zone = %s", _current_zone);
        _board = p_board;

        _session = p_session;
        _session.register( self );

        self.column_count = p_session.zone_column_count;
        self.line_count = p_session.zone_line_count;
        self.border_column_count = p_session.zone_column_count / 4;
        self.border_line_count = p_session.zone_column_count / 4;

        _real_canvas = document.getElementById( p_canvas_id );

        // size of editor's big pixels
        self.column_size = 1;
        self.line_size = 1;

        var zone = _board.get_zone(_current_zone);

        self.context = _real_canvas.getContext('2d');

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
    function zone_relative_position( remote_zone, remote_zone_position ) {
        // console.log("editor/zone_relative_position : remote_zone = %s", JSON.stringify( remote_zone ));
        // console.log("editor/zone_relative_position : remote_zone_position = %s", JSON.stringify( remote_zone_position ));

        var dx = remote_zone.position[0] - _board.get_zone(_current_zone).position[0];
        // y coordinates are inverted, because of the canvas ...
        var dy = _board.get_zone(_current_zone).position[1] - remote_zone.position[1];
        // console.log("editor/zone_relative_position : dx = %s  dy = %s", dx, dy );

        var edx = dx * self.column_count;
        var edy = dy * self.line_count;
        // console.log("editor/zone_relative_position : edx = %s  edy = %s", edx, edy );

        var res = {
            x : edx + remote_zone_position.x,
            y : edy + remote_zone_position.y
        };
        // console.log("editor/zone_relative_position : result = %s", JSON.stringify( res ));
        return res;
    }




    /**
     * Repaint zone drawing
     */
    this.update_paint = function() {

        var remote_zone;
        var zones;
        var rt_zone_pos;
        var local_pos;
        var zone_pos;
        var color;

        zones = _board.get_zone_list();
        console.log("editor/update_paint : %s", JSON.stringify( zones));

        for (var zone_idx=0; zone_idx < zones.length; zone_idx++) {
            remote_zone = _board.get_zone( zones[zone_idx] );
            console.log("editor/update_paint : remote_zone = %s", zone_idx );

            for (var x = 0 ; x < self.column_count ; x++ ){
                for (var y = 0; y < self.line_count ; y++ ) {
                    zone_pos = { 'x': x, 'y': y };
                    color = remote_zone.pixel_get( zone_pos );

                    rt_zone_pos = zone_relative_position( remote_zone, zone_pos );
                    local_pos = zone_to_local_position( rt_zone_pos );
                    self.pixel_draw( local_pos, color );
                }
            }
        }

    }


    /**
     *
     */
    this.update_size = function() {
        var real_canvas = _real_canvas,
        win = {
            w: $(window).width(),
            h : $(window).height()
        },
        margin = 80;

        real_canvas.style.position = 'absolute';
        if (win.w > win.h) {
            real_canvas.width = win.h - margin;
            real_canvas.height = win.h - margin;
        } else {
            real_canvas.width = win.w - margin;
            real_canvas.height = win.w - margin;
        }
        real_canvas.style.top = margin + "px";
        real_canvas.style.left = Math.floor((win.w - real_canvas.width) / 2) + 'px';

        // console.log("editor/update_size: window.width = " + [ $(window).width(), $(window).height() ] );

        // console.log("editor/update_size: real_canvas.width = " + real_canvas.width);
        _column_size = real_canvas.width / (self.column_count + (self.border_column_count * 2));
        _line_size = real_canvas.height / (self.line_count + (self.border_line_count * 2));

        // console.log("editor/update_size: column_size = " + _column_size);

        var ctx = real_canvas.getContext("2d");
        ctx.fillStyle = '#000';
        ctx.fillRect(0, 0, real_canvas.width, real_canvas.height);
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
        _board.get_zone(_current_zone).pixel_set( zone_pos, color );
        // add to patch structure
        _board.get_zone(_current_zone).patch_record( zone_pos, color );
        // draw localy
        self.pixel_draw( local_pos, color );
    };



    /**
     *
     */
    this.handle_stroke = function( stk ) {
        console.log("viewer/handle_stroke : stroke = %s", JSON.stringify( stk ));
        var remote_zone = _board.get_zone( stk.zone );
        // console.log("viewer/handle_stroke : remote_zone = %s", JSON.stringify( remote_zone )); 
        var color = stk.color;
        // console.log("viewer/handle_stroke : color = %s", JSON.stringify( color )); 
        var cgset = null;
        var zone_pos = null;
        var local_pos = null;
        var rt_zone_pos = null;
        for (var i=0;i<stk.changes.length;i++) {
            cgset = stk.changes[i];
            // console.log("viewer/handle_stroke : cgset = %s", JSON.stringify( cgset )); 
            zone_pos = { x: cgset[0], y: cgset[1] }
            // console.log("viewer/handle_stroke : zone_pos = %s", JSON.stringify( zone_pos )); 
            rt_zone_pos = zone_relative_position( remote_zone, zone_pos );
            // console.log("viewer/handle_stroke : rt_zone_pos = %s", JSON.stringify( rt_zone_pos )); 
            local_pos = zone_to_local_position( rt_zone_pos );
            // console.log("viewer/handle_stroke : local_pos = %s", JSON.stringify( local_pos )); 
            self.pixel_draw( local_pos, color );
        }
    }


	/**
	 * Handle user-related (join/leave) events
	 */
	this.handle_event = function( ev ) {
		console.log("viewer/handle_event : %s", JSON.stringify( ev ) );

        var zones = _board.get_zone_list();

        _boundaries = { xmin:0, xmax:0, ymin:0, ymax:0 }
        for (var zone_idx=0; zone_idx < zones.length; zone_idx++) {
            remote_zone = _board.get_zone( zones[zone_idx] );
            console.log("viewer/handle_event : %s", JSON.stringify( remote_zone ));
            var x = remote_zone.position[0];
            var y = remote_zone.position[1];
            if (x < _boundaries.xmin) { _boundaries.xmin = x; }
            if (x > _boundaries.xmax) { _boundaries.xmax = x; }
            if (y < _boundaries.ymin) { _boundaries.ymin = y; }
            if (y > _boundaries.ymay) { _boundaries.ymay = y; }
        }
	}

    // call constructor
    this.initialize(p_session, p_board, p_canvas_id);
}

