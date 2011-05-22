

// vim: set ts=4 sw=4 et:
"use strict";

const SESSION_URL_JOIN = "/api/session/join";
const SESSION_URL_LEAVE = "/api/session/leave";
const SESSION_TYPE_DRAW = "draw";
const SESSION_TYPE_VIEW = "view";


function Session( session_type, callback ) {

    var self = this;

    this.brush = null;
    this.user_id = null;
    this.zone_column_count = null;
    this.zone_line_count = null;

    /**
     * Semi-Constructor
     */
    var initialize = function() {
        var user_id = $.cookie('user_id');
        var username = $.cookie('username');

        var session_url = SESSION_URL_JOIN + "?type=" + session_type;
        if ( user_id != null ) {
            session_url += "&user_id="+user_id;
        }
        if ( username != null ) {
            session_url += "&username="+username;
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
                this.username = response.username;
                this.zone_column_count = response.zone_column_count;
                this.zone_line_count = response.zone_line_count;

                $.cookie( 'user_id', this.user_id );
                $.cookie( 'username', this.username );
                console.log('session/join response mod : ' + JSON.stringify(this) );

                // FIXME: set cookie with user_id for next time
                // FIXME: set username with username for next time

                callback( self );
            }
        });
    }

    this.to_s = function() { JSON.stringify(self); };


    initialize();
}


