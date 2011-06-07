

// vim: set ts=4 sw=4 et:
"use strict";

var SESSION_URL_JOIN = "/api/session/join";
var SESSION_URL_LEAVE = "/api/session/leave";
var SESSION_URL_UPDATE = "/api/session/update";

var SESSION_UPDATE_INTERVAL = 10 * 1000 ;

var SESSION_TYPE_DRAW = "draw";
var SESSION_TYPE_VIEW = "view";


function Session( session_type, callback ) {

    var self = this;

    this.brush = null;
    this.user_id = null;
    this.zone_column_count = null;
    this.zone_line_count = null;

    var _current_stroke_id = 0;
    var _current_message_id = 0;
    var _current_event_id = 0;

    var _drawing = null;
    var _view = null;
    var _chat = null;


    /**
     * Semi-Constructor
     */
    this.initialize = function() {

        var user_id = $.cookie('user_id');
        var user_name = $.cookie('user_name');
        var user_session = $.cookie('user_session');

        var session_url = SESSION_URL_JOIN + "?type=" + session_type;
        if ( user_id != null ) {
            session_url += "&user_id="+user_id;
        }
        if ( user_session != null ) {
            session_url += "&user_session="+user_session;
        }
        if ( user_name != null ) {
            session_url += "&user_name="+user_name;
        }

        // get session info from 

        $.ajax({
            url: session_url,
            dataType: "json",
            type: 'GET',
            context: self,
            success: function( response ){
                console.log('session/join response : ' + JSON.stringify(response) );

                this.user_id = response.user_id;
                this.user_name = response.user_name;
                this.user_session = response.user_session;
                this.zone_column_count = response.zone_column_count;
                this.zone_line_count = response.zone_line_count;

                _current_event_id = response.event_id;
                _current_stroke_id = response.stroke_id;
                _current_message_id = response.message_id;

                $.cookie( 'user_id', this.user_id );
                $.cookie( 'user_name', this.user_name );
                $.cookie( 'user_session', this.user_session );
                console.log('session/join response mod : ' + JSON.stringify(this) );

                // FIXME: set cookie with user_id for next time
                // FIXME: set user_name with user_name for next time

                window.setTimeout( self.update, SESSION_UPDATE_INTERVAL );
                console.log("gotcha!");

                callback( self );
            }
        });

    }


    /**
     *
     */
    this.update = function(){

        var strokes_updates = [];
        var messages_updates = [];
        var req ;

        // skip if no user id assigned
        if (!self.user_id) {
            window.setTimeout( self.update, SESSION_UPDATE_INTERVAL );
            return null;
        }

        // assign real values if objets are present
        if (_drawing) {
            strokes_updates = _drawing.patches_get();
        }
        if (_chat) {
            messages_updates = _chat.patches_get();
        }
        console.log("strokes_updates = %s", strokes_updates);
        console.log("messages_updates = %s", messages_updates);

        req = {
            strokes_since : _current_stroke_id,
            messages_since : _current_message_id,
            events_since : _current_event_id,

            strokes : strokes_updates,
            messages : messages_updates,
        }

        console.log("drawing/patches_update: req = %s", JSON.stringify( req ) ); 
        $.ajax({
            url: SESSION_URL_UPDATE,
            dataType: "json",
            data: JSON.stringify( req ),
            type: 'POST',
            context: self,
            success: function( response ){
                console.log('drawing/update response : ' + JSON.stringify( response ) );

                for (var i=0; i<response.events.length; i++){
                    // FIXME: do something with event updates
                    _current_event_id = response.event[i].id;
                    console.log('drawing/update set response id to %s', _current_event_id);
                }

                for (var i=0; i<response.strokes.length; i++){
                    // FIXME: do something with drawing updates
                    _current_stroke_id = response.drawing[i].id;
                    console.log('drawing/update set response id to %s', _current_stroke_id);
                }

                for (var i=0; i<response.messages.length; i++){
                    // FIXME: do something with chat updates
                    _current_message_id = response.chat[i].id;
                    console.log('drawing/update set response id to %s', _current_message_id);
                }
                window.setTimeout( self.update, SESSION_UPDATE_INTERVAL );
            },
            error: function( response ) {
               window.setTimeout( self.update, SESSION_UPDATE_INTERVAL * 2 );
           }
        });

    };

    this.register_drawing = function( p_drawing ){
        _drawing = p_drawing;
    }

    this.register_view = function( p_view ) {
        _view = p_view
    }

    this.initialize();
}


