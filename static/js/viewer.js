
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

    this.context = null;


    /**
     * Constructor
     */
    this.initialize = function( p_session, p_board, p_canvas_id ) {
        _boundaries = {
            xmin: 0,
            xmax: 0,
            ymin: 0,
            ymax: 0,
            width: 0,
            height: 0
        }

        _current_zone =  p_session.user_zone.index;
        _board = p_board;
        _session = p_session;
        _session.register( self );

        console.log("viewer/initialize : _current_zone = %s", _current_zone);

        self.update_boundaries();


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
    function local_to_zone_position( zone, local_position ){
        return {
            x: local_position.x - ((zone.position[0] - _boundaries.xmin)* zone.width ),
            y: local_position.y - ((_boundaries.ymax - zone.position[1] )* zone.height )
        };
    }


    /**
     * Convert zone to local grid position
     */
    function zone_to_local_position( zone, zone_position ) {
        // console.log("viewer/zone_to_local_position: zone = %s", JSON.stringify( zone ));
        return {
            x: zone_position.x + ((zone.position[0] - _boundaries.xmin)* zone.width ), 
            y: zone_position.y + ((_boundaries.ymax - zone.position[1] )* zone.height )
        };
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
        console.log("viewer/update_paint : %s", JSON.stringify( zones));

        for (var zone_idx=0; zone_idx < zones.length; zone_idx++) {
            remote_zone = _board.get_zone( zones[zone_idx] );
            console.log("viewer/update_paint : remote_zone = %s", zone_idx );

            for (var x = 0 ; x < remote_zone.width; x++ ){
                for (var y = 0; y < remote_zone.height ; y++ ) {
                    zone_pos = { 'x': x, 'y': y };
                    color = remote_zone.pixel_get( zone_pos );

                    local_pos = zone_to_local_position( remote_zone, zone_pos );
                    self.pixel_draw( local_pos, color );
                }
            }
        }

    }


    /**
     *
     */
    this.update_size = function() {
        var win, margin;

        win = {
            w: $(window).width(),
            h : $(window).height()
        };
        margin = 80;

        _real_canvas.style.position = 'absolute';
        if (win.w > win.h) {
            _real_canvas.width = win.h - margin;
            _real_canvas.height = win.h - margin;
        } else {
            _real_canvas.width = win.w - margin;
            _real_canvas.height = win.w - margin;
        }
        _real_canvas.style.top = margin + "px";
        _real_canvas.style.left = Math.floor((win.w - _real_canvas.width) / 2) + 'px';

        // console.log("viewer/update_size: window.width = " + [ $(window).width(), $(window).height() ] );

        // console.log("viewer/update_size: real_canvas.width = " + real_canvas.width);
        _column_size = _real_canvas.width / self.column_count;
        _line_size = _real_canvas.height / self.line_count;

        // console.log("viewer/update_size: column_size = " + _column_size);
        var ctx = _real_canvas.getContext("2d");
        ctx.fillStyle = '#200';
        ctx.fillRect(0, 0, _real_canvas.width, _real_canvas.height);
    };


    /**
     * change pixel at given position, on canvas only
     */
    this.pixel_draw = function( local_pos, color ) {
        var ctx = self.context;
        //console.log("viewer/pixel_draw local_pos = %s", local_pos.to_json() );
        var canvas_pos = local_to_canvas_position( local_pos );
        var rect = {
            x : canvas_pos.x + (0.05 * _column_size),
            y : canvas_pos.y + (0.05 * _column_size),
            w : _column_size - ( 0.1 * _column_size ),
            h : _line_size - ( 0.1 * _column_size )
        };

        //console.log("viewer/pixel_draw rect = %s", rect.to_json() );
        ctx.fillStyle = ZONE_BACKGROUND_COLOR;
        ctx.fillRect( rect.x, rect.y, rect.w, rect.h );

        ctx.fillStyle = color;
        ctx.fillRect( rect.x, rect.y, rect.w, rect.h );
    }



    /**
     *
     */
    this.handle_stroke = function( stk ) {
        var console = window.noconsole;
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
            console.log("viewer/handle_stroke : cgset = %s", JSON.stringify( cgset )); 
            zone_pos = { x: cgset[0], y: cgset[1] }
            console.log("viewer/handle_stroke : zone_pos = %s", JSON.stringify( zone_pos )); 
            local_pos = zone_to_local_position( remote_zone, zone_pos );
            console.log("viewer/handle_stroke : local_pos = %s", JSON.stringify( local_pos )); 
            self.pixel_draw( local_pos, color );
        }
    }


	/**
	 * Handle user-related (join/leave) events
	 */
	this.handle_event = function( ev ) {
        var console = window.noconsole;
        var zones; 
        var remote_zone;
        var x,y, w, h ;

		console.log("viewer/handle_event : %s", JSON.stringify( ev ) );

        self.update_boundaries();
        self.update_size();
        self.update_paint();
	}


    /**
     * Update boundaries from board information
     */
    this.update_boundaries = function() {
        var console = window.noconsole;
        var zones, remote_zone, x, y;
        var zone_idx;

        zones = _board.get_zone_list();

        // reset boundaries first
        _boundaries = { xmin:0, xmax:0, ymin:0, ymax:0, width: 0, height:0 }

        for (zone_idx=0; zone_idx < zones.length; zone_idx++) {
            remote_zone = _board.get_zone( zones[zone_idx] );
            x = remote_zone.position[0];
            y = remote_zone.position[1];
            if (x < _boundaries.xmin) { _boundaries.xmin = x; }
            if (x > _boundaries.xmax) { _boundaries.xmax = x; }
            if (y < _boundaries.ymin) { _boundaries.ymin = y; }
            if (y > _boundaries.ymay) { _boundaries.ymay = y; }
        }

        // we make a square now ^^
        _boundaries.width = _boundaries.xmax - _boundaries.xmin;
        _boundaries.height = _boundaries.ymax - _boundaries.ymin;

        if ( _boundaries.width > _boundaries.height ) {
            _boundaries.ymax = _boundaries.ymin + _boundaries.width;
            _boundaries.width = _boundaries.width + 1;
            _boundaries.height = _boundaries.width;
        } else {
            _boundaries.xmax = _boundaries.xmin + _boundaries.height;
            _boundaries.height = _boundaries.height + 1;
            _boundaries.width = _boundaries.height;
        }

        console.log("viewer/update_boundaries : boundaries = %s", JSON.stringify( _boundaries ));
        self.column_count = _boundaries.width * _session.zone_column_count;
        self.line_count = _boundaries.height * _session.zone_line_count;
    }

    // call constructor
    this.initialize(p_session, p_board, p_canvas_id);
}

