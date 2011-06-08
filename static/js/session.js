

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

    this.user_id = null;
    this.zone_column_count = null;
    this.zone_line_count = null;
    this.user_zone = null;

    var _current_stroke_id = 0;
    var _current_message_id = 0;
    var _current_event_id = 0;

    var _observers = null;


    /**
     * Semi-Constructor
     */
    this.initialize = function() {

        _observers = []

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

                this.user_zone = response.user_zone;
                this.other_users = response.other_users;
                this.other_zones = response.other_zones;
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

                window.setTimeout( self.update, SESSION_UPDATE_INTERVAL );
                console.log("gotcha!");

                callback( self );

                // handle other zone events
                for (var i=0;i<this.other_zones.length;i++){
                    // FIXME: get initial zone content
                }
                
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
        if (_observers.length < 1) {
            window.setTimeout( self.update, SESSION_UPDATE_INTERVAL );
            return null;
        }

        strokes_updates = []
        messages_updates = []
        for (var i=0; i<_observers.length; i++){
            if (_observers[i].get_messages) {
                messages_updates = messages_updates.concat( messages_updates, _observers[i].get_messages() );
            }
            if (_observers[i].get_strokes) {
                strokes_updates = strokes_updates.concat( strokes_updates, _observers[i].get_strokes() );
            }
        }

        console.log("session/update: strokes_updates = %s", JSON.stringify( strokes_updates ));
        console.log("session/update: messages_updates = %s", JSON.stringify( messages_updates ));

        req = {
            strokes_since : _current_stroke_id,
            messages_since : _current_message_id,
            events_since : _current_event_id,

            strokes : strokes_updates,
            messages : messages_updates,
        }

        console.log("session/update: req = %s", JSON.stringify( req ) );
        $.ajax({
            url: SESSION_URL_UPDATE,
            dataType: "json",
            data: JSON.stringify( req ),
            type: 'POST',
            context: self,
            success: function( response ){
                console.log('session/update response : ' + JSON.stringify( response ) );
                if (response.status[0] != 2) {
                    window.setTimeout( self.update, SESSION_UPDATE_INTERVAL * 2 );
                    return null;
                }

                for (var o=0; o<_observers.length;o++){
                    for (var i=0; i<response.events.length; i++){
                        _current_event_id = response.events[i].id;
                        if (_observers[o].handle_event) {
                            _observers[o].handle_event( response.events[i] );
                        }
                    }

                    for (var i=0; i<response.strokes.length; i++){
                        _current_stroke_id = response.strokes[i].id;
                        if (_observers[o].handle_stroke) {
                            _observers[o].handle_stroke( response.strokes[i] );
                        }
                    }

                    for (var i=0; i<response.messages.length; i++){
                        _current_message_id = response.messages[i].id;
                        if (_observers[o].handle_message) {
                            _observers[o].handle_message( response.messages[i] );
                        }
                    }
                }

                window.setTimeout( self.update, SESSION_UPDATE_INTERVAL );
            },
            error: function( response ) {
               window.setTimeout( self.update, SESSION_UPDATE_INTERVAL * 2 );
           }
        });

    };

    this.register = function( p_observer ){
        _observers.push( p_observer );
    }

    this.initialize();
}
