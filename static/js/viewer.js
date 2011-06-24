/******************************************************************************/
/*                                                                            */
/*  Poetic Generator Reloaded is a multiplayer and collaborative art          */
/*  experience.                                                               */
/*                                                                            */
/*  Copyright (C) 2011 - Gnuside                                              */
/*                                                                            */
/*  This program is free software: you can redistribute it and/or modify it   */
/*  under the terms of the GNU Affero General Public License as published by  */
/*  the Free Software Foundation, either version 3 of the License, or (at     */
/*  your option) any later version.                                           */
/*                                                                            */
/*  This program is distributed in the hope that it will be useful, but       */
/*  WITHOUT ANY WARRANTY; without even the implied warranty of                */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero  */
/*  General Public License for more details.                                  */
/*                                                                            */
/*  You should have received a copy of the GNU Affero General Public License  */
/*  along with this program.  If not, see <http://www.gnu.org/licenses/>.     */
/*                                                                            */
/******************************************************************************/

// vim: set ts=4 sw=4 et:
"use strict";

var POSITION_TYPE_DRAWING = 0;
var POSITION_TYPE_ZONE = 0;

function Viewer( p_session, p_board, p_canvas_id, p_color_picker ){
    //var console = { log: function() {} };

    var self = this;

    var _session;
    var _board;
    var _real_canvas;
    var _column_size;
    var _line_size;
    var _pencil_move;

    var _current_zone;
    var _boundaries;

    var _color_picker = null;

    this.name = "Viewer";
    this.column_count = null;
    this.line_count = null;
    this.color_picker_enabled = false;

    this.context = null;


    /**
     * Constructor
     */
    this.initialize = function( p_session, p_board, p_canvas_id, p_color_picker ) {
        _color_picker = p_color_picker;

        _boundaries = {
            xmin: 0,
            xmax: 0,
            ymin: 0,
            ymax: 0,
            width: 0,
            height: 0
        };

        _pencil_move = {
            enable : false
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
    function local_to_zone_position( zone, local_position ){
        return {
            x: local_position.x - (( zone.position[0] - _boundaries.xmin ) * zone.width ),
            y: local_position.y - (( _boundaries.ymax - zone.position[1] ) * zone.height )
        };
    }


    /**
     * Convert zone to local grid position
     */
    function zone_to_local_position( zone, zone_position ) {
        // console.log("viewer/zone_to_local_position: zone = %s", JSON.stringify( zone ));
        return {
            x: zone_position.x + (( zone.position[0] - _boundaries.xmin ) * zone.width ),
            y: zone_position.y + (( _boundaries.ymax - zone.position[1] ) * zone.height )
        };
    }

    /**
     * Detect target zone given a local position
     */
    function local_to_target_zone( local_position ) {
        var result_zone;
        var zones;
        var zone_pos;

        zones = _board.get_zone_list();
        for (var zone_idx=0; zone_idx < zones.length; zone_idx++) {
            // console.log("viewer/local_to_target_zone: trying index = %s", zones[zone_idx] );
            result_zone = _board.get_zone( zones[zone_idx] );
            console.log("viewer/local_to_target_zone: result_zone = %s", JSON.stringify( result_zone ) );

            if (!result_zone) { continue; }

            zone_pos = local_to_zone_position( result_zone, local_position );
            console.log("viewer/local_to_target_zone: zone_pos = %s", JSON.stringify( zone_pos ) );
            if ( result_zone.contains_position( zone_pos ) ) {
                return result_zone;
            }
        }
        return null;
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

        //_real_canvas.style.position = 'absolute';
        if (win.w > win.h) {
            _real_canvas.width = win.h - margin;
            _real_canvas.height = win.h - margin;
        } else {
            _real_canvas.width = win.w - margin;
            _real_canvas.height = win.w - margin;
        }
        //_real_canvas.style.top = margin + "px";
        //_real_canvas.style.left = Math.floor((win.w - _real_canvas.width) / 2) + 'px';

        // console.log("viewer/update_size: window.width = " + [ $(window).width(), $(window).height() ] );

        // console.log("viewer/update_size: real_canvas.width = " + real_canvas.width);
        _column_size = _real_canvas.width / self.column_count;
        _line_size = _real_canvas.height / self.line_count;

        // console.log("viewer/update_size: column_size = " + _column_size);
        var ctx = _real_canvas.getContext("2d");
        ctx.fillStyle = '#200';
        ctx.fillRect(0, 0, _real_canvas.width, _real_canvas.height);

        _color_picker.update_size( _real_canvas );
    };


    /**
     * change pixel at given position, on canvas only
     */
    this.pixel_draw = function( local_pos, color ) {
        var ctx = self.context;
        //console.log("viewer/pixel_draw local_pos = %s", local_pos.to_json() );
        var canvas_pos = local_to_canvas_position( local_pos );
        var rect = {
            x : canvas_pos.x,
            y : canvas_pos.y,
            w : _column_size,
            h : _line_size
        };

        //console.log("viewer/pixel_draw rect = %s", rect.to_json() );
        ctx.fillStyle = ZONE_BACKGROUND_COLOR;
        ctx.fillRect( rect.x, rect.y, rect.w, rect.h );

        ctx.fillStyle = color;
        ctx.fillRect( rect.x, rect.y, rect.w, rect.h );
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
     * Handle mouse event
     */
    this.mouseup = function( event_obj ) { self.pencil_up( event_obj ); }
    this.touchstop = function( event_obj ) {
        event_obj.mouseX = event_obj.touches[0].pageX - canvas.offsetLeft;
        event_obj.mouseY = event_obj.touches[0].pageY - canvas.offsetTop;
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
        event_obj.mouseX = event_obj.touches[0].pageX - canvas.offsetLeft;
        event_obj.mouseY = event_obj.touches[0].pageY - canvas.offsetTop;
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
        event_obj.mouseX = event_obj.touches[0].pageX - canvas.offsetLeft;
        event_obj.mouseY = event_obj.touches[0].pageY - canvas.offsetTop;
        self.pencil_move( event_obj );
        event_obj.preventDefault();
    }

    this.pencil_move = function( event_obj ) {
        var ctx = self.context;
        var canvas = _real_canvas;

        if (_pencil_move.enable) {
            var canvas_pos = { x: event_obj.mouseX, y: event_obj.mouseY };
            var local_pos = canvas_to_local_position( canvas_pos );
            var target_zone = local_to_target_zone( local_pos );
            if (!target_zone) { return; }

            console.log("viewer/pencil_move: target_zone = %s", JSON.stringify( target_zone ));
            var zone_pos = local_to_zone_position( target_zone, local_pos );

            if ( true === this.color_picker_enabled ) {
                var color = _board.get_zone(target_zone).pixel_get( zone_pos );
                console.log("viewer/pencil_move: color = %s", color);

                _color_picker.set_color( color );
            }
        }
    };


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
            if(remote_zone != null) {
              x = remote_zone.position[0];
              y = remote_zone.position[1];
              if (x < _boundaries.xmin) { _boundaries.xmin = x; }
              if (x > _boundaries.xmax) { _boundaries.xmax = x; }
              if (y < _boundaries.ymin) { _boundaries.ymin = y; }
              if (y > _boundaries.ymay) { _boundaries.ymay = y; }
            }
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
    };


    this.toggle_color_picker = function () {
        this.color_picker_enabled = ( true === this.color_picker_enabled ) ? false : true;
    };

    // call constructor
    this.initialize(p_session, p_board, p_canvas_id, p_color_picker);
}

