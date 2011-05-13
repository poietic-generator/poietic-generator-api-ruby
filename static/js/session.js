
function Session( callback ) {
	this.brush = null;

	this.SESSION_JOIN = "/api/session/join";
	this.SESSION_LEAVE = "/api/session/leave";


	var session_id = null;
	var user_id = null;

	function initialize() {
		// get session info from 
		$.ajax({
		    // FIXME: request with previous user_id
		    url: "/api/session/join",
		    ataType: "json",
		    type: 'GET',
		    context: this,
		    success: function( user_id ){
			this.user_id = user_id;

			// FIXME: set cookie with user_id
			alert('got user id : ' + this.user_id );
		    }
		});
	}

	initialize();
}
