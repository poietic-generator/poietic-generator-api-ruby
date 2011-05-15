
const SESSION_URL_JOIN = "/api/session/join";
const SESSION_URL_LEAVE = "/api/session/leave";
const SESSION_TYPE_DRAW = "draw";
const SESSION_TYPE_VIEW = "view";

function Session( session_type, callback ) {

	this.brush = null;
	this.user_id = null;
	this.zone_width = null;
	this.zone_height = null;

	// get session info from 
	$.ajax({
	    // FIXME: request with previous user_id
	    url: SESSION_URL_JOIN + "?type=" + session_type,
	    dataType: "json",
	    type: 'GET',
	    context: this,
	    success: function( response ){
		console.log('session/join response : ' + JSON.stringify(response) );

		this.user_id = response.user_id;
		this.username = response.username;
		this.zone_width = response.zone_width;
		this.zone_height = response.zone_height;

		// FIXME: set cookie with user_id for next time
		// FIXME: set username with username for next time

		callback( this );
	    }
	});
}


