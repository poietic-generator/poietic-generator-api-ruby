
// vim: set ts=4 sw=4 et:
"use strict";

function ColorPicker( p_session, p_canvas_id ) {
	var self = this;

	this.update_size = function() {
        // canvas 
        var win = { 
            w: $(window).width(),
            h : $(window).height()
        };

        if (win.w > win.h) {
            real_canvas.width = win.h - 20;
            real_canvas.height = win.h - 20;
        } else {
            real_canvas.width = win.w - 20;
            real_canvas.height = win.w - 20;
        }

	}


    /** 
     * Handle mouse event
     */
    this.mouseup = function( event_obj ) {
        // FIXME: do something useful
    };


    /** 
     * Handle mouse event
     */
    this.mousedown = function( event_obj ) {
        // FIXME: do something useful
    };


    /** 
     * Handle mouse event
     */
    this.mousemove = function( event_obj ) {
        // FIXME: do something useful
    };

    var canvas_event = function( event_obj ) {
        event_obj.mouseX = event_obj.pageX - _canvas.offsetLeft;
        event_obj.mouseY = event_obj.pageY - _canvas.offsetTop;

        var func = self[event_obj.type];
        if (func) { func( event_obj ); }
        // console.log("clicked at %s,%s", mouseX, mouseY );
    };


    this.to_s = function() { JSON.stringify(this); };

	this.session = p_session;

    var _canvas_id = picker_id
    var _canvas = document.getElementById( p_canvas_id );

    // add handlers for mouse events
    _canvas.addEventListener( 'mousedown', canvas_event, false );
    _canvas.addEventListener( 'mouseup', canvas_event, false );
    _canvas.addEventListener( 'mousemove', canvas_event, false );

    // add handler for resize event
    $(window).resize(function() {
        self.update_size();
        self.update_paint();
    });

}

