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

var VIEW_SESSION_URL_JOIN = "/api/session/snapshot";
var VIEW_SESSION_URL_UPDATE = "/api/session/get";

var VIEW_SESSION_UPDATE_INTERVAL = 1000 ;

var STATUS_INFORMATION = 1
var STATUS_SUCCESS = 2
var STATUS_REDIRECTION = 3
var STATUS_SERVER_ERROR = 4
var STATUS_BAD_REQUEST = 5



function ViewSession( callback ) {
  //  var console = noconsole;

    var self = this;

    this.zone_column_count = null;
    this.zone_line_count = null;
    this.user_session = null;

    var _current_stroke_id = 0;
    var _current_message_id = 0;
    var _current_event_id = 0;

    var _observers = null;


    /**
     * Semi-Constructor
     */
    this.initialize = function() {

        _observers = [];

        // get session info from
        $.ajax({
            url: VIEW_SESSION_URL_JOIN,
            dataType: "json",
            type: 'GET',
            context: self,
            success: function( response ){
                console.log('session/join response : ' + JSON.stringify(response) );

                this.user_session = response.user_session;
                this.zone_column_count = response.zone_column_count;
                this.zone_line_count = response.zone_line_count;

                _current_event_id = response.event_id;
                _current_stroke_id = response.stroke_id;
                _current_message_id = response.message_id;

                $.cookie( 'user_session', this.user_session, {path: "/"} );
                // console.log('session/join response mod : ' + JSON.stringify(this) );

                console.log("gotcha!");

                callback( self );

                //console.log('session/join post-callback ! observers = %s', JSON.stringify( _observers ));
                var all_zones = this.other_zones.concat( [ this.user_zone ] );
                // handle other zone events
                for (var i=0;i<all_zones.length;i++) {
                    console.log('session/join on zone %s',JSON.stringify(all_zones[i]));
                    self.dispatch_strokes( all_zones[i].content );
                }

                self.dispatch_messages( response.msg_history );

                window.setTimeout( self.update, VIEW_SESSION_UPDATE_INTERVAL );

                console.log('session/join end');

            }
        });

        this.register( self );
    };


    /**
     * Retrieve the user name from given id
     */
    this.get_user_name = function ( id ) {
        if ( id === this.user_id ) {
            return this.user_name;
        }
        for (var i=0; i < this.other_users.length; i++) {
            if ( id === this.other_users[i].id ) {
                return this.other_users[i].name;
            }
        }
        return null;
    };


    /**
     * Treat not ok Status (!STATUS_SUCCESS)
     */
    this.treat_status_nok = function ( response ) {

        switch(response.status[0]) {
            case STATUS_INFORMATION:
                break;
            case STATUS_SUCCESS:
                // ???
                break;
            case STATUS_REDIRECTION:
                // We got redirected for some reason, we do execute ourselfs
                console.log("STATUS_REDIRECTION --> Got redirected to '%s'" % response.status[2]);
                document.location.href = response.status[2];
                break;
            case STATUS_SERVER_ERROR:
                // FIXME : We got a server error, we should try to reload the page.
                break;
            case STATUS_BAD_REQUEST:
                // FIXME : OK ???
                break;
        }
        return null;
    };
    /**
     *
     */
    this.update = function(){

        var strokes_updates = [];
        var messages_updates = [];
        var req ;

        // skip if no user id assigned
        if (!self.user_id) {
            window.setTimeout( self.update, VIEW_SESSION_UPDATE_INTERVAL );
            return null;
        }

        // assign real values if objets are present
        if (_observers.length < 1) {
            window.setTimeout( self.update, VIEW_SESSION_UPDATE_INTERVAL );
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
            strokes_after : _current_stroke_id,
            messages_after : _current_message_id,
            events_after : _current_event_id,

            strokes : strokes_updates,
            messages : messages_updates,
        }

        console.log("session/update: req = %s", JSON.stringify( req ) );
        $.ajax({
            url: VIEW_SESSION_URL_UPDATE,
            dataType: "json",
            data: JSON.stringify( req ),
            type: 'POST',
            context: self,
            success: function( response ){
                console.log('session/update response : ' + JSON.stringify( response ) );
				self.treat_status_nok(response);
                if (response.status[0] != STATUS_SUCCESS) {
                    window.setTimeout( self.update, VIEW_SESSION_UPDATE_INTERVAL * 2 );
                }

                self.dispatch_events( response.events );
                self.dispatch_strokes( response.strokes );
                self.dispatch_messages( response.messages );

                window.setTimeout( self.update, VIEW_SESSION_UPDATE_INTERVAL );
            },
            error: function( response ) {
               window.setTimeout( self.update, VIEW_SESSION_UPDATE_INTERVAL * 2 );
           }
        });

    };


    this.dispatch_events = function( events ){
        for (var i=0; i<events.length; i++) {
            if ( (events[i].id) || (_current_event_id < events[i].id) ) {
                _current_event_id = events[i].id;
            }
            for (var o=0; o<_observers.length;o++){
                if (_observers[o].handle_event) {
                    _observers[o].handle_event( events[i] );
                }
            }
        }
    }

    this.dispatch_strokes = function( strokes ){
        for (var i=0; i<strokes.length; i++) {
            if ( (strokes[i].id) || (_current_stroke_id < strokes[i].id) ) {
                _current_stroke_id = strokes[i].id;
            }
            for (var o=0; o<_observers.length;o++){
                if (_observers[o].handle_stroke) {
                    _observers[o].handle_stroke( strokes[i] );
                }
            }
        }
    }

    this.dispatch_messages = function( messages ){
        for (var i=0; i<messages.length; i++) {
            if ( (messages[i].id) || (_current_message_id < messages[i].id) ) {
                _current_message_id = messages[i].id;
            }
            for (var o=0; o<_observers.length;o++){
                if (_observers[o].handle_message) {
                    _observers[o].handle_message( messages[i] );
                }
            }
        }
    }


    this.handle_event = function( ev ) {
        console.log("session/handle_event : %s", JSON.stringify( ev ));
        switch (ev.type) {
            case "join" :
                this.other_users.push(ev.desc.user);
                break;
            case "leave" :
                for (var i = 0; i < this.other_users.length; i++) {
                    if (ev.desc.user.id === this.other_users[i].id) {
                        this.other_users.splice(i, 1);
                    }
                }
                break;
            default : // other events are ignored
                break;
        }
    };

    this.register = function( p_observer ){
        _observers.push( p_observer );
    }

    this.initialize();
}
