
function Session( session_type, callback ) {
	this.brush = null;


	this.TYPE


	var session_id = null;
	this.user_id = null;

	function initialize() {
		// get session info from 
		$.ajax({
		    // FIXME: request with previous user_id
		    url: "/api/session/join?type="+session_type,
		    ataType: "json",
		    type: 'GET',
		    context: this,
		    success: function( user_id ){
			this.user_id = user_id;
			
			// FIXME: set cookie with user_id for next time
			alert('got user id : ' + this.user_id );

			callback( this );
		    }
		});
	}

	initialize();
}

Session.prototype.SESSION_JOIN = "/api/session/join";
Session.prototype.SESSION_LEAVE = "/api/session/leave";
Session.prototype.TYPE_DRAW = "draw";
Session.prototype.TYPE_VIEW = "view";

