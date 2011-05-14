
const SESSION_URL_JOIN = "/api/session/join";
const SESSION_URL_LEAVE = "/api/session/leave";
const SESSION_TYPE_DRAW = "draw";
const SESSION_TYPE_VIEW = "view";

function Session( session_type, callback ) {
	this.brush = null;

	var session_id = null;
	this.user_id = null;

	// get session info from 
	$.ajax({
	    // FIXME: request with previous user_id
	    url: SESSION_URL_JOIN + "?type=" + session_type,
	    ataType: "json",
	    type: 'GET',
	    context: this,
	    success: function( user_id ){
		this.user_id = user_id;

		// FIXME: set cookie with user_id for next time
		console.log('got user id : ' + this.user_id );

		callback( this );
	    }
	});
}


