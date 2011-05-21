

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

	// get session info from 
	$.ajax({
	    // FIXME: request with previous user_id
	    url: SESSION_URL_JOIN + "?type=" + session_type,
	    dataType: "json",
	    type: 'GET',
	    context: self,
	    success: function( response ){
		console.log('session/join response : ' + JSON.stringify(response) );

		this.user_id = response.user_id;
		this.username = response.username;
		this.zone_column_count = response.zone_column_count;
		this.zone_line_count = response.zone_line_count;

		console.log('session/join response mod : ' + JSON.stringify(this) );

		// FIXME: set cookie with user_id for next time
		// FIXME: set username with username for next time

		callback( self );
	    }
	});

    this.to_s = function() { JSON.stringify(self); };
}


