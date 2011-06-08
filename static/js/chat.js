
"use strict";

function Chat( p_session ) {
    var _session;

    var self = this;

    this._queue = [];

    /**
     * Constructor
     */
    this.initialize = function (p_session) {
        // register chat to session
        p_session.register(self);

        // initialize list of users for the send message form
        if (0 < p_session.other_users.length) {
            var select = $("#send-message-form-to");
            for (var i=0; i < p_session.other_users.length; i++) {
                select.append('<option value="'
			+ p_session.other_users[i].id + '">'
			+ p_session.other_users[i].name
			+ ' (' + p_session.other_users[i].id + ')</option>');
            }
        }

        // attach submit event
        $("#send-message-form").submit(function(event){
            event.preventDefault();
	    var message = {
                user_dst: parseInt($(this).find("#send-message-form-to").val(), 10),
                stamp: new Date(),
                content: $(this).find("#send-message-form-content").val()
            };
            self.queue_message( message );
        });
    };


    this.queue_message = function (message) {
        this._queue.push(message);
    };


    /**
     *
     */
    this.get_messages = function () {
        var queue   = self._queue;
        self._queue = [];
        return queue;
    };


    /**
     *
     */
    this.handle_event = function( ev ) {
	// do nothing here :-)
	console.log("chat/handle_event : %s", JSON.stringify( ev ));
    }


    /**
     *
     */
    this.handle_message = function( msg ) {
	// FIXME: do something here
	console.log("chat/handle_message : %s", JSON.stringify( msg ));
    }


    // call initialize method
    this.initialize( p_session );
}

