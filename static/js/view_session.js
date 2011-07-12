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
var VIEW_SESSION_URL_UPDATE = "/api/session/play";

var VIEW_SESSION_UPDATE_INTERVAL = 1000 ;
var VIEW_PLAY_UPDATE_INTERVAL = (VIEW_SESSION_UPDATE_INTERVAL / 1000) * 2 ;

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

    var _observers = null;
    var _start_date = 0;
    var _duration = 0;


    /**
     * Semi-Constructor
     */
    this.initialize = function(date) {

        _observers = [];

        // get session info from
        $.ajax({
            url: VIEW_SESSION_URL_JOIN,
            data: {date: date || -1, session: "default"},
            dataType: "json",
            type: 'GET',
            context: self,
            success: function( response ){
                console.log('session/join response : ' + JSON.stringify(response) );

                this.zone_column_count = response.zone_column_count;
                this.zone_line_count = response.zone_line_count;

                _start_date = response.start_date;
                _duration = response.duration;

                // console.log('session/join response mod : ' + JSON.stringify(this) );

                self.other_zones = response.zones;

                callback( self );

                //console.log('session/join post-callback ! observers = %s', JSON.stringify( _observers ));
                //var all_zones = this.other_zones.concat( [ this.user_zone ] );
                // handle other zone events
                for (var i=0;i<self.other_zones.length;i++) {
                    console.log('session/join on zone %s',JSON.stringify(self.other_zones[i]));
                    self.dispatch_strokes( self.other_zones[i].content );
                }

                //self.dispatch_messages( response.msg_history );

                window.setTimeout( self.update, VIEW_SESSION_UPDATE_INTERVAL );

                console.log('session/join end');

            }
        });
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

        var strokes_updates = [], req;

        // assign real values if objets are present
        if (_observers.length < 1) {
            window.setTimeout( self.update, VIEW_SESSION_UPDATE_INTERVAL );
            return null;
        }

        strokes_updates = []
        for (var i=0; i<_observers.length; i++){
            if (_observers[i].get_strokes) {
                strokes_updates = strokes_updates.concat( strokes_updates, _observers[i].get_strokes() );
            }
        }

        console.log("session/update: strokes_updates = %s", JSON.stringify( strokes_updates ));

        req = {
            session: "default",
            since: _start_date + _duration,
            duration: VIEW_PLAY_UPDATE_INTERVAL
        };

        console.log("session/update: req = %s", JSON.stringify( req ) );
        $.ajax({
            url: VIEW_SESSION_URL_UPDATE,
            dataType: "json",
            data: req,
            type: 'GET',
            context: self,
            success: function( response ){
                console.log('session/update response : ' + JSON.stringify( response ) );
                self.treat_status_nok(response);
                if (response.status[0] != STATUS_SUCCESS) {
                    window.setTimeout( self.update, VIEW_SESSION_UPDATE_INTERVAL * 2 );
                }

                _duration = response.duration;

                self.dispatch_events( response.events );
                self.dispatch_strokes( response.strokes );

                window.setTimeout( self.update, VIEW_SESSION_UPDATE_INTERVAL );
            },
            error: function( response ) {
               window.setTimeout( self.update, VIEW_SESSION_UPDATE_INTERVAL * 2 );
           }
        });

    };


    this.dispatch_events = function( events ){
        for (var i=0; i<events.length; i++) {
            for (var o=0; o<_observers.length;o++){
                if (_observers[o].handle_event) {
                    _observers[o].handle_event( events[i] );
                }
            }
        }
    }

    this.dispatch_strokes = function( strokes ){
        for (var i=0; i<strokes.length; i++) {
            for (var o=0; o<_observers.length;o++){
                if (_observers[o].handle_stroke) {
                    _observers[o].handle_stroke( strokes[i] );
                }
            }
        }
    };

    this.register = function( p_observer ){
        _observers.push( p_observer );
    };


    /**
     * Play from current position
     */
    this.current = function () {
    };

    /**
     * Replay from begining
     */
    this.restart = function () {
        this.initialize(0);
    };

    this.initialize();
}
