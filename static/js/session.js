

// vim: set ts=4 sw=4 et:
"use strict";

var SESSION_URL_JOIN = "/api/session/join";
var SESSION_URL_LEAVE = "/api/session/leave";
var SESSION_URL_UPDATE = "/api/session/update";

var SESSION_UPDATE_INTERVAL = 5000;

var SESSION_TYPE_DRAW = "draw";
var SESSION_TYPE_VIEW = "view";


function Session( session_type, callback ) {

    var self = this;

    this.brush = null;
    this.user_id = null;
    this.zone_column_count = null;
    this.zone_line_count = null;

    var _update_timer = null;

    var _current_drawing_id = 0;
    var _current_chat_id = 0;
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
                _current_drawing_id = response.drawing_id;
                _current_chat_id = response.drawing_id;

                $.cookie( 'user_id', this.user_id );
                $.cookie( 'user_name', this.user_name );
                $.cookie( 'user_session', this.user_session );
                console.log('session/join response mod : ' + JSON.stringify(this) );

                // FIXME: set cookie with user_id for next time
                // FIXME: set user_name with user_name for next time

                callback( self );
            }
        });
    }


    /**
     *
     */
    this.update = function(){

        var drawing_updates = [];
        var chat_updates = [];
        var req ;

        // assign real values if objets are present
        if (_drawing) {
            drawing_updates = _drawing.patches_get();
        }
        if (_chat) {
            chat_updates = _chat.patches_get();
        }
        console.log("drawing_updates = %s", drawing_updates);
        console.log("chat_updates = %s", chat_updates);

        req = {
            drawing_since : _current_drawing_id,
            chat_since : _current_chat_id,
            event_since : _current_event_id,

            drawing : drawing_updates,
            chat : chat_updates,
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
    _update_timer = window.setInterval( self.update, SESSION_UPDATE_INTERVAL );
}


